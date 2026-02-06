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
cursor.execute("SELECT order_id, order_date FROM orders;")
orders = cursor.fetchall()

if not orders:
    raise Exception("Orders table is empty.")

print("Starting shipments data generation...")

shipment_statuses = (
    ["delivered"] * 70 +
    ["shipped"] * 15 +
    ["delayed"] * 10 +
    ["lost"] * 5
)

carriers = ["BlueDart", "Delhivery", "Ecom Express", "XpressBees"]

for order_id, order_date in orders:
    status = random.choice(shipment_statuses)
    carrier = random.choice(carriers)

    # shipped_date is 1–3 days after order
    shipped_date = fake.date_time_between(
        start_date=order_date + timedelta(days=1),
        end_date=order_date + timedelta(days=3)
    )

    delivered_date = None

    if status == "delivered":
        # normal delivery: 2–5 days after shipping
        delivered_date = fake.date_time_between(
            start_date=shipped_date + timedelta(days=2),
            end_date=shipped_date + timedelta(days=5)
        )
    elif status == "delayed":
        # delayed delivery: 6–12 days after shipping
        delivered_date = fake.date_time_between(
            start_date=shipped_date + timedelta(days=6),
            end_date=shipped_date + timedelta(days=12)
        )
    # shipped → no delivered_date yet
    # lost → no delivered_date

    cursor.execute("""
        INSERT INTO shipments
        (order_id, shipped_date, delivered_date, shipment_status, carrier)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        order_id,
        shipped_date,
        delivered_date,
        status,
        carrier
    ))

conn.commit()
cursor.close()
conn.close()

print(f"{len(orders)} shipments inserted successfully.")
