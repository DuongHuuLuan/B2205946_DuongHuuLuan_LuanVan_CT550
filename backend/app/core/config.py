# from pydantic import BaseModel

# class Settings(BaseModel):
#     PROJECT_NAME: str ="Ung dung cua hang non bao hiem"

#     SQLALCHMY_DATABASE_URI: str = "sql:///./app.db"

# settings = Settings()
import os
from urllib.parse import quote_plus
from dotenv import load_dotenv

load_dotenv()

raw_password = os.getenv('DB_PASSWORD')
encoded_password = quote_plus(raw_password) if raw_password else ""

DATABASE_URL = (
    f"mysql+pymysql://{os.getenv('DB_USER')}:"
    f"{encoded_password}@"
    f"{os.getenv('DB_HOST')}:"
    f"{os.getenv('DB_PORT')}/"
    f"{os.getenv('DB_NAME')}"
)