INSERT INTO orders (customer_name, amount, status)
VALUES ('New Customer', 499.99, 'created');

UPDATE orders
SET status = 'paid'
WHERE id = 1;

DELETE FROM orders
WHERE id = 2;