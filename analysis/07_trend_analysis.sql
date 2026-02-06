-- ======================================================
-- 07_trend_analysis.sql
-- Goal:
-- Analyze how key business metrics change over time.
-- ======================================================

/*
Core Business Questions:

1. Revenue trend over time
2. Order volume trend over time
3. Customer activity trend
4. Returns trend over time
5. Net revenue trend after returns
*/

--------------------------------------------------------
-- 1. Revenue trend over time
-- Explanation:
-- Tracks revenue by time period to identify growth,
-- decline, or seasonality.
--------------------------------------------------------

SELECT
    DATE_TRUNC('month', o.order_date) AS order_month,
    SUM(oi.quantity * oi.unit_price) AS monthly_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY order_month
ORDER BY order_month;

--------------------------------------------------------
-- 2. Order volume trend over time
-- Explanation:
-- Measures changes in the number of orders over time.
--------------------------------------------------------

SELECT
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY order_month
ORDER BY order_month;

--------------------------------------------------------
-- 3. Customer activity trend
-- Explanation:
-- Shows how the number of active customers changes over time.
--------------------------------------------------------

SELECT
    DATE_TRUNC('month', order_date) AS order_month,
    COUNT(DISTINCT customer_id) AS active_customers
FROM orders 
GROUP BY order_month
ORDER BY order_month;

--------------------------------------------------------
-- 4. Returns trend over time
-- Explanation:
-- Analyzes whether returns are increasing or decreasing.
--------------------------------------------------------

SELECT
    DATE_TRUNC('month', return_date) AS return_month,
    COUNT(DISTINCT order_id) AS total_returns
FROM returns 
GROUP BY return_month
ORDER BY return_month;

--------------------------------------------------------
-- 5. Net revenue trend after returns
-- Explanation:
-- Tracks actual revenue after subtracting returns.
--------------------------------------------------------

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(oi.quantity * oi.unit_price) AS gross_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY month
),
monthly_returns AS (
    SELECT
        DATE_TRUNC('month', r.return_date) AS month,
        SUM(r.refund_amount) AS returned_revenue
    FROM returns r
    GROUP BY month
)
SELECT
    mr.month,
    mr.gross_revenue,
    COALESCE(mr.gross_revenue - mret.returned_revenue, mr.gross_revenue) AS net_revenue
FROM monthly_revenue mr
LEFT JOIN monthly_returns mret
    ON mr.month = mret.month
ORDER BY mr.month;

