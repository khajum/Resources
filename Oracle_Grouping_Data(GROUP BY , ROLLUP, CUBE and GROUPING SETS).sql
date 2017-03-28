--------------------------------------------------------------------------------
--- Examples of Grouping functions - GROUP BY, ROLLUP and CUBE
--------------------------------------------------------------------------------
/*

Grouping Data:

-- Aggregate Functions
-- Grouping Multiple Columns
-- HAVING Clause
-- ROLLUP Operations
-- Partial ROLLUP
-- CUBE Operations
-- GROUPING Function
-- GROUPING SETS
-- Cross-Tabulation Queries
-- PIVOT Operation
-- UNPIVOT Operation

*/ 

DROP TABLE dimension_tab;

CREATE TABLE dimension_tab(
        fact_1_id       NUMBER NOT NULL,
        fact_2_id       NUMBER NOT NULL,
        fact_3_id       NUMBER NOT NULL,
        fact_4_id       NUMBER NOT NULL,
        sales_value NUMBER(10,2)
);


-- Create some random test data
INSERT INTO dimension_tab
SELECT  Trunc(Dbms_Random.Value(low => 1, high => 3)) AS fact_1_id,
        Trunc(Dbms_Random.Value(low => 1, high => 6)) AS  fact_2_id,
        Trunc(Dbms_Random.Value(low => 1, high => 11)) AS  fact_3_id,
        Trunc(Dbms_Random.Value(low => 1, high => 11)) AS  fact_4_id,
        Round(Dbms_Random.Value(low => 1, high => 100),2) AS sales_value
FROM dual
CONNECT BY LEVEL <= 1000;

COMMIT;

SELECT * FROM dimension_tab ORDER BY fact_1_id, fact_2_id, fact_3_id, fact_4_id;
--------------------------------------------------------------------------------
-- GROUP BY Example
--------------------------------------------------------------------------------
-- Aggregate function applies to all rows
SELECT Sum(sales_value) AS sales_value
FROM dimension_tab;

-- Aggregate function applies to each group
-- Group by column 1 results in 2 rows.

SELECT
        fact_1_id, Count(*) AS num_rows, Sum(sales_value) AS sales_value
FROM dimension_tab
GROUP BY fact_1_id
ORDER BY fact_1_id;


-- Aggregate function applies to each group
-- Group by column 1 and 2 results in 10 rows (2*5).

SELECT
        fact_1_id, fact_2_id, Count(*) AS num_rows, Sum(sales_value) AS sales_value
FROM dimension_tab
GROUP BY fact_1_id,fact_2_id
ORDER BY fact_1_id,fact_2_id;

-- Aggregate function applies to each group
-- Group by column 1, 2 and 3 results in 100 rows (2*5*10).

SELECT
        fact_1_id, fact_2_id, fact_3_id, Count(*) AS num_rows, Sum(sales_value) AS sales_value
FROM dimension_tab
GROUP BY fact_1_id,fact_2_id, fact_3_id
ORDER BY fact_1_id,fact_2_id, fact_3_id;

--------------------------------------------------------------------------------
-- ROLLUP Example
--------------------------------------------------------------------------------

-- ROLLUP gives n+1 levels of subtotals.
-- n = nmber of columns in ROLLUP
/*
  ROLLUP(a, b, c) gives
  (a, b, c)
  (a, b)
  (a)
  ()

*/
SELECT fact_1_id, fact_2_id,Sum(sales_value) AS sales_value
FROM dimension_tab
GROUP BY ROLLUP(fact_1_id, fact_2_id)
ORDER BY fact_1_id, fact_2_id



--------------------------------------------------------------------------------
-- CUBE Example
--------------------------------------------------------------------------------

-- CUBE gives 2^n levels of subtotals.
-- n = nmber of columns in ROLLUP
/*
  CUBE(a, b, c) gives
  (a, b, c)
  (a, b)
  (a, c)
  (a)
  (b, c)
  (b)
  (c)
  ()

*/
SELECT fact_1_id, fact_2_id,Sum(sales_value) AS sales_value
FROM dimension_tab
GROUP BY CUBE(fact_1_id, fact_2_id)
ORDER BY fact_1_id, fact_2_id


--------------------------------------------------------------------------------
-- GROUPING Functions
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- GROUPING Example
--------------------------------------------------------------------------------
-- Grouping function accepts single column as parameter and return "1" if the column
-- contains a null value, or "0" for any other values, including stored null values

SELECT
        fact_1_id, fact_2_id,Sum(sales_value) AS sales_value,
        Grouping(fact_1_id) AS f1g,
        Grouping(fact_2_id) AS f2g
FROM dimension_tab
GROUP BY CUBE(fact_1_id, fact_2_id)
ORDER BY fact_1_id, fact_2_id


