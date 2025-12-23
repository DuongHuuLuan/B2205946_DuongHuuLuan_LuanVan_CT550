from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from app.api.endpoints import auth
from app.api.endpoints import product
from app.api.endpoints import category
from app.api.endpoints import variant

app = FastAPI(title="Helmet Shop", version="1.0.0")

app.include_router(auth.router)
app.include_router(product.router)
app.include_router(category.router)
app.include_router(variant.router)