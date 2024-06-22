DROP TRIGGER IF EXISTS when_date_update;
DELIMITER $$
CREATE TRIGGER when_date_update 
AFTER UPDATE ON global_var
FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE prid CHAR(8);
    DECLARE cursor_rids CURSOR FOR 
        SELECT rid FROM reader WHERE NEW.var_value >= graduation;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    IF NEW.var_name = 'cur_date' AND NEW.var_value != OLD.var_value THEN
        OPEN cursor_rids;

        read_loop: LOOP
           FETCH cursor_rids INTO prid;
            IF done THEN
                LEAVE read_loop;
            END IF;
            DELETE FROM reserve WHERE prid = reader_ID;
            DELETE FROM borrow WHERE prid = reader_ID;
            DELETE FROM reader WHERE rid = prid;
        END LOOP;
        CLOSE cursor_rids;

		DELETE FROM borrow 
        WHERE NEW.var_value > DATE_ADD(borrow_date, INTERVAL 90 DAY) 
        AND return_date IS NOT NULL;

        UPDATE borrow 
        SET if_default = TRUE 
        WHERE NEW.var_value > return_ddl AND return_date IS NULL;

        DELETE FROM reserve 
        WHERE NEW.var_value > reserve_ddl;
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS when_defaulting;
DELIMITER $$
CREATE TRIGGER when_defaulting AFTER UPDATE ON borrow
FOR EACH ROW
BEGIN
	DECLARE cur_date DATE;
    SELECT var_value INTO cur_date FROM global_var WHERE var_name = "cur_date";
	IF NEW.if_default <> OLD.if_default AND NEW.if_default = TRUE THEN
		UPDATE reader SET defaulting = TRUE WHERE rid = NEW.reader_ID;-- 设置违约
    END IF;
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
		IF (SELECT COUNT(*) FROM borrow WHERE reader_ID = NEW.reader_ID AND cur_date > return_ddl AND return_date IS NULL) = 0 THEN
			UPDATE reader SET defaulting = FALSE WHERE rid = NEW.reader_ID;-- 注销违约
        END IF;
    END IF;
END$$
DELIMITER ;
