from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.schemas.user_schema import UserCreate, UserRead
from app.schemas.post import PostCreate, PostUpdate, PostOut
from app.models.post import Post
from app.services.user_service import create_user
from app.core.deps import get_db
from app.services.user_service import create_user, get_all_users
from app.services.auth_service import get_current_user
from app.core.db import SessionLocal
from app.models.user import User
from typing import List



router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/hello", tags=["Demo"])
def hello():
    return {"message": "Welcome to TechInnovators API v1"}

@router.post("/users", response_model=UserRead, tags=["Users"])
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    return create_user(db, user)

# Already inside router
@router.get("/users", response_model=list[UserRead], tags=["Users"])
def list_users(db: Session = Depends(get_db)):
    return get_all_users(db)
