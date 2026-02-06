-- ======================================================
-- 03_sales_analysis.sql
-- Goal:
-- Understand financial performance and revenue health
-- of the business.
-- ======================================================

/*
Core Business Questions:
1. Total revenue and total orders
2. Revenue trend over time
3. Average Order Value (AOV)
4. Payment vs Revenue validation
5. Revenue loss due to returns
*/

-- ------------------------------------------------------
-- 1. Total revenue and total orders
-- Explanation:
-- Measures the overall business scale and baseline performance.
-- ------------------------------------------------------

SELECT
	SUM(revenue) AS total_revenue,
	COUNT(order_id) AS total_orders
FROM (
	SELECT
		order_id,
		SUM(quantity * unit_price) AS revenue
	FROM order_items
	GROUP BY order_id
);

-- ------------------------------------------------------
-- 2. Revenue trend over time
-- Explanation:
-- Understands growth, seasonality, and performance stability.
-- ------------------------------------------------------

SELECT
	period,
	COUNT(order_id) AS total_orders,
	SUM(revenue) AS total_revenue
FROM (
	SELECT
		DATE_TRUNC('month', o.order_date) AS period,
		oi.order_id,
		SUM(oi.quantity * oi.unit_price) AS revenue
	FROM orders o
	LEFT JOIN order_items oi
		ON o.order_id = oi.order_id
	GROUP BY DATE_TRUNC('month', o.order_date), oi.order_id
) t
GROUP BY period
ORDER BY period;

-- ------------------------------------------------------
-- 3. Average Order Value (AOV)
-- Explanation:
-- Shows how much revenue each order generates on average.
-- ------------------------------------------------------

SELECT
    ROUND(AVG(order_revenue), 2) AS aov
FROM (
    SELECT
        order_id,
        SUM(quantity * unit_price) AS order_revenue
    FROM order_items
    GROUP BY order_id
);


-- ------------------------------------------------------
-- 4. Payment alignment with revenue
-- Explanation:
-- Validates whether recorded payments match calculated revenue.
-- ------------------------------------------------------

SELECT
    SUM(order_revenue) AS total_revenue,
    SUM(total_payments) AS total_payments,
    SUM(order_revenue - total_payments) AS total_difference
FROM (
    SELECT
        r.order_id,
        r.order_revenue,
        COALESCE(p.payments, 0) AS total_payments
    FROM (
        SELECT order_id, SUM(quantity * unit_price) AS order_revenue
        FROM order_items
        GROUP BY order_id
    ) r
    LEFT JOIN (
        SELECT 
			order_id, 
			SUM(amount) AS payments
        FROM payments
        GROUP BY order_id
    ) p
    ON r.order_id = p.order_id
);

-- ------------------------------------------------------
-- 5. Revenue loss due to returns
-- Explanation:
-- Measures operational and financial leakage.
-- ------------------------------------------------------

SELECT
    SUM(order_revenue) AS total_revenue,
    SUM(returned_revenue) AS total_returned_revenue,
    SUM(order_revenue - returned_revenue) AS net_revenue
FROM (
    SELECT
        r.order_id,
        r.order_revenue,
        COALESCE(rt.returned_revenue, 0) AS returned_revenue
    FROM (
        SELECT
            order_id,
            SUM(quantity * unit_price) AS order_revenue
        FROM order_items
        GROUP BY order_id
    ) r
    LEFT JOIN (
        SELECT
            order_id,
            SUM(refund_amount) AS returned_revenue
        FROM returns
        GROUP BY order_id
    ) rt
    ON r.order_id = rt.order_id
) t;
