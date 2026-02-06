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

# Fetch customers and their signup dates
cursor.execute("SELECT customer_id, signup_date FROM customers;")
customers = cursor.fetchall()

if not customers:
    raise Exception("Customers table is empty.")

print("Starting sessions data generation...")

NUM_SESSIONS = 10000

traffic_sources = (
    ["organic"] * 40 +
    ["ads"] * 30 +
    ["email"] * 20 +
    ["referral"] * 10
)

device_types = (
    ["mobile"] * 55 +
    ["desktop"] * 35 +
    ["tablet"] * 10
)

for _ in range(NUM_SESSIONS):
    customer_id, signup_date = random.choice(customers)

    # Session must be after signup
    session_start = fake.date_time_between(start_date=signup_date, end_date='now')

    # Session duration 1 to 20 minutes
    duration_minutes = random.randint(1, 20)
    session_end = session_start + timedelta(minutes=duration_minutes)

    traffic_source = random.choice(traffic_sources)
    device_type = random.choice(device_types)

    pages_viewed = random.randint(1, 15)

    # Conversion probability ~11%
    session_converted = True if random.random() < 0.11 else False

    cursor.execute("""
        INSERT INTO sessions
        (customer_id, session_start, session_end, traffic_source, device_type, pages_viewed, session_converted)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (
        customer_id,
        session_start,
        session_end,
        traffic_source,
        device_type,
        pages_viewed,
        session_converted
    ))

conn.commit()
cursor.close()
conn.close()

print(f"{NUM_SESSIONS} sessions inserted successfully.")
