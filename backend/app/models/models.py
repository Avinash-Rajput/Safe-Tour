from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base
import uuid

def gen_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    firebase_uid = Column(String, unique=True, nullable=False, index=True)
    name = Column(String, nullable=False)
    photo_url = Column(String, nullable=True)
    city = Column(String, default="bangalore")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    contacts = relationship("EmergencyContact", back_populates="user")
    sos_events = relationship("SosEvent", back_populates="user")
    live_sessions = relationship("LiveSession", back_populates="user")

class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    phone_number = Column(String, nullable=False)

    user = relationship("User", back_populates="contacts")

class SosEvent(Base):
    __tablename__ = "sos_events"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    triggered_at = Column(DateTime(timezone=True), server_default=func.now())
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)

    user = relationship("User", back_populates="sos_events")
    pings = relationship("LocationPing", back_populates="sos_event")

class LiveSession(Base):
    __tablename__ = "live_sessions"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    session_token = Column(String, unique=True, default=gen_uuid)
    started_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)
    is_active = Column(Boolean, default=True)

    user = relationship("User", back_populates="live_sessions")
    pings = relationship("LocationPing", back_populates="live_session")

class LocationPing(Base):
    __tablename__ = "location_pings"

    id = Column(String, primary_key=True, default=gen_uuid)
    session_id = Column(String, ForeignKey("live_sessions.id"), nullable=True)
    sos_event_id = Column(String, ForeignKey("sos_events.id"), nullable=True)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    battery_pct = Column(Integer, nullable=True)
    pinged_at = Column(DateTime(timezone=True), server_default=func.now())

    live_session = relationship("LiveSession", back_populates="pings")
    sos_event = relationship("SosEvent", back_populates="pings")
