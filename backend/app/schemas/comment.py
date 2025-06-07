from pydantic import BaseModel, ConfigDict
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

    model_config = ConfigDict(from_attributes=True)
