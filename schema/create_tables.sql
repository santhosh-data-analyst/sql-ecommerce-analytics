/*
===========================================================
File: create_tables.sql
Project: E-commerce Customer & Revenue Analysis
Purpose:
    This script defines the complete database schema for the
    e-commerce analytics warehouse.

    It contains all core entities required to analyze:
    - Customers
    - Products & Categories
    - Orders & Revenue
    - Payments
    - Shipments
    - Returns
    - User Sessions (Behavioral Analytics)

Design Principles:
    - Fully normalized schema
    - Financial accuracy using NUMERIC data types
    - Referential integrity via foreign keys
    - Analytics-friendly column naming
===========================================================
*/

-- =========================================================
-- Customers Table
-- Stores master data for all registered customers.
-- =========================================================
CREATE TABLE customers (
    customer_id      SERIAL PRIMARY KEY,
    first_name       VARCHAR(50),
    last_name        VARCHAR(50),
    email            VARCHAR(100) UNIQUE,
    gender           CHAR(1),
    date_of_birth    DATE,
    city             VARCHAR(50),
    state            VARCHAR(50),
    country          VARCHAR(50),
    signup_date      TIMESTAMP,
    is_active        BOOLEAN DEFAULT TRUE
);

-- =========================================================
-- Categories Table
-- Supports hierarchical product categorization.
-- parent_category_id allows category nesting.
-- =========================================================
CREATE TABLE categories (
    category_id         SERIAL PRIMARY KEY,
    category_name       VARCHAR(100),
    parent_category_id  INT REFERENCES categories(category_id)
);

-- =========================================================
-- Products Table
-- Stores all sellable products with pricing and cost data.
-- price > cost is enforced logically by data generation.
-- =========================================================
CREATE TABLE products (
    product_id    SERIAL PRIMARY KEY,
    product_name  VARCHAR(150),
    category_id   INT REFERENCES categories(category_id),
    price         NUMERIC(10,2),
    cost          NUMERIC(10,2),
    is_active     BOOLEAN,
    created_at    TIMESTAMP
);

-- =========================================================
-- Orders Table
-- Represents the order header.
-- total_amount is calculated from order_items.
-- =========================================================
CREATE TABLE orders (
    order_id      SERIAL PRIMARY KEY,
    customer_id   INT REFERENCES customers(customer_id),
    order_date    TIMESTAMP,
    order_status  VARCHAR(20),
    total_amount  NUMERIC(12,2)
);

-- =========================================================
-- Order Items Table
-- Line-level transactional data.
-- Revenue is derived from this table.
-- =========================================================
CREATE TABLE order_items (
    order_item_id  SERIAL PRIMARY KEY,
    order_id       INT REFERENCES orders(order_id),
    product_id     INT REFERENCES products(product_id),
    quantity       INT,
    unit_price     NUMERIC(10,2),
    discount       NUMERIC(10,2) DEFAULT 0
);

-- =========================================================
-- Payments Table
-- Tracks payment status and cash collection.
-- Allows analysis of failed and refunded transactions.
-- =========================================================
CREATE TABLE payments (
    payment_id      SERIAL PRIMARY KEY,
    order_id        INT REFERENCES orders(order_id),
    payment_date    TIMESTAMP,
    payment_method  VARCHAR(30),
    payment_status  VARCHAR(20),
    amount          NUMERIC(12,2)
);

-- =========================================================
-- Shipments Table
-- Enables delivery performance and logistics analysis.
-- =========================================================
CREATE TABLE shipments (
    shipment_id     SERIAL PRIMARY KEY,
    order_id        INT REFERENCES orders(order_id),
    shipped_date    TIMESTAMP,
    delivered_date  TIMESTAMP,
    shipment_status VARCHAR(20),
    carrier         VARCHAR(50)
);

-- =========================================================
-- Returns Table
-- Tracks product-level returns and refund leakage.
-- =========================================================
CREATE TABLE returns (
    return_id      SERIAL PRIMARY KEY,
    order_id       INT REFERENCES orders(order_id),
    product_id     INT REFERENCES products(product_id),
    return_date    TIMESTAMP,
    return_reason  VARCHAR(100),
    refund_amount  NUMERIC(10,2)
);

-- =========================================================
-- Sessions Table
-- Behavioral data for funnel and conversion analysis.
-- =========================================================
CREATE TABLE sessions (
    session_id        SERIAL PRIMARY KEY,
    customer_id       INT REFERENCES customers(customer_id),
    session_start     TIMESTAMP,
    session_end       TIMESTAMP,
    traffic_source    VARCHAR(50),
    device_type       VARCHAR(20),
    pages_viewed      INT,
    session_converted BOOLEAN
);
