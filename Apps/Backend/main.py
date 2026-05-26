from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os
import uuid
from datetime import datetime, timezone
from typing import List

# Load environment variables from .env
load_dotenv()

from database import get_db_provider
from models import Ingredient, IngredientCreate

# Initialize Database Provider
db_provider = get_db_provider()
db_provider.init_db()

app = FastAPI(
    title="Food-Waste Recipe Finder API",
    description="Backend API for MVP",
    version="1.0.0"
)

# Enable CORS for the Frontend
allowed_origins_str = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000")
allowed_origins = [origin.strip() for origin in allowed_origins_str.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
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
    
    db_provider.create_ingredient(ingredient)
    return ingredient

@app.get("/ingredients", response_model=List[Ingredient])
def get_ingredients():
    return db_provider.get_ingredients()

@app.delete("/ingredients/{ingredient_id}")
def delete_ingredient(ingredient_id: str):
    deleted = db_provider.delete_ingredient(ingredient_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Ingredient not found")
    return {"message": "Ingredient deleted"}

@app.put("/ingredients/{ingredient_id}", response_model=Ingredient)
def update_ingredient(ingredient_id: str, ingredient_in: IngredientCreate):
    # Retrieve the existing ingredient first to preserve its createdAt timestamp
    existing_ingredients = db_provider.get_ingredients_by_ids([ingredient_id])
    if not existing_ingredients:
        raise HTTPException(status_code=404, detail="Ingredient not found")
        
    created_at = existing_ingredients[0].createdAt
    
    return db_provider.update_ingredient(ingredient_id, ingredient_in, created_at)

from agent_service import generate_recipes
from models import RecipeResponse, GenerateRecipeRequest

@app.post("/recipes/generate", response_model=RecipeResponse)
async def generate_recipes_endpoint(request: GenerateRecipeRequest):
    ingredients = db_provider.get_ingredients_by_ids(request.ingredient_ids)
    
    if not ingredients:
        raise HTTPException(status_code=400, detail="No valid ingredients found")
        
    # Filter out expired ingredients just in case frontend sends them
    valid_ingredients = []
    today = datetime.now().strftime("%Y-%m-%d")
    for ing in ingredients:
        if ing.expiresAt >= today:
            # Omit createdAt and id to save tokens
            valid_ingredients.append({
                "name": ing.name,
                "quantity": ing.quantity,
                "unit": ing.unit,
                "expiresAt": ing.expiresAt
            })
            
    if not valid_ingredients:
        raise HTTPException(status_code=400, detail="No non-expired ingredients found")
        
    # Call LLM
    try:
        recipes = await generate_recipes(valid_ingredients)
        return recipes
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM Error: {str(e)}")
