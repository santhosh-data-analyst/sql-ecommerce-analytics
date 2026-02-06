import psycopg2
import random
from decimal import Decimal

conn = psycopg2.connect(
    dbname="sql_master_project",
    user="postgres",
    password="PASSWORD",   # <-- replace this
    host="localhost",
    port="5432"
)

cursor = conn.cursor()

cursor.execute("SELECT order_id FROM orders;")
orders = [row[0] for row in cursor.fetchall()]

cursor.execute("SELECT product_id, price FROM products WHERE is_active = TRUE;")
products = cursor.fetchall()

if not orders or not products:
    raise Exception("Orders or Products table is empty.")

print("Starting order_items generation...")

total_items = 0

for order_id in orders:
    num_items = random.randint(1, 5)
    chosen_products = random.sample(products, num_items)

    for product_id, price in chosen_products:
        quantity = random.randint(1, 4)

        if random.random() < 0.3:
            discount_rate = Decimal(str(random.uniform(0.05, 0.2)))
            discount = (price * Decimal(quantity) * discount_rate).quantize(Decimal("0.01"))
        else:
            discount = Decimal("0.00")

        cursor.execute("""
            INSERT INTO order_items
            (order_id, product_id, quantity, unit_price, discount)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            order_id,
            product_id,
            quantity,
            price,
            discount
        ))

        total_items += 1

conn.commit()
cursor.close()
conn.close()

print(f"{total_items} order_items inserted successfully.")
