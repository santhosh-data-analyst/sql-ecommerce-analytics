-- ======================================================
-- 04_product_analysis.sql
-- Goal:
-- Identify which products and categories drive revenue,
-- volume, and quality performance.
-- ======================================================

/*
Core Business Questions:
1. Which products generate the most revenue?
2. Which categories generate the most revenue?
3. Which products sell frequently vs expensively?
4. Which products have the highest return rates?
5. Are there underperforming products?
*/

-- ------------------------------------------------------
-- 1. Which products generate the most revenue?
-- Explanation:
-- Finds the products that contribute the highest total revenue.
-- ------------------------------------------------------

SELECT 
    p.product_id,
    p.product_name,
    SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) AS total_revenue
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------
-- 2. Which categories generate the most revenue?
-- Explanation:
-- Finds which product categories earn the most money.
-- ------------------------------------------------------

SELECT 
    c.category_id,
    c.category_name,
    SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) AS total_revenue
FROM categories c
JOIN products p
    ON c.category_id = p.category_id
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------
-- 3. Which products sell frequently vs expensively?
-- Explanation:
-- Compares sales volume with product price impact.
-- ------------------------------------------------------

SELECT 
    p.product_id,
    p.product_name,
    SUM(COALESCE(oi.quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) AS total_revenue
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- ------------------------------------------------------
-- 4. Which products have the highest return rates?
-- Explanation:
-- Identifies products with the most returns compared to sales.
-- ------------------------------------------------------

SELECT 
    p.product_id,
    p.product_name,
    SUM(COALESCE(oi.quantity, 0)) AS total_sold_quantity,
    SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) AS total_revenue,
    SUM(COALESCE(r.refund_amount, 0)) AS total_refund_amount,
    ROUND(
        SUM(COALESCE(r.refund_amount, 0)) * 1.0 /
        NULLIF(SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)), 0), 2
    ) AS refund_rate
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN returns r
    ON oi.order_id = r.order_id
   AND oi.product_id = r.product_id
GROUP BY p.product_id, p.product_name
ORDER BY refund_rate DESC NULLS LAST;

-- ------------------------------------------------------
-- 5. Are there underperforming products?
-- Explanation:
-- Finds products with low sales, low revenue, or high returns.
-- ------------------------------------------------------

SELECT
    p.product_id,
    p.product_name,
    SUM(COALESCE(oi.quantity, 0)) AS total_sold_quantity,
    SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) AS total_revenue,
    SUM(COALESCE(r.refund_amount, 0)) AS total_refund_amount,
    ROUND(
        SUM(COALESCE(r.refund_amount, 0)) * 1.0 /
        NULLIF(SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)), 0),
        4
    ) AS refund_rate
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
LEFT JOIN returns r
    ON oi.order_id = r.order_id
   AND oi.product_id = r.product_id
GROUP BY p.product_id, p.product_name
HAVING
    SUM(COALESCE(oi.quantity, 0)) < 10
    OR SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)) < 5000
    OR (SUM(COALESCE(r.refund_amount, 0)) * 1.0 /
        NULLIF(SUM(COALESCE(oi.quantity, 0) * COALESCE(oi.unit_price, 0)), 0)) > 0.10
ORDER BY refund_rate DESC NULLS LAST;
