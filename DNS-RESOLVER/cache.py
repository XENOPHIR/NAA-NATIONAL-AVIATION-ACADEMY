import pymysql
import time

def get_connection():
    return pymysql.connect(
        host="localhost",
        port=3306,
        user="root",
        password="4444",
        database="dns_cache_db",
        cursorclass=pymysql.cursors.DictCursor
    )

def get_from_cache(domain, ttl=60):
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM dns_cache WHERE domain = %s", (domain,))
        row = cursor.fetchone()
    conn.close()

    if row and time.time() - row["timestamp"] < ttl:
        return row["ip_address"]
    return None

def save_to_cache(domain, ip):
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute(
            "REPLACE INTO dns_cache (domain, ip_address, timestamp) VALUES (%s, %s, %s)",
            (domain, ip, int(time.time()))
        )
    conn.commit()
    conn.close()
