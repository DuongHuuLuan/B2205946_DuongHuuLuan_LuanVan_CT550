from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.api.endpoints import auth

app = FastAPI(title="Helmet Shop", version="1.0.0")

app.include_router(auth.router, prefix="/auth", tags=["Authentication"])