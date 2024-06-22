CREATE SCHEMA `library`; -- character set utf8;
USE `library`;

CREATE TABLE `book` (
  `bid` CHAR(8),
  `title` VARCHAR(100) NOT NULL,
  `author` VARCHAR(50),
  `cover` LONGBLOB,
  `reserve_queue` INT NOT NULL DEFAULT 0,
  `borrow_times` INT NOT NULL DEFAULT 0,
  `books_available` INT NOT NULL,
  `books_total` INT NOT NULL, 
  PRIMARY KEY (`bid`),
  UNIQUE (`title`, `author`)
  );
  
  CREATE TABLE `manager`(
	`mid` CHAR(8),
    `mname` VARCHAR(50) NOT NULL,
    `mtel` VARCHAR(15) NOT NULL,
    `mpassword` VARCHAR(16),
    PRIMARY KEY (`mid`),
	CHECK (CHAR_LENGTH(`mpassword`) >= 8 AND CHAR_LENGTH(`mpassword`) <= 16)
  );
  
  CREATE TABLE `reader`(
	`rid` CHAR(8),
    `rname` VARCHAR(50) NOT NULL,
    `rtel` VARCHAR(15) NOT NULL,
    `rpassword` VARCHAR(16),
    `enrollment` DATE NOT NULL,
    `graduation` DATE NOT NULL,
    `defaulting` BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (`rid`),
	CHECK (CHAR_LENGTH(`rpassword`) >= 8 AND CHAR_LENGTH(`rpassword`) <= 16)
  );
  
  CREATE TABLE `borrow`(
	`reader_ID` CHAR(8),
    `book_ID` CHAR(8),
    `borrow_date` DATE,
    `return_date` DATE,
    `return_ddl` DATE,
    `if_default` BOOLEAN NOT NULL DEFAULT FALSE,
    `if_log_off` BOOLEAN,
    PRIMARY KEY (`reader_ID`,`book_ID`,`borrow_date`),
    FOREIGN KEY(`reader_ID`) REFERENCES `reader`(`rid`),
	FOREIGN KEY(`book_ID`) REFERENCES `book`(`bid`)
  );
  
  CREATE TABLE `reserve`(
	`reader_ID` CHAR(8),
    `book_ID` CHAR(8),
    `reserve_date` DATE,
    `take_date` DATE,
    `reserve_ddl` DATE,
    PRIMARY KEY (`reader_ID`,`book_ID`,`reserve_date`),
	FOREIGN KEY(`reader_ID`) REFERENCES `reader`(`rid`),
    FOREIGN KEY(`book_ID`) REFERENCES `book`(`bid`)
  );
  
  
  CREATE TABLE `global_var`(
	`var_name` VARCHAR(255),
    `var_value` VARCHAR(255),
    PRIMARY KEY (`var_name`)
  );
  
  INSERT INTO `global_var`(`var_name`,`var_value`)
  VALUES
  ('cur_date',CURDATE())
  ;
  
  
  
  
  DROP TABLE book; DROP TABLE manager; DROP TABLE reader; DROP TABLE borrow; DROP TABLE reserve; DROP TABLE global_var;
  
  SET FOREIGN_KEY_CHECKS=0;
  SET SQL_SAFE_UPDATES=0;
  DELETE FROM book; DELETE FROM manager;  DELETE FROM reader;  DELETE FROM borrow; DELETE FROM reserve; 
  SET SQL_SAFE_UPDATES=1;
  SET FOREIGN_KEY_CHECKS=1;
  
  DROP SCHEMA library;