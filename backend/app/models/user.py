from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from app.core.db import Base  # DO NOT redefine Base
from sqlalchemy.orm import relationship
from app.models.post import Post

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    posts = relationship("Post", back_populates="author", foreign_keys="[Post.author_id]")
    comments = relationship("Comment", back_populates="author", foreign_keys="[Comment.author_id]")
    likes = relationship("Like", back_populates="user", cascade="all, delete-orphan")
