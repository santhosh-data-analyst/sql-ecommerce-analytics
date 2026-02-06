import psycopg2
import random
from faker import Faker
from datetime import timedelta
from decimal import Decimal

fake = Faker()

conn = psycopg2.connect(
    dbname="sql_master_project",
    user="postgres",
    password="PASSWORD",   # <-- replace this
    host="localhost",
    port="5432"
)

cursor = conn.cursor()

# Fetch delivered orders with their delivery date
cursor.execute("""
    SELECT o.order_id, s.delivered_date
    FROM orders o
    JOIN shipments s ON o.order_id = s.order_id
    WHERE s.shipment_status = 'delivered'
""")
delivered_orders = cursor.fetchall()

if not delivered_orders:
    raise Exception("No delivered orders found.")

# Fetch order items with financials
cursor.execute("""
    SELECT oi.order_id, oi.product_id,
           oi.quantity, oi.unit_price, oi.discount
    FROM order_items oi
""")
order_items = cursor.fetchall()

# Organize order_items by order_id
order_items_dict = {}
for order_id, product_id, qty, price, discount in order_items:
    order_items_dict.setdefault(order_id, []).append(
        (product_id, qty, price, discount)
    )

return_reasons = [
    "Damaged product",
    "Wrong item delivered",
    "Size issue",
    "Quality not as expected",
    "Late delivery",
    "Changed mind"
]

print("Starting returns data generation...")

total_returns = 0

for order_id, delivered_date in delivered_orders:
    # 10% chance that a delivered order has a return
    if random.random() < 0.10:
        items = order_items_dict.get(order_id)
        if not items:
            continue

        # Choose one product from the order to return
        product_id, qty, price, discount = random.choice(items)

        # Refund should be less than or equal to item's net value
        item_total = (price * Decimal(qty)) - discount
        refund_amount = (item_total * Decimal(str(random.uniform(0.6, 1.0)))).quantize(Decimal("0.01"))

        return_date = fake.date_time_between(
            start_date=delivered_date + timedelta(days=1),
            end_date=delivered_date + timedelta(days=7)
        )

        reason = random.choice(return_reasons)

        cursor.execute("""
            INSERT INTO returns
            (order_id, product_id, return_date, return_reason, refund_amount)
            VALUES (%s, %s, %s, %s, %s)
        """, (
            order_id,
            product_id,
            return_date,
            reason,
            refund_amount
        ))

        total_returns += 1

conn.commit()
cursor.close()
conn.close()

print(f"{total_returns} returns inserted successfully.")
