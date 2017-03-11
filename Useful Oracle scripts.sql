--------------------------------------------
-- Check free space(ASM disk)
--------------------------------------------
SELECT Sum(TOTAL_MB)/1024,Sum(free_mb)/1024 FROM v$asm_disk;

SELECT name,Sum(TOTAL_MB)/1024,Sum(free_mb)/1024
FROM v$asm_disk GROUP BY name;

-- Space consumed by tablespace/user
SELECT tablespace_name,Round(Sum(bytes)/1024/1024/1024) GB FROM dba_data_files
GROUP BY  tablespace_name
ORDER BY 2 DESC;

SELECT * FROM dba_data_files  WHERE TABLESPACE_NAME=USER


SELECT * FROM dba_segments;

select round(sum(bytes)/1024/1024/1024) GB, segment_name
from dba_segments
where SEGMENT_NAME in ('HP_CLAIMS','HP_RXCLAIMS','HP_ELIGIBILITIES','HP_ELIGIBILITIES_PMPR')
group by segment_name order by 1 desc;
--------------------------------------------------------------------------------
SELECT * FROM TABLE(dbms_xplan.display_cursor('&sql_id','&child_number','ALLSTATS LAST'))

SELECT dbms_sqltune.report_sql_monitor(sql_id=>'amjc708n8c96v',TYPE=>'TEXT',report_level=>'ALL') AS report FROM dual;

--------------------------------------------------------------------------------
--- TROUBLESHOOTING STUCK QUERIES
--------------------------------------------------------------------------------

-- SQL Monitor
DECLARE
    report CLOB;
BEGIN
        report := dbms_sqltune.report_sql_monitor(sql_id =>'amjc708n8c96v', TYPE=>'TEXT', report_level=>'ALL');
        Dbms_Output.Put_Line(report);

END;
--------------------------------------------------------------------------------

-- ACTIVE SESSION

SELECT Nvl(event,session_state),Count(*) FROM v$active_session_history
WHERE sql_id='3qs8j1hqfhrzn'
GROUP BY Nvl(event,session_state)
ORDER BY 2 DESC;


SELECT * FROM v$active_session_history WHERE ;

---------------------------------------------------------------------------------
-- Explain Plan
--------------------------------------------------------------------------------
EXPLAIN PLAN FOR 
SELECT * FROM DBA_TABLES;

SELECT * FROM TABLE(dbms_xplan.display);

--------------------------------------------------------------------------------
-- Session Wait Events
--------------------------------------------------------------------------------

SELECT b.object_name,SID,ROW_WAIT_OBJ#,BLOCKING_SESSION,EVENT,STATE,SECONDS_IN_WAIT FROM v$session a,dba_objects b WHERE username=USER AND a.ROW_WAIT_OBJ#=b.object_id ORDER BY SECONDS_IN_WAIT desc;

SELECT event,state,Count(*) FROM v$session_wait GROUP BY event,state ORDER BY 3 DESC;

SELECT * FROM v$waitstat ORDER BY TIME desc;

---------------------------------------------------------------------------------
--- Generating AWR Report
--------------------------------------------------------------------------------
SELECT * FROM DBA_HIST_SNAPSHOT  ORDER BY BEGIN_INTERVAL_TIME desc;

--1.
SELECT * FROM TABLE(dbms_workload_repository.awr_report_html('1411069681','1','14259','14296'));

-- 2.
SQL> $ORACLE_HOME/rdbms/ADMIN/awrrpti.sql



--------------------------------------------------------------------------------
-- SQL by CPU Usage
--------------------------------------------------------------------------------
SELECT sql_text,
sql_id,
Round(cpu_time/1000000) cpu_time,
Round(elapsed_time/1000000) elapsed_time,
Round(USER_IO_WAIT_TIME/1000000) USER_IO_WAIT_TIME,
Round(CONCURRENCY_WAIT_TIME/1000000) CONCURRENCY_WAIT_TIME,
disk_reads,
buffer_gets,
rows_processed
-- SELECT *
FROM v$sqlarea
WHERE PARSING_SCHEMA_NAME=USER
AND SQL_TEXT LIKE '%ELIG%'
ORDER BY   cpu_time desc;

--------------------------------------------------------------------------------
-- Long running querries details
--------------------------------------------------------------------------------
SELECT * FROM v$session_longops where USERNAME =USER AND TIME_REMAINING>0

SELECT b.sql_id,b.sql_fulltext, a.* FROM v$session_longops a, v$sql b WHERE a.sql_id =b.sql_id AND a.USERNAME =USER AND TIME_REMAINING>0  ORDER BY a.sql_id;

