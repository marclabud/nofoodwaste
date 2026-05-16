from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os
import uuid
from datetime import datetime, timezone
from typing import List

from database import init_db, get_db
from models import Ingredient, IngredientCreate

# Load environment variables from .env
load_dotenv()

# Initialize Database
init_db()

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

@app.post("/ingredients", response_model=Ingredient)
def create_ingredient(ingredient_in: IngredientCreate):
    ingredient_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()
    
    ingredient = Ingredient(
        id=ingredient_id,
        createdAt=created_at,
        **ingredient_in.model_dump()
    )
    
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute(
            '''
            INSERT INTO ingredients (id, name, quantity, unit, expiresAt, createdAt)
            VALUES (?, ?, ?, ?, ?, ?)
            ''',
            (ingredient.id, ingredient.name, ingredient.quantity, ingredient.unit, ingredient.expiresAt, ingredient.createdAt)
        )
        conn.commit()
        
    return ingredient

@app.get("/ingredients", response_model=List[Ingredient])
def get_ingredients():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM ingredients ORDER BY expiresAt ASC')
        rows = cursor.fetchall()
        
    return [Ingredient(**dict(row)) for row in rows]

@app.delete("/ingredients/{ingredient_id}")
def delete_ingredient(ingredient_id: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute('DELETE FROM ingredients WHERE id = ?', (ingredient_id,))
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Ingredient not found")
        conn.commit()
        
    return {"message": "Ingredient deleted"}

# Future endpoints according to MVP specs:
# POST /recipes/generate
