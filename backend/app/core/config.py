# from pydantic import BaseModel

# class Settings(BaseModel):
#     PROJECT_NAME: str ="Ung dung cua hang non bao hiem"

#     SQLALCHMY_DATABASE_URI: str = "sql:///./app.db"

# settings = Settings()
import os
from urllib.parse import quote_plus
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()

raw_password = os.getenv('DB_PASSWORD')
encoded_password = quote_plus(raw_password) if raw_password else ""

class Settings(BaseSettings):
    DATABASE_URL: str = (
        f"mysql+pymysql://{os.getenv('DB_USER')}:"
        f"{encoded_password}@"
        f"{os.getenv('DB_HOST')}:"
        f"{os.getenv('DB_PORT')}/"
        f"{os.getenv('DB_NAME')}"
    )

    SECRET_KEY: str = os.getenv("SECRET_KEY", "default_secret_key_if_not_found")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))

settings = Settings()