select b.sql_id,b.SQL_TEXT,a.* from v$session_longops a, v$sql b where username = user and a.SQL_ID='9pmdc29gh33gh' and a.sql_id=b.sql_id order by START_TIME;

select b.sql_id,substr(b.SQL_TEXT,1,50),OPNAME,min(START_TIME) START_TIME ,max(LAST_UPDATE_TIME),round((max(LAST_UPDATE_TIME)-min(START_TIME))*24*60,2) Exec_MIN
from v$session_longops a, v$sql b
where username = user and b.SQL_TEXT like '%PROF%' and a.sql_id=b.sql_id
group by b.sql_id,substr(b.SQL_TEXT,1,50),OPNAME
order by SQL_ID,START_TIME;



-- SELECT * FROM v$session_longops where USERNAME =USER and sql_id='amjc708n8c96v' ORDER BY  START_TIME DESC;

SELECT * FROM  v$sql_monitor WHERE username=USER AND status='EXECUTING'
--------------------------------------------------------------------------------
-- Identifying resource-incentive SQL
--------------------------------------------------------------------------------

SELECT first_refresh_time,PLAN_OPERATION,PLAN_OPTIONS,PLAN_OBJECT_NAME ,Round(PLAN_CPU_COST/1000000,2) PLAN_CPU_COST,PLAN_IO_COST, OUTPUT_ROWS, PHYSICAL_WRITE_BYTES
FROM v$sql_plan_monitor
WHERE sql_id='0jmjm39um5aan'  AND PLAN_CPU_COST>0  OR PLAN_IO_COST>0
--AND PLAN_OPERATION='HASH JOIN'
ORDER BY PLAN_IO_COST DESC;


SELECT * FROM v$filestat

SELECT * FROM v$sysstat;

SELECT * FROM v$osstat

-------------------------------------------
-- SGA/PGA consumption by user name
-------------------------------------------
SELECT * FROM v$sgastat;

SELECT * FROM v$sesstat
SELECT * FROM v$session

SELECT pool,Round(Sum(BYTES)/1024/1024,2) "value-MB" FROM V$SGASTAT GROUP BY pool;

SELECT * FROM V$SGASTAT;

SELECT * FROM v$pgastat

SELECT Round(Sum(BYTES)/1024/1024/1024,2) "value-GB" FROM V$SGASTAT

SELECT USERNAME,name,Sum(Value/1024/1024) "Value-MB"
FROM v$statname n,
v$session s,
v$sesstat t
WHERE s.sid = t.sid
AND n.STATISTIC# = t.STATISTIC#
AND s.username IS NOT NULL
AND TYPE='USER'
AND username=user
AND n.name IN ('session pga memory','session uga memory')
GROUP BY name,USERNAME
ORDER BY 3 DESC;


--------------------------------------------------------------------------------
-- Query to find program/user/session etc currently using temp space
--------------------------------------------------------------------------------
SELECT
b.TABLESPACE,
b.SEGFILE#,
b.SEGBLK#,
Round(((b.BLOCKS*p.Value)/1024/1024/1024),2) "SIZE-GB",
a.SID,
a.SERIAL#,
a.USERNAME,
a.OSUSER,
a.MACHINE
FROM v$session a,
v$tempseg_usage b,
v$process c,
v$parameter p
WHERE p.NAME='db_block_size'
AND a.saddr = b.SESSION_ADDR
AND a.paddr=c.addr
GROUP BY
b.TABLESPACE,SEGFILE#,SEGBLK#,BLOCKS

SELECT * FROM v$session;

SELECT * FROM v$tempseg_usage WHERE "USER"=USER;

SELECT SQL_FULLTEXT,a.* FROM v$tempseg_usage a, v$sql b WHERE "USER"=USER AND a.sql_id=b.sql_id;

SELECT * FROM v$sort_segment

SELECT * FROM v$sql WHERE sql_id='6csz99xhr3j2v'


--------------------------------------------------------------------------------
-- RAM memomy size
--------------------------------------------------------------------------------

-- TOTAL
SELECT STAT_NAME, Round(Max(VALUE)/1024/1024/1024,2) TOTAL_GB FROM dba_hist_osstat
WHERE STAT_NAME LIKE '%PHYSICAL_MEMORY_BYTES%'
GROUP BY STAT_NAME;
--------------------------------------------------------------------------------
-- Accessing SQL Test Case Builder Using DBMS_SQLDIAG
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--- Script to find highly fragmented tables
--------------------------------------------------------------------------------
SELECT
table_name,
Round((blocks*8)/1024/1024,2) "size (KB)",
Round((num_rows*avg_row_len/1024/1024/1024),2) "actual data(kb)",
(Round((blocks*8/1024/1024),2) - Round((num_rows*avg_row_len/1024/1024/1024),2)) "wasted_space (kb)"
FROM dba_tables
WHERE TABLESPACE_NAME='HI0655001' AND Round((blocks*8),2)>Round((num_rows*avg_row_len/1024),2)
ORDER BY 4 DESC;


