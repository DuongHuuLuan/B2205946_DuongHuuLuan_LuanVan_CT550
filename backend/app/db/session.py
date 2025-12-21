# from sqlalchemy import create_engine
# from sqlalchemy.orm import sessionmaker

# from app.core.config import settings

# engine = create_engine(
#     settings.SQLALCHMY_DATABASE_URI,connect_args= {"check_same_thread": False} if settings.SQLALCHMY_DATABASE_URI.startswith("sql") else {}
# )

# SessionLocal = sessionmaker(autocommit = False, autoflush =False, bind = engine)

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import DATABASE_URL

engine = create_engine(DATABASE_URL, echo=True)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)
