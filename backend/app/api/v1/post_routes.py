from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List

from app.models.post import Post
from app.models.like import Like
from app.models.user import User
from app.schemas.post import PostOut, PostCreate, PostUpdate
from app.core.deps import get_db
from app.services.auth_service import get_current_user

router = APIRouter()


@router.get("/", response_model=List[PostOut])
def get_all_posts(db: Session = Depends(get_db)):
    results = (
        db.query(Post, func.count(Like.id).label("like_count"))
        .outerjoin(Like, Post.id == Like.post_id)
        .group_by(Post.id)
        .all()
    )

    return [
        PostOut(
            id=post.id,
            title=post.title,
            content=post.content,
            created_at=post.created_at,
            author_id=post.author_id,
            like_count=like_count
        )
        for post, like_count in results
    ]


@router.post("/", response_model=PostOut)
def create_post(
    post: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_post = Post(**post.dict(), author_id=current_user.id)
    db.add(new_post)
    db.commit()
    db.refresh(new_post)

    return PostOut(
        id=new_post.id,
        title=new_post.title,
        content=new_post.content,
        created_at=new_post.created_at,
        author_id=new_post.author_id,
        like_count=0
    )


@router.get("/{post_id}", response_model=PostOut)
def get_post(post_id: int, db: Session = Depends(get_db)):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    like_count = db.query(Like).filter(Like.post_id == post_id).count()

    return PostOut(
        id=post.id,
        title=post.title,
        content=post.content,
        created_at=post.created_at,
        author_id=post.author_id,
        like_count=like_count
    )


@router.put("/{post_id}", response_model=PostOut)
def update_post(
    post_id: int,
    updated: PostUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this post")

    post.title = updated.title
    post.content = updated.content
    db.commit()
    db.refresh(post)

    like_count = db.query(Like).filter(Like.post_id == post_id).count()

    return PostOut(
        id=post.id,
        title=post.title,
        content=post.content,
        created_at=post.created_at,
        author_id=post.author_id,
        like_count=like_count
    )


@router.delete("/{post_id}")
def delete_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    if post.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")

    db.delete(post)
    db.commit()
    return {"detail": "Post deleted"}
