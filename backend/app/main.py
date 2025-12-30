from fastapi import FastAPI
import app.core.cloudinary
from fastapi.staticfiles import StaticFiles
from app.api.endpoints import auth
from app.api.endpoints import product
from app.api.endpoints import category
from app.api.endpoints import variant
from app.api.endpoints import cart
from app.api.endpoints import order
from app.api.endpoints import delivery
from app.api.endpoints import payment
from app.api.endpoints import evaluate
from app.api.endpoints import distributor
from app.api.endpoints import warehouse
from app.api.endpoints import receipt

app = FastAPI(title="Helmet Shop", version="1.0.0")

app.include_router(auth.router)
app.include_router(product.router)
app.include_router(category.router)
app.include_router(variant.router)
app.include_router(cart.router)
app.include_router(order.router)
app.include_router(delivery.router)
app.include_router(payment.router)
app.include_router(evaluate.router)
app.include_router(distributor.router)
app.include_router(warehouse.router)
app.include_router(receipt.router)