from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    supabase_url: str = ""
    supabase_service_key: str = ""
    supabase_db_url: str = ""
    firebase_credentials_path: str = "firebase-service-account.json"
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_phone_number: str = ""
    twilio_whatsapp_number: str = ""
    openai_api_key: str = ""
    reddit_client_id: str = ""
    reddit_client_secret: str = ""
    reddit_user_agent: str = "SafeTourBot/0.1"
    admin_secret: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
