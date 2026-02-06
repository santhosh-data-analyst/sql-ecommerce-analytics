-- ======================================================
-- 05_retention_analysis.sql
-- Goal:
-- Analyze customer retention and churn behavior
-- over time.
-- ======================================================

/*
Core Business Questions:
1. First-time vs returning customers
2. Customer return rate
3. Time to second purchase
4. Early churn within 30 days
5. Cohort-based retention (Month 0 → Month 1)
*/

-- ------------------------------------------------------
-- 1. First-time vs returning customers
-- Explanation:
-- Measures baseline customer retention.
-- ------------------------------------------------------

WITH customer_orders AS (
    SELECT
        c.customer_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-time customer'
        WHEN order_count > 1 THEN 'Returning customer'
		ELSE 'No ordered customer'
    END AS customer_type,
    COUNT(*) AS customer_count
FROM customer_orders
GROUP BY customer_type
ORDER BY customer_type DESC;

-- ------------------------------------------------------
-- 2. Customer return rate
-- Explanation:
-- Calculates the percentage of returning customers.
-- ------------------------------------------------------

WITH customer_orders AS (
    SELECT
        c.customer_id,
        COUNT(o.order_id) AS order_count
    FROM customers c
    LEFT JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT
    ROUND(100.0 * COUNT(CASE WHEN order_count > 1 THEN 1 END)/ COUNT(*),2) AS customer_return_rate_pct
FROM customer_orders;


-- ------------------------------------------------------
-- 3. Time to second purchase
-- Explanation:
-- Measures how quickly customers return after first purchase.
-- ------------------------------------------------------

WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_rank
    FROM orders o
),
first_second_orders AS (
    SELECT
        customer_id,
        MAX(CASE WHEN order_rank = 1 THEN order_date END) AS first_order_date,
        MAX(CASE WHEN order_rank = 2 THEN order_date END) AS second_order_date
    FROM ranked_orders
    GROUP BY customer_id
)
SELECT
    ROUND(AVG(DATE_PART('day', second_order_date - first_order_date))::NUMERIC,2)
		AS avg_days_to_second_purchase
FROM first_second_orders
WHERE second_order_date IS NOT NULL;


-- ------------------------------------------------------
-- 4. Early churn (30-day rule)
-- Explanation:
-- Identifies customers who churned within 30 days.
-- ------------------------------------------------------

WITH ranked_orders AS (
    SELECT
        o.customer_id,
        o.order_date,
        ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date) AS order_rank
    FROM orders o
),
first_second_orders AS (
    SELECT
        customer_id,
        MAX(CASE WHEN order_rank = 1 THEN order_date END) AS first_order_date,
        MAX(CASE WHEN order_rank = 2 THEN order_date END) AS second_order_date
    FROM ranked_orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS early_churned_customers
FROM first_second_orders
WHERE
    second_order_date IS NULL
    OR second_order_date > first_order_date + INTERVAL '30 days';

-- ------------------------------------------------------
-- 5. Monthly cohort retention (Month 0 → Month 1)
-- Explanation:
-- Compares retention across customer cohorts.
-- ------------------------------------------------------

WITH customer_cohorts AS (
    SELECT
        c.customer_id,
        DATE_TRUNC('month', MIN(o.order_date)) AS cohort_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
),
monthly_orders AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_date) AS order_month
    FROM orders o
)
SELECT
    cc.cohort_month,
    COUNT(DISTINCT cc.customer_id) AS cohort_size,
    COUNT(DISTINCT mo.customer_id) AS month_1_returning_customers
FROM customer_cohorts cc
LEFT JOIN monthly_orders mo
    ON cc.customer_id = mo.customer_id
   AND mo.order_month = cc.cohort_month + INTERVAL '1 month'
GROUP BY cc.cohort_month
ORDER BY cc.cohort_month;
