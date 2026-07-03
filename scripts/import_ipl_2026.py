from database import get_connection


def main():
    try:
        connection = get_connection()

        print("Connected to PostgreSQL successfully!")

        connection.close()

        print("Connection closed successfully!")

    except Exception as e:
        print(e)


if __name__ == "__main__":
    main()