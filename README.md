# SQL E-commerce Analytics

A structured SQL analytics project built on a synthetic e-commerce dataset to answer real business questions around customers, sales, products, retention, trends, and performance metrics.

---

## 📌 Project Objective

To demonstrate:
- Strong **SQL (PostgreSQL)** fundamentals
- Business-oriented analytical thinking
- Clean, explainable queries suitable for interviews
- End-to-end analytics workflow used in real teams

---

## ❓ Business Questions Answered

- How is overall revenue and sales performance?
- Who are the most valuable customers?
- Which products and categories drive the business?
- How strong is customer retention?
- What trends exist over time?
- Which KPIs best summarize business health?

---

## 🗃️ Dataset Overview

- Synthetic e-commerce dataset
- Designed to resemble real transactional systems
- Data validated before analysis

### Core Tables
- `customers`
- `categories`
- `products`
- `orders`
- `order_items`
- `payments`
- `shipments`
- `returns`
- `sessions`

---

## 🛠️ Tools Used

- **PostgreSQL (SQL)**
- Relational data modeling
- Aggregations, joins, subqueries
- Window functions
- Business KPI calculations

---

## 📂 Project Structure

```text
sql-ecommerce-analytics/
├── schema/
│   └── create_tables.sql
│
├── data/
│   ├── load_data.sql
│   └── python_scripts/
│       └── data generation scripts
│
├── analysis/
│   ├── 01_database_exploration.sql
│   ├── 02_customer_analysis.sql
│   ├── 03_sales_analysis.sql
│   ├── 04_product_analysis.sql
│   ├── 05_retention_analysis.sql
│   ├── 06_ranking_analysis.sql
│   ├── 07_trend_analysis.sql
│   └── 08_performance_metrics.sql
│
└── README.md

```

---


## 📊 Analysis Overview


**01. Database Exploration**

- Table coverage and data validation
- Relationship and sanity checks


**02. Customer Analysis**

- Customer activity and order behavior
- Revenue contribution
- Repeat purchase logic and segmentation


**03. Sales Analysis**

- Revenue, orders, and AOV
- Sales distribution and returns impact


**04. Product Analysis**

- Product and category performance
- High and low performing products


**05. Retention Analysis**

- Repeat customers and churn indicators
- Time-based retention patterns


**06. Ranking Analysis**

- Top customers and products
- Ranking using window functions


**07. Trend Analysis**

- Time-series analysis of revenue and orders
- Growth and seasonality patterns


**08. Performance Metrics**

- Business-level KPIs
- Summary metrics suitable for reporting

---

## ✅ Key Takeaways

- Business-first SQL analysis
- Clean and explainable queries
- Realistic analytics workflow
- Interview-ready structure and logic

---
