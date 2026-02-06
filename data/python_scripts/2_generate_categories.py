import psycopg2

conn = psycopg2.connect(
    dbname="sql_master_project",
    user="postgres",
    password="PASSWORD",  # <-- replace this
    host="localhost",
    port="5432"
)

cursor = conn.cursor()

categories = [
    ("Electronics", None),
    ("Mobiles", 1),
    ("Laptops", 1),
    ("Fashion", None),
    ("Men Clothing", 4),
    ("Women Clothing", 4),
    ("Home", None),
    ("Kitchen", 7),
    ("Furniture", 7),
    ("Beauty", None),
    ("Sports", None),
    ("Books", None)
]

for name, parent_id in categories:
    cursor.execute("""
        INSERT INTO categories (category_name, parent_category_id)
        VALUES (%s, %s)
    """, (name, parent_id))

conn.commit()
cursor.close()
conn.close()

print("Categories inserted successfully.")
