from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional, List

class PostBase(BaseModel):
    title: str
    content: str

class PostCreate(PostBase):
    pass

class PostUpdate(PostBase):
    pass

class PostOut(PostBase):
    id: int
    author_id: int
    created_at: datetime
    like_count: int 

    model_config = ConfigDict(from_attributes=True)