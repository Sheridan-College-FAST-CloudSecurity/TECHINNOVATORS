from app.core.db import engine, Base
from app.models import user, post, comment, like  # Import all models so they're registered with Base
from app.core.seed import seed_data
from app.core.deps import get_db

def init():
    print("creating DB tables...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
  
    print("Seeding sample data...")
    db = next(get_db())
    try:
        seed_data(db)
    finally:
        db.close()

if __name__ == "__main__":
    init()
