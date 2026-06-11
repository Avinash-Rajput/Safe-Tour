from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.firebase import init_firebase
from app.api.users import router as users_router
from app.api.scores import router as scores_router
from app.core.database import engine
from sqlalchemy import text

app = FastAPI(title="SafeTour API", version="0.0.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

firebase_initialized = False

@app.on_event("startup")
async def startup_event():
    global firebase_initialized
    try:
        init_firebase()
        firebase_initialized = True
    except Exception as e:
        print(f"Warning: Firebase not initialized — {e}")

app.include_router(users_router, prefix="/api")
app.include_router(scores_router)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "safetour-backend"}

@app.get("/health/deep")
async def deep_health_check():
    db_status = "disconnected"
    try:
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        db_status = "connected"
    except Exception:
        pass
    return {
        "status": "ok",
        "database": db_status,
        "firebase": "initialized" if firebase_initialized else "not initialized"
    }