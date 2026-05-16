from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.firebase import init_firebase

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

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "safetour-backend"}
