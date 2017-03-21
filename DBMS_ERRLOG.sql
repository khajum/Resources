-- Create test table
CREATE TABLE DEMO_DBMS_ERRLOG
AS
SELECT * FROM USER_OBJECTS WHERE ROWNUM<1;

SELECT * FROM DEMO_DBMS_ERRLOG;

ALTER TABLE  DEMO_DBMS_ERRLOG
ADD CONSTRAINT PK_OBJECT_ID_01 PRIMARY KEY(OBJECT_ID);


-- Create an error log table using DBMS_ERRLOG package
BEGIN

DBMS_ERRLOG.create_error_log(
dml_table_name => 'DEMO_DBMS_ERRLOG',
--err_log_table_name => 'TBL_ERROR_LOG', --Default is first 25 Characters of DML table prefixed eith 'ERR_$' eg: dml_table_name: 'DEMO_DBMS_ERRLOG', err_log_table_name: 'ERR_$DEMO_DBMS_ERRLOG'
err_log_table_owner => USER ,
err_log_table_space =>USER
);

END;
/

SELECT Count(*) FROM err$_demo_dbms_errlog


INSERT INTO DEMO_DBMS_ERRLOG
SELECT * FROM USER_OBJECTS
Log errors
reject limit UNLIMITED;

--Insert - 1760 row(s), executed in 1.895 sec.

SELECT Count(*) FROM err$_demo_dbms_errlog


DELETE FROM  DEMO_DBMS_ERRLOG WHERE  object_id BETWEEN  3012502 AND 3163637;
COMMIT;



-- Now, let's insert all the rows using error log.
INSERT INTO DEMO_DBMS_ERRLOG
SELECT * FROM USER_OBJECTS
Log errors
reject limit UNLIMITED;

-- Insert - 1751 row(s), executed in 235 ms
COMMIT;

-- Now, check error generated

SELECT * FROM err$_demo_dbms_errlog;


SELECT Count(*) FROM DEMO_DBMS_ERRLOG;