-- The GROUPING columns can be used for ordering or filtering results


SELECT
        fact_1_id, fact_2_id,Sum(sales_value) AS sales_value,
        Grouping(fact_1_id) AS f1g,
        Grouping(fact_2_id) AS f2g
FROM dimension_tab
GROUP BY CUBE(fact_1_id, fact_2_id)
--HAVING Grouping(fact_1_id) = 1 OR Grouping(fact_2_id) = 1 -- group by fact_1_id subtotal, group by fact_2_id subtotal and total
-- HAVING Grouping(fact_1_id) = 1 and Grouping(fact_2_id) = 1  -- Total
--HAVING Grouping(fact_1_id) = 0 and Grouping(fact_2_id) = 1 -- group by fact_1_id
-- HAVING Grouping(fact_1_id) = 0 and Grouping(fact_2_id) = 0 -- group by  fact_1_id and fact_2_id subtotals
ORDER BY fact_1_id, fact_2_id

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- GROUPING_ID Example
--------------------------------------------------------------------------------

/*
 GROUPING_ID function provides an alternate and more compact way to identify subtotal rows.
 Pass the dimensions columns as arguments, it returns a number indicating the GROUP BY level
*/

SELECT
        fact_1_id, fact_2_id,Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id) AS grouping_id
FROM dimension_tab
GROUP BY CUBE(fact_1_id, fact_2_id)
ORDER BY grouping_id,fact_1_id, fact_2_id


SELECT
        fact_1_id, fact_2_id,Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id) AS grouping_id
FROM dimension_tab
GROUP BY ROLLUP(fact_1_id, fact_2_id)
ORDER BY grouping_id,fact_1_id, fact_2_id



--------------------------------------------------------------------------------
-- GROUP_ID Example
--------------------------------------------------------------------------------
/*
   GROUP_ID function assigns value "0" to the first set, and all subsequent sets get assigned higher number.
   The following query forces duplicats to show the GROUP_ID in action
*/

SELECT
        fact_1_id, fact_2_id,Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id) AS grouping_id,
        GROUP_ID() AS group_id
FROM dimension_tab
GROUP BY GROUPING SETS(fact_1_id, CUBE(fact_1_id, fact_2_id))
ORDER BY grouping_id,fact_1_id, fact_2_id, GROUP_ID


FACT_1_ID FACT_2_ID SALES_VALUE GROUPING_ID GROUP_ID
        1         1     4914.79           0        0
        1         2     6002.92           0        0
        1         3     4760.46           0        0
        1         4      6232.4           0        0
        1         5     4001.03           0        0
        1               25911.6           1        0   -- duplicate
        1               25911.6           1        1   -- duplicate
        2         1     4414.88           0        0
        2         2     5627.82           0        0
        2         3     4740.09           0        0
        2         4     4749.24           0        0
        2         5      4651.4           0        0
        2              24183.43           1        1   -- duplicate
        2              24183.43           1        0   -- duplicate
                  1     9329.67           2        0
                  2    11630.74           2        0
                  3     9500.55           2        0
                  4    10981.64           2        0
                  5     8652.43           2        0
                       50095.03           3        0

-- If necessary, you could then filter the results using the group

SELECT
        fact_1_id, fact_2_id,Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id) AS grouping_id,
        GROUP_ID() AS group_id
FROM dimension_tab
GROUP BY GROUPING SETS(fact_1_id, CUBE(fact_1_id, fact_2_id))
HAVING  GROUP_ID()=0
ORDER BY fact_1_id, fact_2_id


FACT_1_ID FACT_2_ID SALES_VALUE GROUPING_ID GROUP_ID
        1         1     4914.79           0        0
        1         2     6002.92           0        0
        1         3     4760.46           0        0
        1         4      6232.4           0        0
        1         5     4001.03           0        0
        1               25911.6           1        0
        2         1     4414.88           0        0
        2         2     5627.82           0        0
        2         3     4740.09           0        0
        2         4     4749.24           0        0
        2         5      4651.4           0        0
        2              24183.43           1        0
                  1     9329.67           2        0
                  2    11630.74           2        0
                  3     9500.55           2        0
                  4    10981.64           2        0
                  5     8652.43           2        0
                       50095.03           3        0

--------------------------------------------------------------------------------
-- GROUPING SETS Example
--------------------------------------------------------------------------------


SELECT
        fact_1_id, fact_2_id,fact_3_id,Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id,fact_3_id) AS grouping_id
FROM dimension_tab
GROUP BY CUBE(fact_1_id, fact_2_id, fact_3_id)
ORDER BY fact_1_id, fact_2_id,fact_3_id


--  If we only need a few of these levels of subtotaling we can use the GROUPING SETS expression
-- and specify exactly which ones we need


SELECT
        fact_1_id, fact_2_id,fact_3_id,Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id,fact_3_id) AS grouping_id
