from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.deps import get_db
from app.models.like import Like
from app.schemas.like import LikeCreate, LikeResponse

router = APIRouter()

@router.post("/", response_model=LikeResponse)
def like_post(like_data: LikeCreate, db: Session = Depends(get_db)):
    existing_like = db.query(Like).filter_by(user_id=like_data.user_id, post_id=like_data.post_id).first()
    if existing_like:
        raise HTTPException(status_code=400, detail="Already liked")
    new_like = Like(**like_data.dict())
    db.add(new_like)
    db.commit()
    db.refresh(new_like)
    return new_like

@router.delete("/", response_model=dict)
def unlike_post(like_data: LikeCreate, db: Session = Depends(get_db)):
    like = db.query(Like).filter_by(user_id=like_data.user_id, post_id=like_data.post_id).first()
    if not like:
        raise HTTPException(status_code=404, detail="Like not found")
    db.delete(like)
    db.commit()
    return {"message": "Unliked successfully"}
