# Use an official Python runtime as a parent image
FROM python:3.9-slim-bullseye

# Install system dependencies required by psycopg2-binary (for PostgreSQL)
# and build-essential for compiling some Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container to /app
# All subsequent commands will run relative to this directory
WORKDIR /app

# Copy backend requirements file first to leverage Docker caching
COPY backend/requirements.txt ./backend/
RUN pip install --no-cache-dir -r ./backend/requirements.txt

# Copy the entire backend application directory
COPY backend/ ./backend/

# Copy the entire frontend/public directory
COPY frontend/public/ ./frontend/public/

# Expose port 8000 (where Gunicorn/FastAPI will listen)
EXPOSE 8000

# Set environment variables for the application (will be overridden by systemd service)
# These are default values if not explicitly set via docker run -e
ENV SQLALCHEMY_DATABASE_URL="postgresql://user:password@host:port/db"
ENV SECRET_KEY="default-secret-key-for-dev"

ENV PYTHONPATH=/app
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "-b", "0.0.0.0:8000", "backend.app.main:app"]