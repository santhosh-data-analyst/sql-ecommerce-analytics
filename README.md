# SQL E-Commerce Analytics

End-to-end SQL analytics project built on a synthetic e-commerce database — 9 tables, 30+ queries across 8 business modules — answering real revenue, retention, and product questions using PostgreSQL.

---

## Business Problem

An e-commerce business has transactional data spread across customers, orders, products, payments, shipments, and returns — but no structured analytical layer on top of it. This project builds that layer using SQL, producing insights that directly support pricing, retention, and product decisions.

---

## Key Findings

- Total revenue across all orders: **₹5,92,87,107**
- Average Order Value (AOV): **₹29,643.55** per order
- **92.11%** of customers placed more than one order — exceptionally high repeat purchase rate
- Return rate: **6.20%** of orders were returned
- Revenue is evenly distributed across the product catalog — the top product ("Meeting Message") accounts for only **0.89%** of total revenue, indicating no single product dependency
- **494 unique customers** drove the entire revenue base

---

## Dataset

- **Type:** Synthetic — programmatically generated to mimic real transactional systems
- **Schema:** 9 relational tables (see structure below)
- **Validated:** Foreign key integrity, NULL checks, and value range checks in Module 01

> The dataset is synthetic to avoid privacy constraints. The SQL logic, schema design, and analytical reasoning are identical to what would be applied on a real production database.

### Schema — 9 Tables

| Table | Description |
|---|---|
| `customers` | Customer profiles |
| `categories` | Product taxonomy |
| `products` | Catalog with cost and price |
| `orders` | Order headers — 494 unique customers |
| `order_items` | Line items per order |
| `payments` | Payment records |
| `shipments` | Delivery status |
| `returns` | Returned orders (6.20% return rate) |
| `sessions` | Web session data per customer |

**Relationships:** `orders` is the central fact table. Customers place orders (1:many). Each order has multiple `order_items` (1:many). `order_items` references `products`. Each order has one `payment` and one `shipment`. `returns` references specific `order_items`. `sessions` links to `customers`.

---

## Tools & Skills

- **PostgreSQL** — window functions, CTEs, subqueries, aggregations
- **Relational data modeling** — 3NF schema, primary/foreign keys
- **Business KPI design** — AOV, LTV, retention rate, return rate, repeat purchase rate

> **Note:** The repository language badge shows Python because the data generation scripts are Python. All analysis work is SQL (`.sql` files in `/analysis`).

---

## Analysis Modules

| Module | File | Business Domain |
|---|---|---|
| 01 | `01_database_exploration.sql` | Schema validation, sanity checks, NULL audit |
| 02 | `02_customer_analysis.sql` | Customer segmentation, revenue contribution, repeat behavior |
| 03 | `03_sales_analysis.sql` | Revenue, AOV, returns impact |
| 04 | `04_product_analysis.sql` | Product and category performance, margin analysis |
| 05 | `05_retention_analysis.sql` | Cohort retention, churn detection, repeat rate |
| 06 | `06_ranking_analysis.sql` | Top customers and products using RANK(), DENSE_RANK() |
| 07 | `07_trend_analysis.sql` | Month-over-month growth, seasonality, LAG() analysis |
| 08 | `08_performance_metrics.sql` | Executive-level KPI summary |

---

## Sample Query — Month-over-Month Revenue Growth

```sql
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date)      AS month,
        SUM(oi.quantity * oi.unit_price)        AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)          AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100, 2
    )                                            AS mom_growth_pct
FROM monthly
ORDER BY month;
```

---

## Project Structure

```
sql-ecommerce-analytics/
├── schema/
│   └── create_tables.sql
├── data/
│   ├── load_data.sql
│   └── python_scripts/        ← data generation only (not analysis)
├── analysis/
│   ├── 01_database_exploration.sql
│   ├── 02_customer_analysis.sql
│   ├── 03_sales_analysis.sql
│   ├── 04_product_analysis.sql
│   ├── 05_retention_analysis.sql
│   ├── 06_ranking_analysis.sql
│   ├── 07_trend_analysis.sql
│   └── 08_performance_metrics.sql
└── README.md
```

---

## How to Run

1. Install PostgreSQL and create a database: `CREATE DATABASE ecommerce;`
2. Run `schema/create_tables.sql` to build the schema
3. Run `data/load_data.sql` to load the dataset
4. Execute any module in `analysis/` using psql or pgAdmin

---

*Published as part of portfolio — B.E. CSE, Sathyabama University | [LinkedIn](https://www.linkedin.com/in/santhosh-reddy-kallam) | [GitHub](https://github.com/santhosh-data-analyst)*
