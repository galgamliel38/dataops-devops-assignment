-- ============================================================
-- test-cdc.sql
-- Run these against ordersdb to trigger CDC events
-- Usage: psql -h <DB_PUBLIC_IP> -U debezium -d ordersdb -f test-cdc.sql
-- ============================================================

-- INSERT – triggers a CREATE (op=c) event
INSERT INTO orders (customer_name, amount, status)
VALUES ('New Customer', 499.99, 'created');

-- UPDATE – triggers an UPDATE (op=u) event
UPDATE orders
SET status = 'paid'
WHERE id = 1;

-- DELETE – triggers a DELETE (op=d) event
DELETE FROM orders
WHERE id = 2;

-- Verify locally
SELECT * FROM orders ORDER BY id;
