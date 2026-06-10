import asyncio
from app.core.database import engine, Base
from app.models.models import User, EmergencyContact, SosEvent, LiveSession, LocationPing
from sqlalchemy import text

async def create_all():
    async with engine.begin() as conn:
        print("Creating all tables...")
        await conn.run_sync(Base.metadata.create_all)
        print("Tables created successfully")

        print("Creating indexes...")
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_location_pings_session ON location_pings(session_id, pinged_at)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_sos_events_user ON sos_events(user_id, triggered_at)"))
        await conn.execute(text("CREATE INDEX IF NOT EXISTS idx_contacts_user ON emergency_contacts(user_id)"))
        print("Indexes created successfully")

if __name__ == "__main__":
    asyncio.run(create_all())