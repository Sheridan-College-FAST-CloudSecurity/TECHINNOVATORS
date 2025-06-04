from pydantic import BaseModel
from datetime import datetime

class CommentBase(BaseModel):
    content: str

class CommentCreate(CommentBase):
    post_id: int

class CommentResponse(CommentBase):
    id: int
    post_id: int
    author_id: int  # ✅ Renamed to match model
    created_at: datetime

    class Config:
        orm_mode = True
