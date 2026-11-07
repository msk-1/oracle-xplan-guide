-- 2章: 読む順番。4 表を結合し、Id の順番と実行の順番が異なる計画を観察する
-- study ユーザーで FREEPDB1 に接続して実行する。
SET LINESIZE 200
SET PAGESIZE 200
SET SERVEROUTPUT OFF

-- 顧客 42 の受注について、明細と商品名を出す
SELECT /*+ GATHER_PLAN_STATISTICS */
       o.order_id, o.order_date, p.name AS product, i.quantity
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items i  ON i.order_id    = o.order_id
JOIN   products p     ON p.product_id  = i.product_id
WHERE  c.customer_id = 42
ORDER  BY o.order_id, i.line_no;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- 結合除去の確認: customers の列 (c.name) を SELECT に加えると CUSTOMERS が計画に現れる
SELECT /*+ GATHER_PLAN_STATISTICS */
       c.name AS customer, o.order_id, o.order_date, p.name AS product, i.quantity
FROM   customers c
JOIN   orders o       ON o.customer_id = c.customer_id
JOIN   order_items i  ON i.order_id    = o.order_id
JOIN   products p     ON p.product_id  = i.product_id
WHERE  c.customer_id = 42
ORDER  BY o.order_id, i.line_no;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
EXIT
