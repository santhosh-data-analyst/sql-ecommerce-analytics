
--=====================================================
--02_customer_analysis.sql
--Purpose:
--Understand customer behavior and identify where revenue actually comes from.
--=====================================================

/*
Core Business Questions:
1. Customer distribution by activity
2. Revenue per customer
3. Revenue concentration
4. Buying behavior
5. Recency analysis
6. RFM segmentation
7. Churn risk customers
8. Revenue by RFM segments
*/

-------------------------------------------------------
-- 1. Customer distribution by activity
-- Define inactive, one-time, repeat, loyal
-------------------------------------------------------

SELECT
	activity_segment,
	COUNT(*) AS customer_count
FROM (
	SELECT
		c.customer_id,
		COUNT(o.order_id) AS order_count,
		CASE 
			WHEN COUNT(o.order_id) = 0 THEN 'INACTIVE'
			WHEN COUNT(o.order_id) = 1 THEN 'ONE_TIME'
			WHEN COUNT(o.order_id) BETWEEN 2 AND 4 THEN 'REPEAT'
			WHEN COUNT(o.order_id) >= 5 THEN 'LOYAL'
		END activity_segment
		FROM customers c
		LEFT JOIN orders o
			ON c.customer_id = o.customer_id
		GROUP BY c.customer_id
) t
GROUP BY activity_segment

-------------------------------------------------------
-- 2. Revenue per customer
-- Who generates the most revenue
-------------------------------------------------------

-- Using Subquery
SELECT
    o.customer_id,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY SUM(oi.quantity * oi.unit_price) DESC
LIMIT 20;

-- Using CTE
WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT
    customer_id,
    total_revenue
FROM customer_revenue
ORDER BY total_revenue DESC;


-------------------------------------------------------
-- 3. Revenue concentration
-- Pareto: top 20% vs rest
-------------------------------------------------------

WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),

cumulative_calculation AS (
	SELECT
		customer_id,
		total_revenue,
		SUM(total_revenue) OVER () AS total_business_revenue,
		SUM(total_revenue) OVER (ORDER BY total_revenue DESC) cumulative_revenue
	FROM customer_revenue
)

SELECT
    customer_id,
    total_revenue,
	cumulative_revenue,
	CONCAT(ROUND(cumulative_revenue * 100 / total_business_revenue, 2), '%') AS cumulative_revenue_pct
FROM cumulative_calculation
ORDER BY total_revenue DESC;

-------------------------------------------------------
-- 4. Buying behavior
-- Frequency vs Average Order Value
-------------------------------------------------------

WITH customer_revenue AS (
    SELECT
        o.customer_id,
		COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
)

SELECT
    customer_id,
	total_orders,
    total_revenue,
    ROUND(total_revenue / total_orders, 2) AS avg_order_value
FROM customer_revenue
ORDER BY customer_id;

-------------------------------------------------------
-- 5. Recency analysis
-- Days since last order
-------------------------------------------------------

WITH last_order_per_customer AS (
    SELECT
        customer_id,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id
)

SELECT
    customer_id,
	last_order_date,
	DATE_PART('day',(CURRENT_DATE - last_order_date)) AS days_since_last_order
FROM last_order_per_customer
ORDER BY days_since_last_order;

-------------------------------------------------------
-- 6. RFM segmentation
-- R, F, M scoring
-------------------------------------------------------

WITH rfm_base AS (
    SELECT
        c.customer_id,
		DATE_PART('day',(CURRENT_DATE - MAX(o.order_date))) AS days_since_last_order,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id
),

rfm_scores AS (
    SELECT
        customer_id,
        days_since_last_order,
        total_orders,
        total_revenue,
        6 - NTILE(5) OVER (ORDER BY COALESCE(days_since_last_order, 9999) ASC) AS r,
        NTILE(5) OVER (ORDER BY COALESCE(total_orders, 0) DESC) AS f,
        NTILE(5) OVER (ORDER BY COALESCE(total_revenue, 0) DESC) AS m
    FROM rfm_base
)

SELECT
    customer_id,
    days_since_last_order,
    total_orders,
    total_revenue,
    r,
    f,
    m,
	CONCAT(r,f,m) AS rfm
