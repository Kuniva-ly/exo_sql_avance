DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    full_name     TEXT        NOT NULL,
    city          TEXT        NOT NULL,
    created_at    DATE        NOT NULL
);

INSERT INTO customers (customer_id, full_name, city, created_at) VALUES
    (1, 'Alice Martin',    'Lille',   DATE '2024-01-10'),
    (2, 'Bruno Dubois',    'Paris',   DATE '2024-02-05'),
    (3, 'Chloé Petit',     'Lyon',    DATE '2024-03-12'),
    (4, 'David Leroy',     'Lille',   DATE '2024-04-01');

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    name         TEXT        NOT NULL,
    category     TEXT        NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL
);

INSERT INTO products (product_id, name, category, unit_price) VALUES
    (1, 'Clavier mécanique',  'Informatique', 79.90),
    (2, 'Souris gamer',       'Informatique', 49.90),
    (3, 'Casque audio',       'Audio',        89.00),
    (4, 'Tapis de souris',    'Accessoires',  19.90);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers(customer_id),
    order_date   DATE    NOT NULL,
    status       TEXT    NOT NULL   -- 'PENDING', 'COMPLETED', 'CANCELLED'
);

INSERT INTO orders (order_id, customer_id, order_date, status) VALUES
    (1, 1, DATE '2024-05-01', 'COMPLETED'),
    (2, 1, DATE '2024-05-02', 'COMPLETED'),
    (3, 2, DATE '2024-05-02', 'COMPLETED'),
    (4, 2, DATE '2024-05-03', 'PENDING'),
    (5, 3, DATE '2024-05-03', 'COMPLETED'),
    (6, 4, DATE '2024-05-04', 'CANCELLED');

CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       INTEGER NOT NULL REFERENCES orders(order_id),
    product_id     INTEGER NOT NULL REFERENCES products(product_id),
    quantity       INTEGER NOT NULL,
    unit_price     NUMERIC(10,2) NOT NULL
);

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 1, 79.90),
    (2, 1, 4, 2, 19.90),
    (3, 2, 2, 1, 49.90),
    (4, 2, 4, 1, 19.90),
    (5, 3, 3, 1, 89.00),
    (6, 5, 1, 2, 79.90),
    (7, 5, 2, 1, 49.90);

---1---

CREATE VIEW v_order_summary AS
SELECT 
    o.order_id,
    c.full_name AS customer_name,
    o.order_date,
    o.status,
    SUM(oi.quantity * oi.unit_price) AS total_amount
FROM 
    orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, c.full_name, o.order_date, o.status;

SELECT * 
FROM v_order_summary
WHERE status = 'COMPLETED'
ORDER BY order_date , order_id ;

---2---
CREATE MATERIALIZED VIEW  v_daily_dashboard_view AS
SELECT 
	o.order_date,
	COUNT(o.order_id) AS completed_order,
	SUM(oi.quantity * oi.unit_price) AS total_amount
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'COMPLETED'
GROUP BY o.order_date;

SELECT *
FROM v_daily_dashboard_view
ORDER BY order_date;

SELECT *
FROM v_daily_dashboard_view
WHERE total_amount > 200
ORDER BY order_date;

---3---

CREATE MATERIALIZED VIEW v_customer_sales_summary AS
SELECT
    c.customer_id,
    c.full_name AS customer_name,
    COUNT(o.order_id) AS completed_orders,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'COMPLETED'
GROUP BY c.customer_id, c.full_name;

SELECT * 
FROM v_customer_sales_summary
ORDER BY total_revenue DESC;

SELECT * 
FROM v_customer_sales_summary
WHERE completed_orders >= 2
ORDER BY total_revenue DESC;

---4---

CREATE INDEX idx_daily_sales_summary_order_date ON v_daily_dashboard_view (order_date);
CREATE INDEX idx_customer_sales_summary_total_revenue ON v_customer_sales_summary (total_revenue);
CREATE INDEX idx_customer_sales_summary_completed_orders_total_revenue ON v_customer_sales_summary (completed_orders, total_revenue);

---5---

INSERT INTO orders (order_id, customer_id, order_date, status)
VALUES (7, 2, DATE '2024-05-04', 'COMPLETED');

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
    (8, 7, 3, 1, 89.00),
    (9, 7, 4, 1, 19.90);

SELECT *
FROM v_order_summary
WHERE order_id = 7;

SELECT *
FROM v_daily_dashboard_view
WHERE order_date = '2024-05-04';

REFRESH MATERIALIZED VIEW v_daily_dashboard_view;

SELECT * 
FROM v_customer_sales_summary
ORDER BY total_revenue DESC;



