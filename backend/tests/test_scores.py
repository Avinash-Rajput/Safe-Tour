import json
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock

from main import app

client = TestClient(app)

sample_data = {
    "city": "bangalore",
    "generated_at": "2026-05-16T00:00:00Z",
    "day": {
        "koramangala": {"score": 74, "band": "safe", "reasons": ["2 theft reports in last 30 days", "High commercial activity"]}
    },
    "night": {
        "koramangala": {"score": 61, "band": "moderate", "reasons": ["Active nightlife", "Reduced police presence after midnight"]}
    }
}

@pytest.fixture
def mock_supabase():
    with patch("app.api.scores.get_supabase") as mock_get_supabase:
        mock_client = MagicMock()
        mock_storage = MagicMock()
        mock_from = MagicMock()
        mock_from.download.return_value = json.dumps(sample_data).encode("utf-8")
        
        mock_storage.from_.return_value = mock_from
        mock_client.storage = mock_storage
        mock_get_supabase.return_value = mock_client
        
        yield mock_get_supabase

def test_get_city_scores_success(mock_supabase):
    response = client.get("/api/scores/bangalore")
    assert response.status_code == 200
    data = response.json()
    assert "day" in data
    assert "night" in data
    assert data["city"] == "bangalore"
    assert "Cache-Control" in response.headers
    assert response.headers["Cache-Control"] == "public, max-age=3600"

def test_get_city_scores_not_supported():
    response = client.get("/api/scores/mumbai")
    assert response.status_code == 404
    assert response.json()["detail"] == "mumbai is not supported yet"

def test_get_zone_score_success(mock_supabase):
    response = client.get("/api/scores/bangalore/zone/koramangala")
    assert response.status_code == 200
    data = response.json()
    assert data["zone_id"] == "koramangala"
    assert data["city"] == "bangalore"
    assert data["day"]["score"] == 74
    assert data["night"]["score"] == 61

def test_get_zone_score_not_found(mock_supabase):
    response = client.get("/api/scores/bangalore/zone/invalid_zone")
    assert response.status_code == 404
    assert response.json()["detail"] == "Zone invalid_zone not found"
