from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.firebase import verify_firebase_token

bearer_scheme = HTTPBearer(auto_error=False)

def get_current_user(
    request: Request,
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> dict:
    auth_header = request.headers.get("Authorization")
    if not credentials:
        print(f"DEBUG AUTH: Credentials None. Header was: {auth_header}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Authorization header missing or invalid. Header: {auth_header}",
        )
    try:
        user = verify_firebase_token(credentials.credentials)
        return user
    except ValueError as e:
        prefix = credentials.credentials[:15] if credentials else "None"
        print(f"DEBUG AUTH: Token verification failed: {e}. Token starts with: {prefix}...")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
