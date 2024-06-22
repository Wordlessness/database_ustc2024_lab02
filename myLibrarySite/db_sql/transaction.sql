-- 学生可以借书还书和预约:
-- 借书:
DROP PROCEDURE IF EXISTS borrow_book;
DELIMITER $$
CREATE PROCEDURE borrow_book(
	IN prid CHAR(8),
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    INOUT pstatus INT
)
BEGIN
    DECLARE pbooks_available INT;
    DECLARE preserve_queue INT;
    DECLARE pbid CHAR(8);
    DECLARE pborrow_date DATE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1; -- 数据库错误
    
    START TRANSACTION;
    SET pstatus = 0;
    
    -- 获取书籍ID
    SELECT bid INTO pbid FROM book WHERE title = ptitle AND author = pauthor;
    
    -- 获取当前日期
    SELECT var_value INTO pborrow_date FROM global_var WHERE var_name = 'cur_date';
    
    -- 检查读者是否有违约记录
    IF (SELECT defaulting FROM reader WHERE rid = prid) = TRUE THEN
        SET pstatus = 2;
    END IF;
    
    -- 检查借阅数量限制
    IF (SELECT COUNT(*) FROM borrow WHERE reader_ID = prid AND return_date IS NULL) >= 3 THEN
        SET pstatus = 3;
    END IF;
    
    -- 检查书籍可用数量和预约情况
    SELECT books_available INTO pbooks_available FROM book WHERE bid = pbid;
    SELECT COUNT(*) INTO preserve_queue FROM reserve WHERE book_ID = pbid;
    IF pbooks_available <= preserve_queue THEN 
        IF NOT EXISTS (SELECT 1 FROM reserve WHERE reader_ID = prid AND book_ID = pbid LIMIT pbooks_available) THEN
            SET pstatus = 4;
        END IF;
    END IF;
    
    -- 检查当天是否已借阅同一本书
    IF EXISTS (SELECT 1 FROM borrow WHERE reader_ID = prid AND book_ID = pbid AND borrow_date = pborrow_date) THEN
        SET pstatus = 5;
    END IF;
    
    -- 检查是否已借阅且未还
    IF EXISTS (SELECT 1 FROM borrow WHERE reader_ID = prid AND book_ID = pbid AND return_date IS NULL) THEN
        SET pstatus = 6;
    END IF;
	
    IF pbid IS NULL THEN
		 SET pstatus = 7;
	END IF;
    -- 如果预约了该书且其他条件通过，则删除预约记录
    IF EXISTS (SELECT 1 FROM reserve WHERE book_ID = pbid AND reader_ID = prid) AND pstatus = 0 THEN
        DELETE FROM reserve WHERE book_ID = pbid AND reader_ID = prid;
    END IF;

    -- 更新书籍的借阅次数和可用数量
    IF pstatus = 0 THEN
        UPDATE book SET borrow_times = borrow_times + 1, books_available = books_available - 1 WHERE bid = pbid;
        CALL borrow_insert(prid, pbid, pborrow_date);
    END IF;
    
    -- 提交或回滚事务
    IF pstatus = 0 THEN
        COMMIT;
        SET pstatus = 0;
    ELSE 
        ROLLBACK;
    END IF;
END$$
DELIMITER ;


-- 还书
DROP PROCEDURE IF EXISTS return_book;
DELIMITER $$
CREATE PROCEDURE return_book(
	IN prid CHAR(8),
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    INOUT pstatus INT
)
BEGIN
	DECLARE pbid CHAR(8);
    DECLARE preturn_date DATE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1; -- 数据库错误
    START TRANSACTION;
    SET pstatus = 0;
    SELECT bid INTO pbid FROM book WHERE title = ptitle AND author = pauthor;
    SELECT var_value INTO preturn_date FROM global_var WHERE var_name = 'cur_date';
    
	IF NOT EXISTS(SELECT 1 FROM borrow WHERE prid = reader_ID AND pbid = book_ID AND return_date IS NULL) THEN -- 您也没借啊
		SET pstatus = 2;
    END IF;
    
	UPDATE borrow SET return_date = preturn_date WHERE prid = reader_ID AND pbid = book_ID AND return_date IS NULL;
    UPDATE book SET  books_available =  books_available + 1 WHERE pbid = bid;
    
    IF pstatus = 0 THEN
		COMMIT;
        SET pstatus = 0;
	ELSE 
		-- TODO 错误处理
		ROLLBACK;
    END IF;
END$$
DELIMITER ;



-- 预约
DROP PROCEDURE IF EXISTS reserve_book;
DELIMITER $$
CREATE PROCEDURE reserve_book(
    IN prid CHAR(8),
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE preserve_date DATE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        SET pstatus = 1;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    SET pstatus = 0;

    -- 获取书籍ID
    SELECT bid INTO pbid 
    FROM book 
    WHERE title = ptitle 
    AND author = pauthor;

    -- 获取当前日期
    SELECT var_value INTO preserve_date 
    FROM global_var 
    WHERE var_name = 'cur_date';
    
    -- 检查读者是否有违约记录
    IF (SELECT defaulting FROM reader WHERE rid = prid) = TRUE THEN
        SET pstatus = 2;
    END IF;
    
    -- 检查是否今日已预约此书
    IF EXISTS (
        SELECT 1 
        FROM reserve 
        WHERE reader_ID = prid 
        AND book_ID = pbid 
    ) THEN
        SET pstatus = 3;
    END IF;
    
    -- 调用插入预约记录的存储过程
    IF pstatus = 0 THEN
        CALL reserve_insert(prid, pbid, preserve_date);
    END IF;

    -- 提交或回滚事务
    IF pstatus = 0 THEN
        COMMIT;
    ELSE 
        ROLLBACK;
    END IF;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS delete_reserve;
DELIMITER $$
CREATE PROCEDURE delete_reserve(
    IN prid CHAR(8),
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        SET pstatus = 1;
        ROLLBACK;
    END;

    START TRANSACTION;

    -- 获取书籍ID
    SELECT bid INTO pbid 
    FROM book 
    WHERE title = ptitle 
    AND author = pauthor;

    -- 初始化 pstatus
    SET pstatus = 0;

    -- 检查预约记录是否存在
    IF NOT EXISTS (
        SELECT 1 
        FROM reserve 
        WHERE reader_ID = prid 
        AND book_ID = pbid
    ) THEN
        SET pstatus = 2;
    ELSE
        -- 删除预约记录
        DELETE FROM reserve 
        WHERE reader_ID = prid 
        AND book_ID = pbid;
    END IF;

    -- 提交或回滚事务
    IF pstatus = 0 THEN
        COMMIT;
    ELSE 
        ROLLBACK;
    END IF;
END$$
DELIMITER ;