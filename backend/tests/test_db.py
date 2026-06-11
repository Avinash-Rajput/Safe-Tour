import pytest
from sqlalchemy import inspect
from app.core.database import engine

@pytest.mark.asyncio
async def test_tables_exist():
    expected_tables = ["users", "emergency_contacts", "sos_events", "live_sessions", "location_pings"]
    async with engine.begin() as conn:
        def get_tables(sync_conn):
            return inspect(sync_conn).get_table_names()
        existing = await conn.run_sync(get_tables)
    for table in expected_tables:
        assert table in existing, f"Table '{table}' not found in database"