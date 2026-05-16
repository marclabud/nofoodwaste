from pydantic import BaseModel, Field
from typing import Literal

class IngredientBase(BaseModel):
    name: str
    quantity: float
    unit: Literal["g", "kg", "ml", "l", "piece"]
    expiresAt: str  # YYYY-MM-DD

class IngredientCreate(IngredientBase):
    pass

class Ingredient(IngredientBase):
    id: str
    createdAt: str  # ISO timestamp
