from pydantic import BaseModel
from datetime import datetime

class PostRead(BaseModel):
    id: int
    title: str
    content: str
    created_at: datetime

    class Config:
        from_attributes = True
