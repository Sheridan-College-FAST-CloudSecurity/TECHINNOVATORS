from fastapi import FastAPI, Request
from fastapi.openapi.utils import get_openapi
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.responses import HTMLResponse
from app.api.v1.blog_routes import router as blog_router
from app.api.v1.auth_routes import router as auth_router
from app.api.v1.comment_routes import router as comment_router
from app.api.v1.like_routes import router as like_router
from app.api.v1.post_routes import router as post_router
from app.models import user, post, comment, like # Add this line

from app.core.config import settings
from fastapi.responses import Response
from app.core.db import SessionLocal, Base, engine # Add Base and engine
from app.core.seed import seed_data          # the function you already wrote

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("--- Application startup: Initializing database ---")
    try:
        # Attempt to drop all tables first for a clean slate in development
        # This is aggressive and good for fresh deployments / re-deployments
        Base.metadata.drop_all(bind=engine)
        print("Existing database tables dropped (if any).")
    except Exception as e:
        # Log if dropping fails, but don't stop startup if it's just due to non-existent DB/tables
        print(f"WARNING: Could not drop existing database tables (may not exist, or connection issue): {e}")

    try:
        # Create all tables (must ensure models are imported as done above)
        Base.metadata.create_all(bind=engine, checkfirst=True)
        print("Database tables created.")
    except Exception as e:
        print(f"ERROR: Failed to create database tables: {e}")
        # This is a critical error, so we re-raise it
        raise

    db = SessionLocal() # Get a new session after tables are created
    try:
        # Seed data only if the database is newly created/empty
        print("Seeding sample data...")
        seed_data(db) # Your seed_data function already handles checking if user exists
        print("✔ Seed data inserted (or already existed).")
    except Exception as e:
        print(f"WARNING: Could not seed data (may already exist or other error): {e}")
    finally:
        db.close() # Always close the session

    yield # Application is now ready to handle requests

    print("--- Application shutdown: Closing resources ---")


app = FastAPI(
    title="TechInnovators Blog API",
    version="1.0.0",
    description="Backend API for the TechInnovators blogging platform.",
    lifespan=lifespan
)


# Allow your front-end origin (e.g. http://127.0.0.1:8080). 
# If you want to allow any origin during development, you can use ["*"].

#origins = [
#    "https://turbo-space-computing-machine-j9vq5qw9g672pp66-8080.app.github.dev", "https://bug-free-guide-5grxpggpxj5537wrw-8080.app.github.dev", "https://psychic-waffle-5gr4jq74vjq7hvgqj-8080.app.github.dev"
#]
#app.add_middleware(
#    CORSMiddleware,
#    allow_origins=origins,
#    allow_credentials=True,
#    allow_methods=["*"],
#    allow_headers=["*"],
#)

app.add_middleware(
    CORSMiddleware,
    allow_origins = ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



# Optional: Customize Swagger/OpenAPI to show the correct password flow
def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title="TechInnovators Blog API",
        version="1.0.0",
        description="API for TechInnovators blogging platform",
        routes=app.routes,
    )
    openapi_schema["components"]["securitySchemes"] = {
        "OAuth2Password": {
            "type": "oauth2",
            "flows": {
                "password": {
                    "tokenUrl": "/api/v1/login",
                    "scopes": {}
                }
            }
        }
    }
    for path in openapi_schema["paths"].values():
        for method in path.values():
            method["security"] = [{"OAuth2Password": []}]
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi



#@app.options("/{path:path}")
#async def handle_options(request: Request):
#    headers = {
#        "Access-Control-Allow-Origin": "https://turbo-space-computing-machine-j9vq5qw9g672pp66-8080.app.github.dev",
#        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
#        "Access-Control-Allow-Headers": "Authorization, Content-Type",
#        "Access-Control-Allow-Credentials": "true",
#    }
#    return Response(status_code=200, headers=headers)


# Register v1 routes
app.include_router(blog_router, prefix="/api/v1")
app.include_router(auth_router, prefix="/api/v1")
app.include_router(comment_router, prefix="/api/v1/comments", tags=["Comments"])
app.include_router(like_router, prefix="/api/v1/likes", tags=["Likes"])
app.include_router(post_router, prefix="/api/v1/posts", tags=["Posts"])


@app.get("/ping", tags=["Health"])
def ping():
    return {"status": "ok"}


# Serve static files from the 'frontend/public' directory relative to /app
# This makes FastAPI directly serve your HTML, CSS, JS, etc.
app.mount("/", StaticFiles(directory="frontend/public", html=True), name="static")
