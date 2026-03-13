from fastapi import FastAPI
import app.core.cloudinary
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from app.api.endpoints import auth
from app.api.endpoints import user
from app.api.endpoints import product
from app.api.endpoints import category
from app.api.endpoints import product_detail
from app.api.endpoints import cart
from app.api.endpoints import order
from app.api.endpoints import delivery
from app.api.endpoints import payment
from app.api.endpoints import evaluate
from app.api.endpoints import distributor
from app.api.endpoints import warehouse
from app.api.endpoints import receipt
from app.api.endpoints import image_url
from app.api.endpoints import discount
from app.api.endpoints import vnpay
from app.api.endpoints import ghn
from app.api.endpoints import dashboard
from app.api.endpoints import statistics
from app.api.endpoints import profile
from app.api.endpoints import chat
from app.api.endpoints import push_notification
from app.api.endpoints import sticker
from app.api.endpoints import design

app = FastAPI(title="Helmet Shop", version="1.0.0")

STATIC_DIR = Path(__file__).resolve().parent.parent / "static"
app.mount("/static", StaticFiles(directory=str(STATIC_DIR), check_dir=False), name="static")
app.include_router(auth.router)
app.include_router(user.router)
app.include_router(product.router)
app.include_router(category.router)
app.include_router(product_detail.router)
app.include_router(cart.router)
app.include_router(order.router)
app.include_router(delivery.router)
app.include_router(payment.router)
app.include_router(evaluate.router)
app.include_router(distributor.router)
app.include_router(warehouse.router)
app.include_router(receipt.router)
app.include_router(image_url.router)
app.include_router(discount.router)
app.include_router(vnpay.router)
app.include_router(ghn.router)
app.include_router(dashboard.router)
app.include_router(statistics.router)
app.include_router(profile.router)
app.include_router(chat.router)
app.include_router(push_notification.router)
app.include_router(sticker.router)
app.include_router(design.router)

from fastapi.middleware.cors import CORSMiddleware


app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
