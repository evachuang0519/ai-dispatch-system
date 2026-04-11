from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from dotenv import load_dotenv

load_dotenv()

from services.db_service import get_pool, close_pool
from routers import drivers, vehicles, history, upload, dispatch, reports, vehicle_types


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    yield
    await close_pool()


app = FastAPI(
    title="AI 自動派單系統 API",
    version="1.0.0",
    lifespan=lifespan
)

# CORS：允許 Classic ASP 前端呼叫
origins = os.getenv("CORS_ORIGINS", "http://localhost").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(drivers.router)
app.include_router(vehicles.router)
app.include_router(history.router)
app.include_router(upload.router)
app.include_router(dispatch.router)
app.include_router(reports.router)
app.include_router(vehicle_types.router)


@app.get("/")
async def root():
    return {"message": "AI 自動派單系統 API", "version": "1.0.0"}
