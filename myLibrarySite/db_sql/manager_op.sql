DROP PROCEDURE IF EXISTS add_book_new;
DELIMITER $$

CREATE PROCEDURE add_book_new(
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    IN pcover LONGBLOB,
    IN num INT,
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;

    -- 检查书是否存在
    SELECT bid INTO pbid FROM book WHERE title = ptitle AND author = pauthor;
    IF pbid IS NOT NULL THEN
        SET pstatus = 2; -- 诶呀, 您要插入的书已经存在了,快去试试"添加书籍(已有)"吧
    ELSE
        SET pbid = find_missing_bid();
        IF pbid IS NULL THEN
            -- 没有空缺的 bid
            SET pstatus = 3; -- 诶呀,图书馆满了呢,暂时不能加新书了
        ELSE
            IF num <= 0 THEN 
                SET pstatus = 4; -- 诶呀,添加书籍的本数必须为正哦
            ELSE
                INSERT INTO book (bid, title, author, cover, books_available, books_total) 
                VALUES (pbid, ptitle, pauthor, pcover, num, num);
                SET pstatus = 0; -- 插入成功
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS add_book_old;
DELIMITER $$
CREATE PROCEDURE add_book_old(
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    IN num INT,
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;

    -- 检查书是否存在
    SELECT bid INTO pbid FROM book WHERE title = ptitle AND author = pauthor;
    IF pbid IS NULL THEN
        SET pstatus = 2; -- 诶呀, 您要插入的书还不存在呢,快去试试"添加书籍(新书)"吧
    ELSE
		IF num <= 0 THEN 
			SET pstatus = 3; -- 诶呀,添加书籍的本数必须为正哦
		ELSE
			UPDATE book SET  books_available = books_available + num, books_total = books_total + num WHERE bid = pbid;
			SET pstatus = 0; -- 添加
		END IF;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS delete_book_some;
DELIMITER $$
CREATE PROCEDURE delete_book_some(
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    IN num INT,
    INOUT pstatus INT
)
BEGIN
	
END
DELIMITER ;

DROP PROCEDURE IF EXISTS delete_book_some;
DELIMITER $$
CREATE PROCEDURE delete_book_some(
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    IN num INT,
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
    -- 检查书是否存在
    SELECT bid INTO pbid FROM book WHERE title = ptitle AND author = pauthor;
    IF pbid IS NULL THEN
        SET pstatus = 2; -- 诶呀, 您要删除的书还不存在呢 
    ELSE
		IF num <= 0 THEN 
			SET pstatus = 3; -- 诶呀,删除书籍的本数必须为正哦
		ELSE
			IF (SELECT books_available FROM book WHERE bid = pbid) < num  THEN
				SET pstatus = 4; -- 诶呀,没有那么多书让你删哦
            ELSE 
				SET pstatus = 0; -- 删除成功!
				UPDATE book SET  books_available = books_available - num, books_total = books_total - num WHERE bid = pbid;
            END IF;
		END IF;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS delete_book_all;
DELIMITER $$
CREATE PROCEDURE delete_book_all(
    IN ptitle VARCHAR(100),
    IN pauthor VARCHAR(50),
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
    -- 检查书是否存在
    SELECT bid INTO pbid FROM book WHERE title = ptitle AND author = pauthor;
    IF pbid IS NULL THEN
        SET pstatus = 2; -- 诶呀, 您要删除的书还不存在呢 
    ELSE
		DELETE FROM borrow WHERE book_ID = pbid;
        DELETE FROM reserve WHERE book_ID = pbid;
        DELETE FROM book WHERE bid = pbid;
        SET pstatus = 0;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS update_book;
DELIMITER $$
CREATE PROCEDURE update_book(
    IN potitle VARCHAR(100),
    IN poauthor VARCHAR(50),
    IN pntitle VARCHAR(100),
    IN pnauthor VARCHAR(50),
    IN pncover LONGBLOB,
    INOUT pstatus INT
)
BEGIN
    DECLARE pbid CHAR(8);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
    SELECT bid INTO pbid FROM book WHERE title = potitle AND author = poauthor;
    IF pbid IS NULL THEN
        SET pstatus = 2; -- 诶呀, 您要修改的书还不存在呢 
    ELSE
		IF pntitle IS NOT NULL THEN
			UPDATE book SET title = pntitle WHERE pbid = bid;
        END IF;
		IF pncover IS NOT NULL THEN
			UPDATE book SET cover = pncover WHERE pbid = bid;
        END IF;
        IF pnauthor IS NOT NULL THEN
			UPDATE book SET author = pnauthor WHERE pbid = bid;
        END IF;
        SET pstatus = 0;
    END IF;
END$$
DELIMITER ;