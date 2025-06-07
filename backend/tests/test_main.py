# tests/test_main.py
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_signup():
    response = client.post("/api/v1/signup", json={
        "username": "testuser",
        "email": "testuser@example.com",
        "password": "testpass"

    })
    assert response.status_code in (200, 400)

def test_login():
    response = client.post("/api/v1/login", data={
        "username": "testuser",
        "password": "testpass"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_create_post():
    login = client.post("/api/v1/login", data={
        "username": "testuser",
        "password": "testpass"
    })
    token = login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    response = client.post("/api/v1/posts/", json={
        "title": "Test Post",
        "content": "This is a test post"
    }, headers=headers)

    assert response.status_code == 200
    assert response.json()["title"] == "Test Post"

def test_get_posts():
    response = client.get("/api/v1/posts/")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_add_comment():
    login = client.post("/api/v1/login", data={
        "username": "testuser",
        "password": "testpass"
    })
    token = login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    posts = client.get("/api/v1/posts/").json()
    if posts:
        post_id = posts[0]["id"]
        response = client.post("/api/v1/comments/", json={
            "post_id": post_id,
            "content": "Great post!"
        }, headers=headers)
        assert response.status_code == 200
