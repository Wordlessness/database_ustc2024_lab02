-- 借阅表插入
DROP PROCEDURE IF EXISTS borrow_insert;
DELIMITER $$
CREATE PROCEDURE borrow_insert(
	IN prid CHAR(8),
    IN pbid CHAR(8),
	IN pborrow_date DATE
)
BEGIN
	DECLARE ddl DATE;
    SET ddl = DATE_ADD(pborrow_date, INTERVAL 30 DAY);
    INSERT INTO borrow (reader_ID, book_ID, borrow_date, return_ddl)
    VALUES (prid,pbid,pborrow_date,ddl);
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS reserve_insert;
DELIMITER $$
CREATE PROCEDURE reserve_insert(
	IN prid CHAR(8),
    IN pbid CHAR(8),
    IN preserve_date DATE
)
BEGIN
	DECLARE ddl DATE;
    SET ddl = DATE_ADD(preserve_DATE, INTERVAL 30 DAY);
    INSERT INTO reserve (reader_ID,book_ID,reserve_date,reserve_ddl)
    VALUES (prid,pbid,preserve_date,ddl);
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS date_update;
DELIMITER $$
CREATE PROCEDURE date_update(
	IN pdelta INT,
    INOUT pstatus INT
)
BEGIN
	DECLARE pdate DATE;
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
    SELECT var_value INTO pdate FROM global_var WHERE var_name = 'cur_date';
    SET pdate = DATE_ADD(pdate, INTERVAL pdelta DAY);
	UPDATE global_var SET var_value = pdate WHERE var_name = 'cur_date';
    SET pstatus = 0;
END$$
DELIMITER ;
