from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
import re
from pydantic import BaseModel, Field, field_validator
from datetime import datetime

from app.core.database import get_db
from app.models.models import User, EmergencyContact
from app.api.deps import get_current_user

router = APIRouter()

# --- Pydantic Schemas ---

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1)
    photo_url: str | None = None
    city: str = "bangalore"

class UserUpdate(BaseModel):
    name: str = Field(..., min_length=1)
    photo_url: str | None = None
    city: str = "bangalore"

class UserResponse(BaseModel):
    id: str
    firebase_uid: str
    name: str
    photo_url: str | None = None
    city: str
    created_at: datetime

    class Config:
        from_attributes = True

class ContactCreate(BaseModel):
    name: str = Field(..., min_length=1)
    phone_number: str

    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r"^\+91[6-9]\d{9}$", v):
            raise ValueError("Invalid phone number. Must match pattern: ^+91[6-9] followed by 9 digits")
        return v

class ContactResponse(BaseModel):
    id: str
    user_id: str
    name: str
    phone_number: str

    class Config:
        from_attributes = True

# --- Helpers/Dependencies ---

async def get_db_user(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    firebase_uid = current_user.get("uid")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token payload",
        )
    
    stmt = select(User).where(User.firebase_uid == firebase_uid)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user

# --- Endpoints ---

@router.post("/users/me", response_model=UserResponse)
async def get_or_create_user(
    payload: UserCreate,
    response: Response,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    firebase_uid = current_user.get("uid")
    if not firebase_uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token payload",
        )
    
    # Check if user already exists
    stmt = select(User).where(User.firebase_uid == firebase_uid)
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()
    
    if user:
        response.status_code = status.HTTP_200_OK
        return user
    
    # Create new user
    new_user = User(
        firebase_uid=firebase_uid,
        name=payload.name,
        photo_url=payload.photo_url,
        city=payload.city
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    response.status_code = status.HTTP_201_CREATED
    return new_user

@router.get("/users/me", response_model=UserResponse)
async def get_user_profile(user: User = Depends(get_db_user)):
    return user

@router.put("/users/me", response_model=UserResponse)
async def update_user_profile(
    payload: UserUpdate,
    user: User = Depends(get_db_user),
    db: AsyncSession = Depends(get_db)
):
    user.name = payload.name
    user.photo_url = payload.photo_url
    user.city = payload.city
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user

@router.post("/users/me/contacts", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
async def add_emergency_contact(
    payload: ContactCreate,
    user: User = Depends(get_db_user),
    db: AsyncSession = Depends(get_db)
):
    # Max 5 contacts per user
    stmt = select(func.count(EmergencyContact.id)).where(EmergencyContact.user_id == user.id)
    count_result = await db.execute(stmt)
    contact_count = count_result.scalar_one()
    
    if contact_count >= 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum of 5 emergency contacts exceeded",
        )
        
    new_contact = EmergencyContact(
        user_id=user.id,
        name=payload.name,
        phone_number=payload.phone_number
    )
    db.add(new_contact)
    await db.commit()
    await db.refresh(new_contact)
    return new_contact

@router.get("/users/me/contacts", response_model=list[ContactResponse])
async def get_emergency_contacts(
    user: User = Depends(get_db_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(EmergencyContact).where(EmergencyContact.user_id == user.id)
    result = await db.execute(stmt)
    contacts = result.scalars().all()
    return contacts

@router.delete("/users/me/contacts/{contact_id}")
async def delete_emergency_contact(
    contact_id: str,
    user: User = Depends(get_db_user),
    db: AsyncSession = Depends(get_db)
):
    stmt = select(EmergencyContact).where(EmergencyContact.id == contact_id)
    result = await db.execute(stmt)
    contact = result.scalar_one_or_none()
    
    if not contact or contact.user_id != user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Contact not found",
        )
        
    await db.delete(contact)
    await db.commit()
    return {"detail": "Contact deleted successfully"}
