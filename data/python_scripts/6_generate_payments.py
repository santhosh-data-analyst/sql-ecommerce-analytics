import psycopg2
import random
from faker import Faker
from datetime import timedelta

fake = Faker()

conn = psycopg2.connect(
    dbname="sql_master_project",
    user="postgres",
    password="PASSWORD",   # <-- replace this
    host="localhost",
    port="5432"
)

cursor = conn.cursor()

# Fetch orders
cursor.execute("SELECT order_id, order_date, total_amount FROM orders;")
orders = cursor.fetchall()

if not orders:
    raise Exception("Orders table is empty.")

print("Starting payments data generation...")

payment_methods = (
    ["card"] * 40 +
    ["UPI"] * 30 +
    ["wallet"] * 20 +
    ["COD"] * 10
)

payment_statuses = (
    ["success"] * 85 +
    ["failed"] * 10 +
    ["refunded"] * 5
)

for order_id, order_date, total_amount in orders:
    payment_date = fake.date_time_between(start_date=order_date, end_date=order_date + timedelta(days=2))
    method = random.choice(payment_methods)
    status = random.choice(payment_statuses)

    if status == "success":
        amount = total_amount
    elif status == "failed":
        amount = 0
    else:  # refunded
        amount = total_amount

    cursor.execute("""
        INSERT INTO payments
        (order_id, payment_date, payment_method, payment_status, amount)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        order_id,
        payment_date,
        method,
        status,
        amount
    ))

conn.commit()
cursor.close()
conn.close()

print(f"{len(orders)} payments inserted successfully.")
