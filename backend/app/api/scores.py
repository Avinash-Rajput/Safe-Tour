from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from supabase import create_client
from app.core.config import settings
import json

router = APIRouter(prefix="/api/scores", tags=["scores"])
SUPPORTED_CITIES = ["bangalore"]

def get_supabase():
    return create_client(settings.supabase_url, settings.supabase_service_key)

@router.get("/{city}")
def get_city_scores(city: str):
    if city not in SUPPORTED_CITIES:
        raise HTTPException(status_code=404, detail=f"{city} is not supported yet")
    try:
        client = get_supabase()
        response = client.storage.from_("region-scores").download(f"{city}/latest.json")
        scores = json.loads(response)
        return JSONResponse(
            content=scores,
            headers={"Cache-Control": "public, max-age=3600"}
        )
    except Exception:
        raise HTTPException(status_code=503, detail="Scores temporarily unavailable")

@router.get("/{city}/zone/{zone_id}")
def get_zone_score(city: str, zone_id: str):
    if city not in SUPPORTED_CITIES:
        raise HTTPException(status_code=404, detail=f"{city} is not supported yet")
    try:
        client = get_supabase()
        response = client.storage.from_("region-scores").download(f"{city}/latest.json")
        scores = json.loads(response)
        day_score = scores.get("day", {}).get(zone_id)
        night_score = scores.get("night", {}).get(zone_id)
        if not day_score:
            raise HTTPException(status_code=404, detail=f"Zone {zone_id} not found")
        return {
            "zone_id": zone_id,
            "city": city,
            "day": day_score,
            "night": night_score,
            "generated_at": scores.get("generated_at")
        }
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=503, detail="Scores temporarily unavailable")
