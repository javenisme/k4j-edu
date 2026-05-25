FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Run as root so the app can write to the Railway volume mounted at LAMB_DB_PATH
# (/opt/lamb). Railway mounts volumes owned by root, so a non-root USER would hit
# PermissionError creating the SQLite DB there.

EXPOSE 9099

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "9099", "--forwarded-allow-ips", "*"]
