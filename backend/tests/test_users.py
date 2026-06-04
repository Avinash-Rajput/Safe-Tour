import pytest
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.future import select
from sqlalchemy.pool import StaticPool

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import app
from app.core.database import Base, get_db
from app.api.deps import get_current_user
from app.models.models import User, EmergencyContact

# --- Test Database Setup ---

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    poolclass=StaticPool,
    connect_args={"check_same_thread": False}
)
TestAsyncSessionLocal = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)

async def override_get_db():
    async with TestAsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

# --- Mock Authentication ---

# Global mutable state to control the current authenticated user's details
mock_auth_state = {
    "uid": "test_firebase_uid",
    "email": "test@example.com"
}

async def override_get_current_user():
    return mock_auth_state

# Apply dependency overrides
app.dependency_overrides[get_db] = override_get_db
app.dependency_overrides[get_current_user] = override_get_current_user

client = TestClient(app)

@pytest.fixture
def anyio_backend():
    return "asyncio"

@pytest.fixture(autouse=True)
async def setup_db():
    # Setup: Create all tables in the clean in-memory database
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Reset mock auth state before each test
    mock_auth_state["uid"] = "test_firebase_uid"
    mock_auth_state["email"] = "test@example.com"
    
    yield
    
    # Teardown: Clean up the database
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

# --- Test Cases ---

@pytest.mark.anyio
async def test_post_users_me_create():
    # Attempt to retrieve/create the profile when user doesn't exist yet
    response = client.post("/api/users/me", json={
        "name": "Avinash",
        "photo_url": "http://example.com/photo.jpg",
        "city": "bangalore"
    })
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Avinash"
    assert data["photo_url"] == "http://example.com/photo.jpg"
    assert data["city"] == "bangalore"
    assert data["firebase_uid"] == "test_firebase_uid"
    assert "id" in data
    assert "created_at" in data

    # Verify directly in the DB
    async with TestAsyncSessionLocal() as session:
        stmt = select(User).where(User.firebase_uid == "test_firebase_uid")
        result = await session.execute(stmt)
        user = result.scalar_one_or_none()
        assert user is not None
        assert user.name == "Avinash"

@pytest.mark.anyio
async def test_post_users_me_exists():
    # Create the user first
    response = client.post("/api/users/me", json={
        "name": "Avinash",
        "photo_url": "http://example.com/photo.jpg",
        "city": "bangalore"
    })
    assert response.status_code == 201
    
    # POST again with same UID
    response2 = client.post("/api/users/me", json={
        "name": "Avinash New Name",  # Even with different body, should return existing record
        "photo_url": "http://example.com/photo2.jpg",
        "city": "mumbai"
    })
    assert response2.status_code == 200
    data = response2.json()
    assert data["name"] == "Avinash"  # Returned the existing user name
    assert data["city"] == "bangalore"

@pytest.mark.anyio
async def test_get_users_me_not_found():
    # User is not in DB yet
    response = client.get("/api/users/me")
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found"

@pytest.mark.anyio
async def test_get_users_me_success():
    # Create the user
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # GET user profile
    response = client.get("/api/users/me")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Avinash"
    assert data["city"] == "bangalore"

@pytest.mark.anyio
async def test_put_users_me_success():
    # Create the user
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # PUT updated profile
    response = client.put("/api/users/me", json={
        "name": "Avinash Updated",
        "photo_url": "http://example.com/new.jpg",
        "city": "mumbai"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Avinash Updated"
    assert data["photo_url"] == "http://example.com/new.jpg"
    assert data["city"] == "mumbai"

@pytest.mark.anyio
async def test_put_users_me_not_found():
    response = client.put("/api/users/me", json={
        "name": "Avinash",
        "city": "bangalore"
    })
    assert response.status_code == 404
    assert response.json()["detail"] == "User not found"

@pytest.mark.anyio
async def test_post_contacts_success():
    # Create user first
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # Add emergency contact
    response = client.post("/api/users/me/contacts", json={
        "name": "Mom",
        "phone_number": "+919876543210"
    })
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Mom"
    assert data["phone_number"] == "+919876543210"
    assert "id" in data
    assert "user_id" in data

@pytest.mark.anyio
async def test_post_contacts_invalid_phone():
    # Create user
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # Invalid starting digit (starts with 5)
    response = client.post("/api/users/me/contacts", json={
        "name": "Dad",
        "phone_number": "+915876543210"
    })
    assert response.status_code == 422
    
    # Invalid length (too short)
    response = client.post("/api/users/me/contacts", json={
        "name": "Dad",
        "phone_number": "+9188765"
    })
    assert response.status_code == 422

    # Missing +91
    response = client.post("/api/users/me/contacts", json={
        "name": "Dad",
        "phone_number": "9876543210"
    })
    assert response.status_code == 422

@pytest.mark.anyio
async def test_post_contacts_limit_exceeded():
    # Create user
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # Add 5 contacts
    for i in range(5):
        response = client.post("/api/users/me/contacts", json={
            "name": f"Contact {i}",
            "phone_number": f"+91987654321{i}"
        })
        assert response.status_code == 201
        
    # Attempt to add the 6th contact
    response = client.post("/api/users/me/contacts", json={
        "name": "Contact 6",
        "phone_number": "+919876543219"
    })
    assert response.status_code == 400
    assert response.json()["detail"] == "Maximum of 5 emergency contacts exceeded"

@pytest.mark.anyio
async def test_get_contacts_list():
    # Create user
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # Add 2 contacts
    client.post("/api/users/me/contacts", json={"name": "Contact A", "phone_number": "+919876543210"})
    client.post("/api/users/me/contacts", json={"name": "Contact B", "phone_number": "+919876543211"})
    
    # GET contacts
    response = client.get("/api/users/me/contacts")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert {c["name"] for c in data} == {"Contact A", "Contact B"}

@pytest.mark.anyio
async def test_delete_contact_success():
    # Create user
    client.post("/api/users/me", json={"name": "Avinash"})
    
    # Add contact
    contact_res = client.post("/api/users/me/contacts", json={"name": "Contact A", "phone_number": "+919876543210"}).json()
    contact_id = contact_res["id"]
    
    # Delete contact
    response = client.delete(f"/api/users/me/contacts/{contact_id}")
    assert response.status_code == 200
    assert response.json() == {"detail": "Contact deleted successfully"}
    
    # Verify in DB it's gone
    async with TestAsyncSessionLocal() as session:
        stmt = select(EmergencyContact).where(EmergencyContact.id == contact_id)
        result = await session.execute(stmt)
        assert result.scalar_one_or_none() is None

@pytest.mark.anyio
async def test_delete_contact_not_owned_or_not_found():
    # User A creates a profile and a contact
    mock_auth_state["uid"] = "user_a"
    client.post("/api/users/me", json={"name": "User A"})
    contact_res = client.post("/api/users/me/contacts", json={"name": "Contact A", "phone_number": "+919876543210"}).json()
    contact_id = contact_res["id"]
    
    # Switch to User B
    mock_auth_state["uid"] = "user_b"
    client.post("/api/users/me", json={"name": "User B"})
    
    # User B tries to delete User A's contact
    response = client.delete(f"/api/users/me/contacts/{contact_id}")
    assert response.status_code == 404
    assert response.json()["detail"] == "Contact not found"

    # User B tries to delete a completely non-existent contact ID
    response2 = client.delete("/api/users/me/contacts/non-existent-id")
    assert response2.status_code == 404
    assert response2.json()["detail"] == "Contact not found"
