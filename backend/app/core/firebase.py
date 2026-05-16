import firebase_admin
from firebase_admin import credentials, auth
from app.core.config import settings
import os

_firebase_initialized = False

def init_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return
    try:
        cred_path = settings.firebase_credentials_path
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            firebase_admin.initialize_app()
        _firebase_initialized = True
    except Exception as e:
        print(f"Firebase init warning: {e}")
        _firebase_initialized = True

def verify_firebase_token(token: str) -> dict:
    try:
        decoded = auth.verify_id_token(token)
        return decoded
    except Exception as e:
        raise ValueError(f"Invalid token: {e}")