SELECT
Round((blocks*8)/1024/1024,2)|| ' GB' "Fragmented Size",
Round((num_rows*avg_row_len/1024/1024/1024),2)||' GB' "Actual Size",
Round((blocks*8)/1024/1024,2) - Round((num_rows*avg_row_len/1024/1024/1024),2) "reclaimable size",
Round(((Round((blocks*8)/1024/1024,2) - Round((num_rows*avg_row_len/1024/1024/1024),2))/Round((blocks*8)/1024/1024,2))*100-10,2) "reclaimable spac %"
FROM user_tables
WHERE table_name='HI_CLAIMS_HMRK_HMRK';



SELECT
OWNER,
TABLE_NAME,
LAST_ANALYZED,
Round((blocks*8)/1024/1024,2)|| ' GB' "Fragmented Size",
Round((num_rows*avg_row_len/1024/1024/1024),2)||' GB' "Actual Size",
Round((blocks*8)/1024/1024,2) - Round((num_rows*avg_row_len/1024/1024/1024),2) "reclaimable size"
--Round(((Round((blocks*8)/1024/1024,2) - Round((num_rows*avg_row_len/1024/1024/1024),2))/Round((blocks*8)/1024/1024,2))*100-10,2) "reclaimable spac %"
FROM dba_tables
WHERE
table_name LIKE 'HI%'
AND
owner='HI0655001'
ORDER BY "reclaimable size" DESC nulls last;




SELECT * FROM user_tables WHERE TABLE_NAME='HI_CLAIMS_HMRK_HMRK';


SELECT * FROM dba_tablespaces WHERE TABLESPACE_NAME=user;

---------------------------------------------------------------------------------
-- Check locking and waiting SID
--------------------------------------------------------------------------------
SELECT
--s.SQL_FULLTEXT,
VH.SID LOCKING_SID,
vs.status,
vs.program program_holding,
vw.sid waiter_sid,
vsw.program program_waiting
FROM v$lock vh,
v$lock vw,
v$session vs ,
--v$sql s,
v$session vsw

WHERE (vh.id1,vh.id2) IN (SELECT id1,id2 FROM v$lock WHERE request=0 INTERSECT   SELECT id1,id2 FROM v$lock WHERE lmode=0)
AND vh.id1=vw.id1
AND vh.id2=vw.id2
AND vh.request=0
AND vw.lmode=0
AND vh.sid=vs.sid
AND vw.sid=vsw.sid
--AND vs.sql_id = s.sql_id
--;
-----------------------------------------------------------------------------------------
--- Basic Table Compression
-----------------------------------------------------------------------------------------
-- 1. Baseline CTAS
CREATE TABLE t1 AS
SELECT * FROM all_objects where ROWNUM<=50000;

-- 2. CTAS with basic compression enabled
CREATE TABLE  t1_compress COMPRESS basic
AS
SELECT * FROM all_objects where ROWNUM<=50000;

-- 3. Normal insert into empty table defined as compresss
CREATE TABLE t1_Normal_insert COMPRESS basic
AS
SELECT * FROM all_objects WHERE ROWNUM=0;

INSERT INTO  t1_Normal_insert SELECT * FROM all_objects WHERE ROWNUM<=50000;

-- 4. Direct path insert into table defined as compress
CREATE TABLE t1_Direct_insert COMPRESS basic
AS
SELECT * FROM all_objects WHERE ROWNUM=0;

INSERT /*+ append */  INTO  t1_Normal_insert SELECT * FROM all_objects WHERE ROWNUM<=50000;

-- 5. CTAS without compression then chang to comprssed.

CREATE TABLE  t1_compress_basic
AS
SELECT * FROM all_objects where ROWNUM<=50000;

ALTER TABLE t1_compress_basic COMPRESS basic;

ALTER TABLE t1_compress_basic move;


SELECT table_name, blocks, pct_free, compression, compress_for,cache
FROM all_tables where COMPRESS_FOR IS NOT NULL;

EXEC dbms_stats.gather_table_stats(ownname=>USER,tabname=>'T1_DIRECT_INSERT', estimate_percent=>dbms_stats.auto_sample_size);
-----------------------------------------------------------------------------------------------------------------