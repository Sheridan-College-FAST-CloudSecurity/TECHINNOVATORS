from pydantic_settings import BaseSettings
from pydantic import ConfigDict

class Settings(BaseSettings):
    APP_NAME: str = "TechInnovators Blog API"
    DEBUG: bool = True
    SQLALCHEMY_DATABASE_URL: str = "sqlite:///./blog.db"
    SECRET_KEY: str = "super-secret-key"
    ALGORITHM: str = "HS256"

    model_config = ConfigDict(env_file=".env", extra="allow")  # ✅ correct way in Pydantic v2

settings = Settings()
