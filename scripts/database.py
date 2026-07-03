import psycopg2


def get_connection():
    return psycopg2.connect(
        host="localhost",
        port=5432,
        database="ipl_analytics",
        user="postgres",
        password="YOUR_PASSWORD"
    )