FROM rfm_scores
ORDER BY r DESC, f DESC, m DESC;

-------------------------------------------------------
-- 7. Churn risk customers
-- Simple rule using R + F
-------------------------------------------------------

WITH rfm_base AS (
    SELECT
        c.customer_id,
		DATE_PART('day',(CURRENT_DATE - MAX(o.order_date))) AS days_since_last_order,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id
),

rfm_scores AS (
    SELECT
        customer_id,
        days_since_last_order,
        total_orders,
        total_revenue,
        6 - NTILE(5) OVER (ORDER BY COALESCE(days_since_last_order, 9999) ASC) AS r,
        NTILE(5) OVER (ORDER BY COALESCE(total_orders, 0) DESC) AS f,
        NTILE(5) OVER (ORDER BY COALESCE(total_revenue, 0) DESC) AS m
    FROM rfm_base
)

SELECT
    customer_id,
    days_since_last_order,
    total_orders,
    total_revenue,
    r,
    f,
    m,
    CONCAT(r,f,m) AS rfm,
    CASE
        WHEN r = 1 THEN 'Almost Lost'
        WHEN r <= 2 AND f <= 2 THEN 'High Risk'
        WHEN r <= 2 AND f >= 4 THEN 'High Value At Risk'
        ELSE 'Low Risk'
    END AS churn_risk
FROM rfm_scores
ORDER BY
    CASE
        WHEN r = 1 THEN 1
        WHEN r <= 2 AND f >= 4 THEN 2
        WHEN r <= 2 AND f <= 2 THEN 3
        ELSE 4
    END,
    r ASC,
    f ASC;

-------------------------------------------------------
-- 8. Revenue by RFM segments
-------------------------------------------------------

WITH rfm_base AS (
    SELECT
        c.customer_id,
        DATE_PART('day', (CURRENT_DATE - MAX(o.order_date))) AS recency_days,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.quantity * oi.unit_price) AS total_revenue
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id
),

rfm_scores AS (
    SELECT
        customer_id,
        COALESCE(recency_days, 9999) AS recency_days,
        COALESCE(total_orders, 0) AS total_orders,
        COALESCE(total_revenue, 0) AS total_revenue,
        6 - NTILE(5) OVER (ORDER BY COALESCE(recency_days, 9999) ASC) AS r,
        NTILE(5) OVER (ORDER BY COALESCE(total_orders, 0) DESC) AS f,
        NTILE(5) OVER (ORDER BY COALESCE(total_revenue, 0) DESC) AS m
    FROM rfm_base
),

rfm_labeled AS (
    SELECT
        *,
        CONCAT(r, f, m) AS rfm,
        CASE
            WHEN r = 5 AND f = 5 AND m = 5 THEN 'Champions'
            WHEN r >= 4 AND f >= 4 AND m >= 4 THEN 'Loyal Customers'
            WHEN r >= 4 AND f <= 2 AND m >= 4 THEN 'Big Spenders (New)'
            WHEN r >= 4 AND f >= 2 AND m <= 3 THEN 'Potential Loyalists'
            WHEN r <= 2 AND f >= 4 AND m >= 4 THEN 'At Risk (High Value)'
            WHEN r <= 2 AND f <= 2 AND m <= 2 THEN 'Lost Customers'
            WHEN r <= 2 AND f >= 3 THEN 'At Risk'
            ELSE 'Others'
        END AS rfm_segment
    FROM rfm_scores
)

SELECT
    rfm_segment,
    COUNT(*) AS customer_count,
    SUM(total_revenue) AS segment_revenue,
    CONCAT(ROUND(SUM(total_revenue) * 100.0 / SUM(SUM(total_revenue)) OVER (),2), '%') AS revenue_pct
FROM rfm_labeled
GROUP BY rfm_segment
ORDER BY
    CASE rfm_segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyal Customers' THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'Big Spenders (New)' THEN 4
        WHEN 'At Risk (High Value)' THEN 5
        WHEN 'At Risk' THEN 6
        WHEN 'Lost Customers' THEN 7
        ELSE 8
    END;


