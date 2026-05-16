from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Load environment variables from .env
load_dotenv()

app = FastAPI(
    title="Food-Waste Recipe Finder API",
    description="Backend API for MVP",
    version="1.0.0"
)

# Enable CORS for the Frontend (Nuxt)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "FastAPI server is running!"}

# Future endpoints according to MVP specs:
# POST /ingredients
# GET /ingredients
# DELETE /ingredients/:id
# POST /recipes/generate
