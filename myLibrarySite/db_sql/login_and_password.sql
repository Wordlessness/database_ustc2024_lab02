DROP PROCEDURE IF EXISTS user_login; -- 读者登录
DELIMITER $$
CREATE PROCEDURE user_login(
    IN pid CHAR(8),
    IN ppassword VARCHAR(16),
    IN if_reader BOOLEAN,
    INOUT pstatus INT,
    INOUT pname VARCHAR(50)
)
BEGIN
    DECLARE user_password VARCHAR(16);
    DECLARE flag INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;

    IF if_reader THEN
        SELECT COUNT(*) INTO flag FROM reader WHERE rid = pid;
    ELSE
        SELECT COUNT(*) INTO flag FROM manager WHERE mid = pid;
    END IF;

    IF flag = 0 THEN
        SET pstatus = IF(if_reader, 2, 3); -- 2: not student, 3: not manager
    ELSE
        IF if_reader THEN
            SELECT rpassword INTO user_password FROM reader WHERE rid = pid;
        ELSE
            SELECT mpassword INTO user_password FROM manager WHERE mid = pid;
        END IF;

        IF user_password IS NULL THEN
            SET pstatus = 4; -- No password set
        ELSE
            IF user_password <> ppassword THEN
                SET pstatus = 5; -- Incorrect password
            ELSE
				IF if_reader THEN
					SELECT rname INTO pname FROM reader WHERE rid = pid;
				ELSE
					SELECT mname INTO manager WHERE mid = pid;
				END IF;
                SET pstatus = 0; -- Login successful
            END IF;
        END IF;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS get_verify_code;-- 返回验证码
DELIMITER $$
CREATE PROCEDURE get_verify_code(
	IN pid CHAR(8),
    IN ptel VARCHAR(15),
    IN if_reader BOOL,
    OUT return_code CHAR(4),
    INOUT pstatus INT
)
BEGIN
	DECLARE user_tel VARCHAR(15);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
    IF if_reader THEN
		SELECT rtel INTO user_tel FROM reader WHERE rid = pid;
    ELSE
		SELECT mtel INTO user_tel FROM manager WHERE mid = pid;
	END IF;
	IF user_tel IS NULL THEN
		SET pstatus = IF(if_reader, 2, 3); -- -- 2: 诶呀,您好像不是这个学校的学生呢 3: 诶呀,您好像不是这个学校的图书管理员呢
	ELSE
		IF (user_tel <> ptel) THEN
			SET pstatus = 4; -- 诶呀, 您的电话号码似乎不匹配呢
		ELSE
			SELECT LPAD(CAST(FLOOR(RAND() * 10000 + 1) AS CHAR), 4, '0') INTO return_code;
            DELETE FROM global_var WHERE var_name = CONCAT(pid, 'code');
            INSERT INTO global_var (var_name,var_value)
            VALUE (CONCAT(pid, 'code'), return_code);
            SET pstatus = 0;
		END IF;
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS verify_return_code;
DELIMITER $$
CREATE PROCEDURE verify_return_code(
	IN pid CHAR(8),
    IN ptel VARCHAR(15),
    IN verify_code CHAR(8),
    IN if_reader BOOL,
	INOUT pstatus INT
)
BEGIN
	DECLARE user_tel VARCHAR(15);
    DECLARE gen_code CHAR(4);
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
	IF if_reader THEN
		SELECT rtel INTO user_tel FROM reader WHERE rid = pid;
    ELSE
		SELECT mtel INTO user_tel FROM manager WHERE mid = pid;
	END IF;
    IF user_tel IS NULL THEN
		SET pstatus = IF(if_reader, 2, 3); -- -- 2: 诶呀,您好像不是这个学校的学生呢 3: 诶呀,您好像不是这个学校的图书管理员呢
	ELSE
		IF (user_tel <> ptel) THEN
			SET pstatus = 4; -- 诶呀, 您的电话号码似乎不匹配呢
		ELSE
			SELECT var_value INTO gen_code FROM global_var WHERE var_name = CONCAT(pid, 'code');
			IF gen_code <> verify_code THEN
				SET pstatus = 5; -- 诶呀, 您的验证码不对呢
            ELSE
				SET pstatus = 0;
            END IF;
		END IF;
	END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS reset_password;
DELIMITER $$
CREATE PROCEDURE reset_password(
	IN pid CHAR(8),
    IN if_reader BOOL,
    IN password1 VARCHAR(20),
    IN password2 VARCHAR(20),
	INOUT pstatus INT
)
BEGIN
	-- 到了这一步已经验证过了pid, 不必重新验证. 
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET pstatus = 1;
    IF password1 <> password2 THEN 
		SET pstatus = 2; -- 诶呀, 您两次输入的密码似乎不一样呢
    ELSE
		IF CHAR_LENGTH(password1) < 8 OR CHAR_LENGTH(password1) > 16 THEN
			SET pstatus = 3; -- 诶呀, 您的密码长度不在8-16位之间呢
		ELSE
			IF if_reader THEN
					UPDATE reader SET rpassword = password1 WHERE rid = pid;
			ELSE 
					UPDATE manager SET mpassword = password1 WHERE mid = pid;
			END IF;
            -- 弹出消息密码重置成功 
        END IF;
    END IF;
END$$
DELIMITER ;