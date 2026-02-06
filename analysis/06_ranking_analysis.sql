-- ======================================================
-- 06_ranking_analysis.sql
-- Goal:
-- Rank customers, products, categories, and time periods
-- based on revenue performance.
-- ======================================================

/*
Core Business Questions:
1. Top customers by revenue
2. Top products by revenue
3. Top-performing categories
4. Best-performing months
5. Bottom performers
*/

-- ------------------------------------------------------
-- 1. Top customers by revenue
-- Explanation:
-- Ranks customers based on total revenue contribution.
-- ------------------------------------------------------

SELECT
	customer_id,
	total_revenue,
	RANK() OVER(ORDER BY total_revenue DESC) AS customer_rank
FROM (
	SELECT
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
GROUP BY o.customer_id
);

-- ------------------------------------------------------
-- 2. Top products by revenue
-- Explanation:
-- Identifies products generating the highest revenue.
-- ------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS product_rank
FROM (
    SELECT
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi
    GROUP BY oi.product_id
) product_revenue
INNER JOIN products p
    ON product_revenue.product_id = p.product_id;

-- ------------------------------------------------------
-- 3. Top-performing categories
-- Explanation:
-- Ranks categories by total revenue.
-- ------------------------------------------------------

SELECT
    c.category_id,
    c.category_name,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS category_rank
FROM (
    SELECT
        p.category_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY p.category_id
) category_revenue
INNER JOIN categories c
    ON category_revenue.category_id = c.category_id;

-- ------------------------------------------------------
-- 4. Best-performing months
-- Explanation:
-- Ranks months based on revenue generated.
-- ------------------------------------------------------

SELECT
    month,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue DESC) AS month_rank
FROM (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
);

-- ------------------------------------------------------
-- 5. Bottom performers
-- Explanation:
-- Identifies lowest revenue contributors.
-- ------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    total_revenue,
    RANK() OVER (ORDER BY total_revenue ASC) AS bottom_rank
FROM (
    SELECT
        oi.product_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM order_items oi
    GROUP BY oi.product_id
) product_revenue
INNER JOIN products p
    ON product_revenue.product_id = p.product_id;
