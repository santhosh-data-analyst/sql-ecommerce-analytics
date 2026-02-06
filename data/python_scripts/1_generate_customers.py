from faker import Faker
import psycopg2
import random

# ----------------------------
# DATABASE CONNECTION
# ----------------------------
conn = psycopg2.connect(
    dbname="sql_master_project",
    user="postgres",
    password="PASSWORD",   # <-- replace this
    host="localhost",
    port="5432"
)

cursor = conn.cursor()
fake = Faker()

NUM_CUSTOMERS = 500

print("Starting customer data generation...")

for _ in range(NUM_CUSTOMERS):
    first_name = fake.first_name()
    last_name = fake.last_name()
    email = fake.unique.email()
    gender = random.choice(['M', 'F'])
    dob = fake.date_of_birth(minimum_age=18, maximum_age=60)
    city = fake.city()
    state = fake.state()
    country = "India"
    signup_date = fake.date_time_between(start_date='-2y', end_date='now')
    is_active = random.choice([True, True, True, False])

    cursor.execute("""
        INSERT INTO customers 
        (first_name, last_name, email, gender, date_of_birth, city, state, country, signup_date, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (
        first_name, last_name, email, gender, dob,
        city, state, country, signup_date, is_active
    ))

conn.commit()
cursor.close()
conn.close()

print(f"{NUM_CUSTOMERS} customers inserted successfully.")
