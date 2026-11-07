-- 1章: EXPLAIN PLAN と DISPLAY_CURSOR を同じ SQL で比べる
-- study ユーザーで FREEPDB1 に接続して実行する。
SET LINESIZE 200
SET PAGESIZE 200
SET TRIMSPOOL ON

PROMPT ===== (1) EXPLAIN PLAN: 実行せずに「予定」を表示する =====
EXPLAIN PLAN FOR
SELECT c.region, COUNT(*) AS cnt, SUM(o.amount) AS total
FROM   orders o
JOIN   customers c ON c.customer_id = o.customer_id
WHERE  o.status = 'PENDING'
GROUP  BY c.region;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

PROMPT ===== (2) DISPLAY_CURSOR: 実際に実行し、実績値と並べて表示する =====
-- SERVEROUTPUT が ON だと直前の SQL が DBMS_OUTPUT 呼び出しになり、計画が取れない
SET SERVEROUTPUT OFF

SELECT /*+ GATHER_PLAN_STATISTICS */
       c.region, COUNT(*) AS cnt, SUM(o.amount) AS total
FROM   orders o
JOIN   customers c ON c.customer_id = o.customer_id
WHERE  o.status = 'PENDING'
GROUP  BY c.region;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
EXIT