FROM dimension_tab
GROUP BY GROUPING SETS((fact_1_id, fact_2_id), (fact_1_id,fact_3_id))
ORDER BY fact_1_id, fact_2_id,fact_3_id


--------------------------------------------------------------------------------
-- Composite Columns Example
--------------------------------------------------------------------------------
/*
  ROLLUP(a, b, c) gives
  (a,b,c)
  (a,b)
  (a)
  ()

  But ROLLUP((a, b), c) gives
  (a, b, c)
  (a, b)
  ()

 CUBE((a, b), c)  gives

 (a, b, c)
 (a, b)
 (c)
 ()

*/

-- Regular Cube
SELECT
        fact_1_id,
        fact_2_id,
        fact_3_id,
        Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id,fact_3_id) AS grouping_id
FROM dimension_tab
GROUP BY CUBE(fact_1_id, fact_2_id, fact_3_id)
ORDER BY GROUPING_ID,fact_1_id, fact_2_id,fact_3_id


-- Cube with composite column
SELECT
        fact_1_id,
        fact_2_id,
        fact_3_id,
        Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id,fact_3_id) AS grouping_id
FROM dimension_tab
GROUP BY CUBE((fact_1_id, fact_2_id), fact_3_id)
ORDER BY GROUPING_ID,fact_1_id, fact_2_id,fact_3_id

--------------------------------------------------------------------------------
--Concatenated Grouping
--------------------------------------------------------------------------------

-- Grouping set of column fact_1_id AND fact_2_id
SELECT
        fact_1_id,
        fact_2_id,
        Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_1_id,fact_2_id) AS grouping_id
FROM dimension_tab
GROUP BY GROUPING SETS(fact_1_id, fact_2_id)
ORDER BY GROUPING_ID,fact_1_id, fact_2_id

-- Grouping set of column fact_3_id AND fact_4_id

SELECT
        fact_3_id,
        fact_4_id,
        Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_3_id,fact_4_id) AS grouping_id
FROM dimension_tab
GROUP BY GROUPING SETS(fact_3_id, fact_4_id)
ORDER BY GROUPING_ID,fact_3_id, fact_4_id

/*

-- If we combine them into concatenated grouping we get 4 groups of subtotals as:

GROUPING SETS(a, b), GROUPING SETS(c, d) gives:
(a, c)
(a, d)
(b, c)
(b, d)

*/
SELECT
        fact_1_id,
        fact_2_id,
        fact_3_id,
        fact_4_id,
        Sum(sales_value) AS sales_value,
        GROUPING_ID(fact_3_id,fact_4_id) AS grouping_id
FROM dimension_tab
GROUP BY GROUPING SETS(fact_1_id,fact_2_id), GROUPING SETS(fact_3_id, fact_4_id)
ORDER BY GROUPING_ID,fact_1_id,fact_2_id,fact_3_id, fact_4_id;





--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- PIVOT and UNPIVOT quiries in 11g
--------------------------------------------------------------------------------

 -- Create Example data
CREATE TABLE employees(job VARCHAR2(50), dept_no NUMBER, sal NUMBER(10,2));


INSERT INTO employees VALUES('ANALYST',20,6600);
INSERT INTO employees VALUES('CLERK',10,1430);
INSERT INTO employees VALUES('CLERK',20,2090);
INSERT INTO employees VALUES('CLERK',30,1045);
INSERT INTO employees VALUES('MANAGER',10,2695);
INSERT INTO employees VALUES('MANAGER',20,3272.5);
INSERT INTO employees VALUES('MANAGER',30,3135);
INSERT INTO employees VALUES('PRESEDINT',10,5500);
INSERT INTO employees VALUES('SALESMAN',30,6160);

COMMIT;

--------------------------------------------------------------------------------

SELECT job, dept_no, Sum(sal) sum_sal
FROM employees
GROUP BY job, dept_no
ORDER BY job, dept_no;



WITH pivot_data AS
(
    SELECT dept_no,job, sal
    FROM employees

)
SELECT * FROM pivot_data
PIVOT
(
	Sum(sal)  		--<-- pivot_clause
	FOR dept_no		--<-- pivot_for_clause
	IN (10,20,30)	--<-- pivot_in_clause

);



WITH pivot_data AS
(
    SELECT dept_no,job, sal
    FROM employees

)
SELECT * FROM pivot_data
PIVOT
(
	Sum(sal)  		--<-- pivot_clause
	FOR dept_no		--<-- pivot_for_clause
	IN (10,20,30,40)	--<-- pivot_in_clause

)
WHERE  JOB IN ('ANALYST','CLERK','SALESMAN');

-- Using inline-view
SELECT *
FROM
(
	SELECT dept_no, job, sal FROM employees
)
pivot ( Sum(sal) FOR dept_no IN ('10','20','30'));


