-- 3章: 列の意味。Starts / E-Rows / A-Rows / Buffers / A-Time を読む
-- study ユーザーで FREEPDB1 に接続して実行する。
SET LINESIZE 200
SET PAGESIZE 200
SET SERVEROUTPUT OFF

-- 関西の顧客の受注について、明細行数を数える
-- 結合方式をわざと NESTED LOOPS に固定し、内側が何度も実行される様子を見る
SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c o i) USE_NL(o) USE_NL(i) */
       COUNT(*) AS item_cnt
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items i  ON i.order_id    = o.order_id
WHERE  c.region = 'KANSAI';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- 比較用: ヒントなし。オプティマイザに結合方式を任せる
SELECT /*+ GATHER_PLAN_STATISTICS */
       COUNT(*) AS item_cnt
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items i  ON i.order_id    = o.order_id
WHERE  c.region = 'KANSAI';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- Cost の比較: 実行せずに、2 つの計画の見積りコストを表示する
EXPLAIN PLAN FOR
SELECT /*+ LEADING(c o i) USE_NL(o) USE_NL(i) */
       COUNT(*)
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items i  ON i.order_id    = o.order_id
WHERE  c.region = 'KANSAI';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +ROWS +COST'));

EXPLAIN PLAN FOR
SELECT COUNT(*)
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items i  ON i.order_id    = o.order_id
WHERE  c.region = 'KANSAI';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +ROWS +COST'));
-- A-Rows を読み違える例: 最初の 50 行だけ取り出して閉じる（画面ツールの動きをまねる）
DECLARE
  CURSOR cur IS SELECT /*+ GATHER_PLAN_STATISTICS partial_fetch_demo */ o.order_id, c.name
                FROM orders o JOIN customers c ON c.customer_id = o.customer_id;
  r cur%ROWTYPE;
BEGIN
  OPEN cur;
  FOR k IN 1..50 LOOP FETCH cur INTO r; END LOOP;
  CLOSE cur;
END;
/

-- PL/SQL から実行した SQL は「直前の SQL」にならないため、V$SQL で SQL_ID を探して表示する
SELECT p.*
FROM   v$sql s,
       TABLE(DBMS_XPLAN.DISPLAY_CURSOR(s.sql_id, s.child_number, 'ALLSTATS LAST')) p
WHERE  s.sql_text LIKE 'SELECT /*+ GATHER_PLAN_STATISTICS partial_fetch_demo%';

-- 小さな例: 顧客 3 人。Starts / E-Rows / A-Rows の関係を数えて確かめる
-- c.name を SELECT しないと結合除去が起き、別の形の計画になる
SELECT /*+ GATHER_PLAN_STATISTICS LEADING(c o) USE_NL(o) INDEX(o orders_customer_ix) FULL(c) */
       MAX(c.name), COUNT(o.amount)
FROM   customers c
JOIN   orders o ON o.customer_id = c.customer_id
WHERE  c.customer_id IN (1, 6, 11);

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
EXIT
