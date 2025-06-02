# app/core/seed.py
# ----------------
from datetime import datetime, timedelta
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.post import Post
from app.models.comment import Comment
from app.core.security import get_password_hash

def seed_data(db: Session) -> None:
    # ---------- 1) Seed user ----------
    user = db.query(User).filter_by(username="testuser").first()
    if not user:
        user = User(
            username="testuser",
            email="test@example.com",
            password=get_password_hash("testpass"),
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # ---------- 2) Seed posts ----------
    titles = [
        "Welcome to BlogSphere!",
        "AI Trends to Watch in 2025",
        "Building a FastAPI Backend",
        "TailwindCSS Tips & Tricks",
        "Understanding Blockchain 101",
        "DevOps for Beginners",
        "Serverless: Hype or Future?",
    ]

    for i, title in enumerate(titles, start=1):
        post = db.query(Post).filter_by(title=title).first()
        if not post:
            post = Post(
                title=title,
                content=f"This is demo post #{i}.",
                author_id=user.id,
                created_at=datetime.utcnow() - timedelta(days=i),
            )
            db.add(post)
            db.commit()
            db.refresh(post)

            # ---------- 3) Optional: seed 2 comments on each post ----------
            for n in range(1, 3):
                comment = Comment(
                    content=f"Demo comment {n} on “{title}”.",
                    author_id=user.id,
                    post_id=post.id,
                    created_at=datetime.utcnow(),
                )
                db.add(comment)
            db.commit()

    print("✔ Seed data inserted")
