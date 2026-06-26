from sqlalchemy import create_engine

USERNAME = "postgres"
PASSWORD = "***REMOVED***"
HOST = "localhost"
PORT = "5432"
DATABASE = "growth_lab"

engine = create_engine(
    f"postgresql+psycopg2://{USERNAME}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}"
)

if __name__ == "__main__":
    try:
        connection = engine.connect()
        print("Connected to growth_lab")
        connection.close()

    except Exception as e:
        print("Connection Failed")
        print(e)