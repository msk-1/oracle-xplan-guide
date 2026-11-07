-- study ユーザーで FREEPDB1 に接続して実行する。
-- 実行計画の題材にする小さな受注スキーマを作る。
-- 何度流しても同じ状態に戻るよう、先に削除する。
SET ECHO ON
WHENEVER SQLERROR CONTINUE
DROP TABLE order_items PURGE;
DROP TABLE orders      PURGE;
DROP TABLE customers   PURGE;
DROP TABLE products    PURGE;
WHENEVER SQLERROR EXIT FAILURE

-- 顧客: 1万件。地域 (region) は 5 種類で均等に分布する
CREATE TABLE customers (
  customer_id   NUMBER        PRIMARY KEY,
  name          VARCHAR2(50)  NOT NULL,
  region        VARCHAR2(10)  NOT NULL,
  created_at    DATE          NOT NULL
);

INSERT /*+ APPEND */ INTO customers
SELECT level,
       'Customer ' || level,
       CASE MOD(level, 5) WHEN 0 THEN 'KANTO' WHEN 1 THEN 'KANSAI' WHEN 2 THEN 'CHUBU'
                          WHEN 3 THEN 'KYUSHU' ELSE 'TOHOKU' END,
       DATE '2020-01-01' + MOD(level, 1500)
FROM dual CONNECT BY level <= 10000;
COMMIT;

-- 商品: 1000件
CREATE TABLE products (
  product_id    NUMBER        PRIMARY KEY,
  name          VARCHAR2(50)  NOT NULL,
  category      VARCHAR2(20)  NOT NULL,
  price         NUMBER(10)    NOT NULL
);

INSERT /*+ APPEND */ INTO products
SELECT level,
       'Product ' || level,
       'CAT' || LPAD(MOD(level, 20), 2, '0'),
       100 + MOD(level * 37, 9900)
FROM dual CONNECT BY level <= 1000;
COMMIT;

-- 受注: 20万件。status は意図的に偏らせる
--   SHIPPED 約98% / PENDING 約1.5% / CANCELLED 約0.5%
-- 見積り誤差やヒストグラムの章で使う
CREATE TABLE orders (
  order_id      NUMBER        PRIMARY KEY,
  customer_id   NUMBER        NOT NULL REFERENCES customers,
  order_date    DATE          NOT NULL,
  status        VARCHAR2(10)  NOT NULL,
  amount        NUMBER(12)    NOT NULL
);

INSERT /*+ APPEND */ INTO orders
SELECT level,
       MOD(level * 7919, 10000) + 1,
       DATE '2023-01-01' + MOD(level, 1000),
       CASE WHEN MOD(level, 200) = 0 THEN 'CANCELLED'
            WHEN MOD(level, 200) <= 3 THEN 'PENDING'
            ELSE 'SHIPPED' END,
       MOD(level * 13, 50000) + 500
FROM dual CONNECT BY level <= 200000;
COMMIT;

-- 受注明細: 受注 1 件につき 1〜3 行
CREATE TABLE order_items (
  order_id      NUMBER        NOT NULL REFERENCES orders,
  line_no       NUMBER        NOT NULL,
  product_id    NUMBER        NOT NULL REFERENCES products,
  quantity      NUMBER(5)     NOT NULL,
  CONSTRAINT order_items_pk PRIMARY KEY (order_id, line_no)
);

INSERT /*+ APPEND */ INTO order_items
SELECT o.order_id, l.line_no,
       MOD(o.order_id * 31 + l.line_no * 17, 1000) + 1,
       MOD(o.order_id + l.line_no, 5) + 1
FROM orders o
JOIN (SELECT level AS line_no FROM dual CONNECT BY level <= 3) l
  ON l.line_no <= MOD(o.order_id, 3) + 1;
COMMIT;

-- 索引（外部キー列と検索に使う列）
CREATE INDEX orders_customer_ix   ON orders (customer_id);
CREATE INDEX orders_date_ix       ON orders (order_date);
CREATE INDEX orders_status_ix     ON orders (status);
CREATE INDEX order_items_prod_ix  ON order_items (product_id);
CREATE INDEX customers_region_ix  ON customers (region);

-- 統計を取る（ヒストグラムは既定の AUTO に任せる）
BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS(ownname => USER);
END;
/

SELECT table_name, num_rows FROM user_tables ORDER BY table_name;
EXIT
