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

    # JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "default_secret_key_if_not_found")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", 30))


    #cloudirary
    CLOUDINARY_CLOUD_NAME: str = os.getenv("CLOUDINARY_CLOUD_NAME")
    CLOUDINARY_API_KEY: str = os.getenv("CLOUDINARY_API_KEY")
    CLOUDINARY_API_SECRET: str = os.getenv("CLOUDINARY_API_SECRET")

    # VNPAY
    VNPAY_TMN_CODE: str = os.getenv("VNPAY_TMN_CODE", "")
    VNPAY_HASH_SECRET: str = os.getenv("VNPAY_HASH_SECRET", "")
    VNPAY_URL: str = os.getenv("VNPAY_URL", "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html")
    VNPAY_RETURN_URL: str = os.getenv("VNPAY_RETURN_URL", "")
    VNPAY_VERSION: str = os.getenv("VNPAY_VERSION", "2.1.0")

    # GHN
    GHN_API_BASE: str = os.getenv("GHN_API_BASE", "https://dev-online-gateway.ghn.vn")
    GHN_TOKEN: str = os.getenv("GHN_TOKEN", "")
    GHN_SHOP_ID: str = os.getenv("GHN_SHOP_ID", "")
    GHN_FROM_NAME: str = os.getenv("GHN_FROM_NAME", "")
    GHN_FROM_PHONE: str = os.getenv("GHN_FROM_PHONE", "")
    GHN_FROM_ADDRESS: str = os.getenv("GHN_FROM_ADDRESS", "")
    GHN_FROM_WARD_CODE: str = os.getenv("GHN_FROM_WARD_CODE", "")
    GHN_FROM_DISTRICT_ID: int = int(os.getenv("GHN_FROM_DISTRICT_ID", 0))
    GHN_DEFAULT_WEIGHT: int = int(os.getenv("GHN_DEFAULT_WEIGHT", 1000))
    GHN_DEFAULT_LENGTH: int = int(os.getenv("GHN_DEFAULT_LENGTH", 20))
    GHN_DEFAULT_WIDTH: int = int(os.getenv("GHN_DEFAULT_WIDTH", 20))
    GHN_DEFAULT_HEIGHT: int = int(os.getenv("GHN_DEFAULT_HEIGHT", 20))
    GHN_PAYMENT_TYPE_ID: int = int(os.getenv("GHN_PAYMENT_TYPE_ID", 2))
    GHN_REQUIRED_NOTE: str = os.getenv("GHN_REQUIRED_NOTE", "KHONGCHOXEMHANG")
    
settings = Settings()
