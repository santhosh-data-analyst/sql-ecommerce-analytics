from faker import Faker
import psycopg2
import random

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

NUM_PRODUCTS = 500

# Fetch category IDs from DB
cursor.execute("SELECT category_id FROM categories;")
category_ids = [row[0] for row in cursor.fetchall()]

if not category_ids:
    raise Exception("No categories found. Insert categories before products.")

print("Starting product data generation...")

for _ in range(NUM_PRODUCTS):
    product_name = fake.word().capitalize() + " " + fake.word().capitalize()
    category_id = random.choice(category_ids)

    cost = round(random.uniform(100, 5000), 2)
    price = round(cost * random.uniform(1.2, 1.8), 2)  # profit margin
    is_active = random.choice([True, True, True, False])  # mostly active
    created_at = fake.date_time_between(start_date='-2y', end_date='now')

    cursor.execute("""
        INSERT INTO products
        (product_name, category_id, price, cost, is_active, created_at)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (
        product_name,
        category_id,
        price,
        cost,
        is_active,
        created_at
    ))

conn.commit()
cursor.close()
conn.close()

print(f"{NUM_PRODUCTS} products inserted successfully.")
