import pytest
from sqlalchemy import text
from app.core.database import engine

@pytest.mark.asyncio
async def test_tables_exist():
    expected_tables = ["users", "emergency_contacts", "sos_events", "live_sessions", "location_pings"]
    async with engine.begin() as conn:
        result = await conn.execute(text(
            "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
        ))
        existing = [row[0] for row in result]
    for table in expected_tables:
        assert table in existing, f"Table '{table}' not found in database"