--------------------------------------------------------------------------------
-- Aliasing pivot column

SELECT  *
FROM employees
pivot
(

-- alias both pivot_clause and pivot_in_clause
	--Sum(sal) AS salaries
	Sum(sal)
--	FOR dept_no IN (
--						10 AS d10_sal,
--						20 AS d20_sal,
--						30 AS d30_sal,
--						40 AS d40_sal
--					)

-- alias pivot_in_claus
--	FOR dept_no IN (10 AS d10_sal, 20 d20_sal, 30 d30_sal, 40 AS d40_sal)

-- selective alias
FOR dept_no IN (10 AS d10_sal, 20, 30 d30_sal, 40)

);


--------------------------------------------------------------------------------
-- pivoting multiple columns

SELECT *
FROM employees
PIVOT
(
	Sum(sal) AS Sum,
 	Count(sal) AS cnt
	--FOR dept_no IN (10 AS d10_sal, 20 AS d20_sal, 30 AS d30_sal, 40 AS d40_sal)

-- extend pivot_for_clause and pivot_in_clause to include JOB valuees in the filter
	FOR (dept_no, job) IN  (
								(30, 'SALESMAN') AS d30_sls,
								(30, 'MANAGER') AS d30_mgr,
								(30, 'CLERK') AS d30_clk
							)

);


-- general restrictions

-- 1. cannot project the column(s) used  in the pivot_for_clause
SELECT dept_no
FROM employees
pivot ( Sum(sal)
FOR dept_no IN (10,20,30));

-- ORA-00904: "DEPT_NO": invalid identifier

-- 2. Cannot include any column(s) used in pivot_clause
SELECT sal
FROM employees
pivot ( Sum(sal)
FOR dept_no IN (10,20,30));

-- ORA-00904: "SAL": invalid identifier

--3. Raises exception, if we attempt to project the SAL column
SELECT *
FROM employees
pivot (sal
FOR dept_no IN (10,20,30));


--------------------------------------------------------------------------------
-- Explain Plan

EXPLAIN PLAN FOR
SELECT *
FROM employees
pivot (Sum(sal)
FOR dept_no IN (10,20,30));


SELECT * FROM TABLE(dbms_xplan.display);



PLAN_TABLE_OUTPUT
Plan hash value: 2432923890

---------------------------------------------------------------------------------
| Id  | Operation           | Name      | Rows  | Bytes | Cost (%CPU)| Time     |
---------------------------------------------------------------------------------
|   0 | SELECT STATEMENT    |           |     9 |   477 |     3  (34)| 00:00:01 |
|   1 |  HASH GROUP BY PIVOT|           |     9 |   477 |     3  (34)| 00:00:01 |
|   2 |   TABLE ACCESS FULL | EMPLOYEES |     9 |   477 |     2   (0)| 00:00:01 |
---------------------------------------------------------------------------------

Note
-----
   - dynamic sampling used for this statement (level=2)

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Pivoting an unknown domain of values

SELECT *
FROM employees
pivot XML (Sum(sal) FOR dept_no IN (ANY));


--------------------------------------------------------------------------------
-- UNPIVOT
--------------------------------------------------------------------------------

-- SYNTAX:
SELECT ....
FROM ...
UNPIVOT [INCLUDE|EXCLUDE NULLS]
(
	unpivot_clause
	unpivot_for_clause
	unpivot_in_clause
)
WHERE ....;


--- Unpivot Examples

CREATE OR REPLACE VIEW pivot_data_vw
AS
SELECT *
FROM employees
pivot(Sum(sal)
FOR dept_no IN (10 AS d10_sal, 20 AS d20_sal, 30 AS d30_sal, 40 AS d40_sal));


SELECT * FROM  pivot_data_vw;


--- Unpivot dataset
SELECT *
FROM pivot_data_vw
UNPIVOT
(
	dept_sal
	FOR sal_desc
	IN (d10_sal, d20_sal, d30_sal, d40_sal)
);


-- Handling NULL data
SELECT *
FROM pivot_data_vw
UNPIVOT	INCLUDE NULLS
(
  dept_sal
  FOR sal_desc
  IN (d10_sal, d20_sal, d30_sal, d40_sal)
);


-- Unpivot aliasing option

SELECT job, sal_desc, dept_sal
FROM pivot_data_vw
unpivot (dept_sal
FOR sal_desc IN (
					d10_sal AS 'SAL TOTAL FOR 10',
					d20_sal AS 'SAL TOTAL FOR 20',
					d30_sal AS 'SAL TOTAL FOR 30',
					d40_sal AS 'SAL TOTAL FOR 40'));





-- General restriction

-- 1. Coluns in the pivot_in_clause must be all of the same datatype
-- 2. Datatype conversions within the unpivot_in_clause is also invalid.