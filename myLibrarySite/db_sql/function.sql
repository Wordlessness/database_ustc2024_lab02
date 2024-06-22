DROP FUNCTION IF EXISTS find_missing_bid;
DELIMITER $$
CREATE FUNCTION find_missing_bid() RETURNS CHAR(8)
DETERMINISTIC
BEGIN
    DECLARE prefix CHAR(1) DEFAULT 'b';
    DECLARE num_part INT DEFAULT 1;
    DECLARE current_bid CHAR(8);
    
    WHILE num_part <= 999 DO
        SET current_bid = CONCAT(prefix, LPAD(num_part, 3, '0'));
        
        IF NOT EXISTS (SELECT 1 FROM book WHERE bid = current_bid) THEN
			return current_bid;
        END IF;
        SET num_part = num_part + 1;
    END WHILE;
    RETURN NULL;
END$$
DELIMITER ;