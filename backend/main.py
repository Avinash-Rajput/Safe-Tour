from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.firebase import init_firebase
from app.api.users import router as users_router
from app.api.scores import router as scores_router

app = FastAPI(title="SafeTour API", version="0.0.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    init_firebase()

app.include_router(users_router, prefix="/api")
app.include_router(scores_router)

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "safetour-backend"}

