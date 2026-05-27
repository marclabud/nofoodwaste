from pydantic import BaseModel, Field
from typing import Literal

class IngredientBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    quantity: float
    unit: Literal["g", "kg", "ml", "l", "piece"]
    expiresAt: str  # YYYY-MM-DD

class IngredientCreate(IngredientBase):
    pass

class Ingredient(IngredientBase):
    id: str
    createdAt: str  # ISO timestamp

class Recipe(BaseModel):
    title: str
    matchScore: float = Field(
        ...,
        description="The match score of the recipe, representing how well the recipe fits the user's available ingredients and food waste priorities. Must be a decimal between 0.0 and 1.0 (e.g., 0.95 for 95%)."
    )
    foodWastePriorityReason: str
    estimatedTimeMinutes: int
    usedIngredients: list[str]
    missingRequiredIngredients: list[str]
    optionalIngredients: list[str]
    steps: list[str]
    explanation: str

class RecipeResponse(BaseModel):
    recipes: list[Recipe]

class GenerateRecipeRequest(BaseModel):
    ingredient_ids: list[str]
