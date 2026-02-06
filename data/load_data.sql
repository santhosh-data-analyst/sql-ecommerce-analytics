/*
===========================================================
File: load_data.sql
Project: E-commerce Customer & Revenue Analysis
Purpose:
    This file documents and validates the data loading process.
    It does NOT insert raw data. Instead, it ensures that:

    - All core tables contain data
    - Referential integrity is preserved
    - Financial totals are reconciled
    - Behavioral and logistics data follow business logic

    Data itself was generated using Python + Faker scripts.
    This SQL file proves that the dataset is production-valid.
===========================================================
*/

-- =========================================================
-- 1. Row Count Validation
-- Ensures all core tables contain data
-- =========================================================

SELECT 'customers'   AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'products',   COUNT(*) FROM products
UNION ALL
SELECT 'orders',     COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL
SELECT 'payments',   COUNT(*) FROM payments
UNION ALL
SELECT 'shipments',  COUNT(*) FROM shipments
UNION ALL
SELECT 'returns',    COUNT(*) FROM returns
UNION ALL
SELECT 'sessions',   COUNT(*) FROM sessions;


-- =========================================================
-- 2. Financial Reconciliation
-- Order totals must match line item aggregation
-- =========================================================

SELECT COUNT(*) AS mismatched_orders
FROM orders o
JOIN (
    SELECT 
        order_id,
        SUM(quantity * unit_price - discount) AS calculated_total
    FROM order_items
    GROUP BY order_id
) sub ON o.order_id = sub.order_id
WHERE o.total_amount <> sub.calculated_total;


-- =========================================================
-- 3. Payments Consistency Checks
-- Ensures payment amounts match order values
-- =========================================================

SELECT COUNT(*) AS invalid_payments
FROM payments p
JOIN orders o ON p.order_id = o.order_id
WHERE 
    (p.payment_status = 'success'  AND p.amount <> o.total_amount)
 OR (p.payment_status = 'failed'   AND p.amount <> 0)
 OR (p.payment_status = 'refunded' AND p.amount <> o.total_amount);


-- =========================================================
-- 4. Shipment Logic Validation
-- =========================================================

-- Delivered and delayed shipments must have delivered_date
SELECT COUNT(*) AS missing_delivery_dates
FROM shipments
WHERE shipment_status IN ('delivered', 'delayed')
  AND delivered_date IS NULL;

-- Shipped and lost orders must not have delivered_date
SELECT COUNT(*) AS invalid_delivery_dates
FROM shipments
WHERE shipment_status IN ('shipped', 'lost')
  AND delivered_date IS NOT NULL;

-- Delivered date must be after shipped date
SELECT COUNT(*) AS invalid_date_sequences
FROM shipments
WHERE delivered_date IS NOT NULL
  AND delivered_date <= shipped_date;


-- =========================================================
-- 5. Returns Integrity Checks
-- =========================================================

-- Returns only for delivered orders
SELECT COUNT(*) AS invalid_return_orders
FROM returns r
JOIN shipments s ON r.order_id = s.order_id
WHERE s.shipment_status <> 'delivered';

-- Return date must be after delivery
SELECT COUNT(*) AS invalid_return_dates
FROM returns r
JOIN shipments s ON r.order_id = s.order_id
WHERE r.return_date <= s.delivered_date;

-- Refund must be positive
SELECT COUNT(*) AS invalid_refund_amounts
FROM returns
WHERE refund_amount <= 0;

-- Refund must not exceed item value
SELECT COUNT(*) AS refund_exceeds_item_value
FROM returns r
JOIN order_items oi 
  ON r.order_id = oi.order_id 
 AND r.product_id = oi.product_id
WHERE r.refund_amount > (oi.quantity * oi.unit_price - oi.discount);


-- =========================================================
-- 6. Session Data Integrity
-- =========================================================

-- Session end must be after session start
SELECT COUNT(*) AS invalid_session_times
FROM sessions
WHERE session_end <= session_start;

-- Pages viewed must be positive
SELECT COUNT(*) AS invalid_pages_viewed
FROM sessions
WHERE pages_viewed <= 0;


-- =========================================================
-- 7. Revenue & Funnel Snapshot (Quick Health Check)
-- =========================================================

SELECT 
    COUNT(*)                         AS total_orders,
    SUM(total_amount)                AS total_revenue,
    AVG(total_amount)                AS avg_order_value
FROM orders;

SELECT 
    COUNT(*) FILTER (WHERE session_converted = TRUE) AS converted_sessions,
    COUNT(*)                                        AS total_sessions,
    ROUND(
        COUNT(*) FILTER (WHERE session_converted = TRUE) * 100.0 / COUNT(*),
        2
    ) AS conversion_rate_percent
FROM sessions;
