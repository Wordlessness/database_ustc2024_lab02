  INSERT INTO manager(mid,mname,mtel)
  VALUES
  ('M001','张强','1311234567'),
  ('M002','李华','1321234567'),
  ('M003','赵明','1331234567')
;
  
  INSERT INTO reader(rid,rname,rtel,enrollment,graduation)
  VALUES
   ('R001','晓白','1311234567','2020-09-01','2024-06-01'),
   ('R002','孙云','1321234567','2021-09-01','2025-06-01'),
   ('R003','王雨','1331234567','2023-09-01','2026-06-01')
;



SELECT * FROM reader;
SELECT * FROM manager;
SELECT * FROM global_var WHERE var_name = 'cur_date';
SELECT * FROM global_var;
SELECT * FROM borrow;
SELECT * FROM reserve;

SELECT* FROM book;



SELECT title, author ,books_total, books_available FROM book;
SELECT title, author ,books_total FROM book WHERE title = 1;
 SET SQL_SAFE_UPDATES=0;
UPDATE global_var SET var_value = '2024-02-01' WHERE var_name = 'cur_date';
 SET SQL_SAFE_UPDATES=1;
 
  SET SQL_SAFE_UPDATES=0;
UPDATE global_var SET var_value = '2024-04-06' WHERE var_name = 'cur_date';
 SET SQL_SAFE_UPDATES=1;
 
 
 SET @status = 0;
CALL borrow_book('r001', '2','2',@status);

CALL reserve_book('r001', '1','1',@status);

CALL reserve_insert("r001", "b005", "2024-03-26");

CALL delete_reserve("r001", "b005", "2024-03-08", @status);