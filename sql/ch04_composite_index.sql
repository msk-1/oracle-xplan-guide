-- 4章（索引のしくみ）: 複合索引の効果と列の順番を測る
-- study ユーザーで FREEPDB1 に接続して実行する。
-- 作った索引は最後に削除し、スキーマを元の状態に戻す。
SET LINESIZE 200
SET PAGESIZE 200
SET SERVEROUTPUT OFF
SET FEEDBACK OFF
COLUMN plan_table_output FORMAT A200

PROMPT ===== (1) 単一列索引 (order_date) だけのとき =====
SELECT /*+ GATHER_PLAN_STATISTICS INDEX(orders orders_date_ix) */ SUM(amount) FROM orders
WHERE order_date BETWEEN DATE '2024-03-01' AND DATE '2024-03-02' AND amount > 49000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

CREATE INDEX orders_date_amount_ix ON orders (order_date, amount);

PROMPT ===== (2) 複合索引 (order_date, amount) を作った後 =====
SELECT /*+ GATHER_PLAN_STATISTICS INDEX(orders orders_date_amount_ix) */ SUM(amount) FROM orders
WHERE order_date BETWEEN DATE '2024-03-01' AND DATE '2024-03-02' AND amount > 49000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

PROMPT ===== (3) 索引にない列 (status) も SELECT すると表を読む =====
SELECT /*+ GATHER_PLAN_STATISTICS INDEX(orders orders_date_amount_ix) */ MAX(status) FROM orders
WHERE order_date BETWEEN DATE '2024-03-01' AND DATE '2024-03-02' AND amount > 49000;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

PROMPT ===== (4) 先頭列 (order_date) の条件がないとき =====
SELECT /*+ GATHER_PLAN_STATISTICS */ COUNT(*) FROM orders WHERE amount = 25500;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

PROMPT ===== (5) 列に関数をかけると RANGE SCAN できない =====
SELECT /*+ GATHER_PLAN_STATISTICS */ SUM(amount) FROM orders WHERE TRUNC(order_date, 'MM') = DATE '2024-03-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

PROMPT ===== (6) 同じ意味を関数なしで書く =====
SELECT /*+ GATHER_PLAN_STATISTICS */ SUM(amount) FROM orders
WHERE order_date >= DATE '2024-03-01' AND order_date < DATE '2024-04-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

DROP INDEX orders_date_amount_ix;

-- 列の順番の比較: 等価条件の列 (customer_id) と範囲条件の列 (order_date)
CREATE INDEX orders_cust_date_ix ON orders (customer_id, order_date);
CREATE INDEX orders_date_cust_ix ON orders (order_date, customer_id);

PROMPT ===== (7) (customer_id, order_date): 等価の列が先 =====
SELECT /*+ GATHER_PLAN_STATISTICS INDEX(orders orders_cust_date_ix) */ COUNT(*) FROM orders
WHERE customer_id = 42 AND order_date >= DATE '2024-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

PROMPT ===== (8) (order_date, customer_id): 範囲の列が先 =====
SELECT /*+ GATHER_PLAN_STATISTICS INDEX(orders orders_date_cust_ix) */ COUNT(*) FROM orders
WHERE customer_id = 42 AND order_date >= DATE '2024-01-01';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

DROP INDEX orders_cust_date_ix;
DROP INDEX orders_date_cust_ix;

PROMPT ===== 後片付けの確認: 残っている索引 =====
SELECT index_name FROM user_indexes WHERE table_name = 'ORDERS' ORDER BY index_name;
EXIT
