from supabase import create_client
from app.core.config import settings
import os

def seed():
    supabase_url = settings.supabase_url
    supabase_key = settings.supabase_service_key
    
    if not supabase_url or not supabase_key:
        print("Error: Supabase credentials not found. Please set SUPABASE_URL and SUPABASE_SERVICE_KEY.")
        return

    client = create_client(supabase_url, supabase_key)
    
    # Define the file path correctly based on the script location
    data_file = os.path.join(os.path.dirname(__file__), "data", "sample_scores.json")
    
    with open(data_file, "r") as f:
        data = f.read()
        
    result = client.storage.from_("region-scores").upload(
        "bangalore/latest.json",
        data.encode('utf-8'),
        {"upsert": "true"}
    )
    print("Seeded scores to Supabase storage")
    print(result)

if __name__ == "__main__":
    seed()
