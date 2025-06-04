from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.deps import get_db
from app.core.db import Base
import os

# Use file-based DB to avoid thread issues
SQLALCHEMY_TEST_DB_URL = "sqlite:///./test.db"
engine = create_engine(SQLALCHEMY_TEST_DB_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)

# Wipe old test.db if exists
if os.path.exists("test.db"):
    os.remove("test.db")

# Create tables for the test DB
Base.metadata.create_all(bind=engine)

# Override DB dependency
def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)

def test_create_and_get_user():
    response = client.post("/api/v1/users", json={
        "username": "testuser",
        "email": "test@example.com",
        "password": "securepass123"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["username"] == "testuser"
    assert data["email"] == "test@example.com"

    response = client.get("/api/v1/users")
    assert response.status_code == 200
    users = response.json()
    assert any(u["email"] == "test@example.com" for u in users)
