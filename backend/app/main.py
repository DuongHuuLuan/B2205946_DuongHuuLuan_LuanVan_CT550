from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="Ung dung ban non bao hiem", version="1.0.0")

@app.get("/") #127.0.0.1:8000
def read_root():
    return {"status: OK "}
