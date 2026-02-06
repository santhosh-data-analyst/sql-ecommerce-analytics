-- ======================================================
-- 08_performance_metrics.sql
-- Goal:
-- Provide a concise KPI-level summary of overall
-- business performance.
-- ======================================================

/*
Core Business Questions:

1. How big is the business?
2. How valuable is the average customer?
3. How efficient is order conversion?
4. How healthy is customer retention?
5. How much revenue is lost to returns?
*/

--------------------------------------------------------
-- 1. Overall Business Size
-- Explanation:
-- High-level snapshot of customers, orders, and revenue.
--------------------------------------------------------

SELECT
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id;

--------------------------------------------------------
-- 2. Average Customer Value
-- Explanation:
-- Average revenue generated per customer.
--------------------------------------------------------

WITH customer_revenue AS (
    SELECT
        c.customer_id,
        SUM(oi.quantity * oi.unit_price) AS customer_revenue
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id
)
SELECT
    ROUND(AVG(customer_revenue), 2) AS avg_customer_value
FROM customer_revenue;

--------------------------------------------------------
-- 3. Order Conversion Efficiency
-- Explanation:
-- Measures how effectively activity converts into orders.
--------------------------------------------------------

SELECT
    ROUND(COUNT(DISTINCT o.customer_id)::DECIMAL / COUNT(DISTINCT c.customer_id), 3) AS order_conversion_rate
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id;

--------------------------------------------------------
-- 4. Customer Retention Health
-- Explanation:
-- Evaluates repeat purchasing behavior.
--------------------------------------------------------

--------------------------------------------------------
-- 5. Revenue Lost Due to Returns
-- Explanation:
-- Revenue reduction caused by returns.
--------------------------------------------------------
