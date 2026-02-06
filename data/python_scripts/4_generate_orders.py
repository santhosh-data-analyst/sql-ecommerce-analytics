from faker import Faker
import psycopg2
import random
from datetime import timedelta

# Database connection
conn = psycopg2.connect(
    dbname="sql_master_project",
    user="postgres",
    password="PASSWORD",   # <-- replace this
    host="localhost",
    port="5432"
)

cursor = conn.cursor()
fake = Faker()

NUM_ORDERS = 2000

# Fetch customers and their signup dates
cursor.execute("SELECT customer_id, signup_date FROM customers;")
customers = cursor.fetchall()

if not customers:
    raise Exception("No customers found. Insert customers before orders.")

print("Starting orders data generation...")

order_statuses = (
    ["delivered"] * 70 +
    ["cancelled"] * 10 +
    ["returned"] * 10 +
    ["shipped"] * 10
)

for _ in range(NUM_ORDERS):
    customer_id, signup_date = random.choice(customers)

    # Order must be after signup
    order_date = fake.date_time_between(start_date=signup_date, end_date='now')
    status = random.choice(order_statuses)

    cursor.execute("""
        INSERT INTO orders
        (customer_id, order_date, order_status, total_amount)
        VALUES (%s, %s, %s, %s)
    """, (
        customer_id,
        order_date,
        status,
        0  # will be updated after order_items insertion
    ))

conn.commit()
cursor.close()
conn.close()

print(f"{NUM_ORDERS} orders inserted successfully.")
