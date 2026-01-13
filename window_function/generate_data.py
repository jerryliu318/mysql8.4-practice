import random
from datetime import datetime, timedelta

# Configuration
NUM_RECORDS = 1000
NUM_USERS = 10
START_DATE = datetime(2026, 1, 1)
END_DATE = datetime(2026, 2, 1)

CATEGORIES = {
    'Electronics': ['Wireless Mouse', 'Mechanical Keyboard', 'USB-C Hub', 'Monitor', 'HDMI Cable', 'Webcam', 'Laptop Stand', 'Power Bank'],
    'Clothing': ['T-Shirt', 'Jeans', 'Sneakers', 'Jacket', 'Hat', 'Socks', 'Scarf', 'Gloves'],
    'Books': ['SQL Guide', 'Python Cookbook', 'Data Science Manual', 'Novel', 'Magazine', 'Biography', 'Sci-Fi', 'History Book'],
    'Home': ['Coffee Mug', 'Desk Lamp', 'Smart Plug', 'Pillow', 'Blanket', 'Picture Frame', 'Clock', 'Plant Pot']
}

def random_date(start, end):
    delta = end - start
    int_delta = (delta.days * 24 * 60 * 60) + delta.seconds
    random_second = random.randrange(int_delta)
    return start + timedelta(seconds=random_second)

def generate_sql():
    sql = [
        "USE shop;",
        "DROP TABLE IF EXISTS order_items;",
        "CREATE TABLE order_items (",
        "    id INT AUTO_INCREMENT PRIMARY KEY,",
        "    user_id INT NOT NULL,",
        "    category VARCHAR(50),",
        "    item_name VARCHAR(100),",
        "    price DECIMAL(10, 2),",
        "    pay_date DATETIME",
        ");",
        "",
        "INSERT INTO order_items (user_id, category, item_name, price, pay_date) VALUES"
    ]

    values = []
    for _ in range(NUM_RECORDS):
        user_id = random.randint(101, 100 + NUM_USERS)
        category = random.choice(list(CATEGORIES.keys()))
        item_name = random.choice(CATEGORIES[category])
        price = round(random.uniform(5.0, 200.0), 2)
        pay_date = random_date(START_DATE, END_DATE).strftime('%Y-%m-%d %H:%M:%S')
        
        values.append(f"({user_id}, '{category}', '{item_name}', {price}, '{pay_date}')")

    sql.append(",\n".join(values) + ";")
    
    return "\n".join(sql)

if __name__ == "__main__":
    with open("init.sql", "w") as f:
        f.write(generate_sql())
    print("Generated init.sql with 1000 records.")
