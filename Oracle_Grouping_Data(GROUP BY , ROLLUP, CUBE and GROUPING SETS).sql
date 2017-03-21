--------------------------------------------------------------------------------
--- Examples of Grouping functions - GROUP BY, ROLLUP and CUBE
--------------------------------------------------------------------------------

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



