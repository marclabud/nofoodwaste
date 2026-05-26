FROM python:3.13-slim

WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DB_PATH=/app/data/food_waste.db

# Create directory for persistent SQLite database
RUN mkdir -p /app/data

# Copy requirements file first for layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source code
COPY main.py database.py models.py llm_service.py agent_service.py ./
COPY prompts/ ./prompts/

# Expose FastAPI port
EXPOSE 8000

# Run Uvicorn production server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
