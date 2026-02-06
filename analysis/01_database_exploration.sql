
--=====================================================
--01_database_exploration.sql
--Purpose:
--Validate whether this database can be trusted for
--business analytics and reporting.
--=====================================================

/*
Core Business Questions:
1. Are all core tables populated and in realistic volume?
2. Are primary keys truly unique in core entities?
3. Are there any orphan records in child tables?
4. Order lifecycle validation
5. Do user and order behavior look realistic?
*/

/* ===================================================
SECTION 1: TABLE COVERAGE (Pipeline Health)
Question:
Are all core tables populated and in realistic volume?
Expected:
No table should have 0 rows.
=================================================== */

SELECT 'customers' AS table_name, COUNT(*) AS record_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'returns', COUNT(*) FROM returns
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments;

/* ===================================================
SECTION 2: PRIMARY KEY UNIQUENESS (Entity Integrity)
Question:
Are primary keys truly unique in core entities?
Expected:
All queries return 0 rows.
=================================================== */
-- customers PK check
-- orders PK check
-- products PK check
-- payments PK check
-- shipments PK check
-- returns PK check
-- sessions PK check

SELECT 'customers' AS table_name, COUNT(*) AS duplicate_pk_count
FROM (
	SELECT customer_id
	FROM customers
	GROUP BY customer_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT order_id
	FROM orders
	GROUP BY order_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT order_item_id
	FROM order_items
	GROUP BY order_item_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'categories' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT category_id
	FROM categories
	GROUP BY category_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'payments' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT payment_id
	FROM payments
	GROUP BY payment_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT product_id
	FROM products
	GROUP BY product_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'returns' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT return_id
	FROM returns
	GROUP BY return_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'sessions' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT session_id
	FROM sessions
	GROUP BY session_id
	Having COUNT(*) > 1
) t
UNION ALL
SELECT 'shipments' AS table_name, COUNT(*) AS pk_count
FROM (
	SELECT shipment_id
	FROM shipments
	GROUP BY shipment_id
	Having COUNT(*) > 1
) t;

/* ===================================================
SECTION 3: FOREIGN KEY COVERAGE (Business Truth)
Question:
Are there any orphan records in child tables?
Expected:
All queries return 0 rows.
=================================================== */

-- 1. orders → customers
SELECT 
    o.order_id,
    o.customer_id
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 2. order_items → orders
SELECT 
    oi.order_item_id,
    oi.order_id
FROM order_items oi
LEFT JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 3. order_items → products
SELECT 
    oi.order_item_id,
    oi.product_id
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 4. products → categories
SELECT 
    p.product_id,
    p.category_id
FROM products p
LEFT JOIN categories ca
    ON p.category_id = ca.category_id
WHERE ca.category_id IS NULL;


-- 5. payments → orders
SELECT
    py.payment_id,
    py.order_id
FROM payments py
LEFT JOIN orders o
    ON py.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 6. shipments → orders
SELECT
    sh.shipment_id,
    sh.order_id
FROM shipments sh
LEFT JOIN orders o
    ON sh.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 7. returns → orders
SELECT
    r.return_id,
    r.order_id
FROM returns r
LEFT JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 8. returns → products
SELECT
    r.return_id,
    r.product_id
FROM returns r
LEFT JOIN products p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL;


-- 9. sessions → customers
SELECT
    s.session_id,
    s.customer_id
FROM sessions s
LEFT JOIN customers c
    ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/* ===================================================
SECTION 4: ORDER LIFECYCLE VALIDATION (Process Correctness)
Business Rules:
1. Each order must have exactly 1 payment
2. Each order must have exactly 1 shipment
3. Orders may have 0 or more returns

Expected:
All invalid counts return 0.
=================================================== */

-- 1. Orders with 0 payments
SELECT 
    o.order_id,
    COUNT(py.payment_id) AS payment_count
FROM orders o
LEFT JOIN payments py
    ON o.order_id = py.order_id
GROUP BY o.order_id
HAVING COUNT(py.payment_id) = 0;


-- 2. Orders with more than 1 payment
SELECT 
    o.order_id,
    COUNT(py.payment_id) AS payment_count
FROM orders o
LEFT JOIN payments py
    ON o.order_id = py.order_id
GROUP BY o.order_id
HAVING COUNT(py.payment_id) > 1;


-- 3. Orders with 0 shipments
SELECT 
    o.order_id,
    COUNT(sh.shipment_id) AS shipment_count
FROM orders o
LEFT JOIN shipments sh
    ON o.order_id = sh.order_id
GROUP BY o.order_id
HAVING COUNT(sh.shipment_id) = 0;


-- 4. Orders with more than 1 shipment
SELECT 
    o.order_id,
    COUNT(sh.shipment_id) AS shipment_count
FROM orders o
LEFT JOIN shipments sh
    ON o.order_id = sh.order_id
GROUP BY o.order_id
HAVING COUNT(sh.shipment_id) > 1;

/* ===================================================
SECTION 5: CUSTOMER BEHAVIOR SANITY CHECK (Realism)
Question:
Does user and order behavior look realistic?

Metrics:
a. Orders per customer → MIN / AVG / MAX
b. Sessions per customer → MIN / AVG / MAX

Expected:
MIN can be 0
AVG should be reasonable
MAX should not be extreme
=================================================== */

-- Orders per customer

SELECT
    MIN(order_count) AS min_orders_per_customer,
    ROUND(AVG(order_count),2) AS avg_orders_per_customer,
    MAX(order_count) AS max_orders_per_customer
FROM (
    SELECT
        c.customer_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
) t;

-- Sessions per customer

SELECT
    MIN(session_count) AS min_sessions_per_customer,
    ROUND(AVG(session_count),2) AS avg_sessions_per_customer,
    MAX(session_count) AS max_sessions_per_customer
FROM (
    SELECT
        c.customer_id,
        COUNT(s.session_id) AS session_count
    FROM customers c
    LEFT JOIN sessions s
        ON c.customer_id = s.customer_id
    GROUP BY c.customer_id
) t;

