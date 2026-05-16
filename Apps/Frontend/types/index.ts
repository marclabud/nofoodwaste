export interface Ingredient {
  id: string
  name: string
  quantity: number
  unit: "g" | "kg" | "ml" | "l" | "piece"
  expiresAt: string
  createdAt: string
}

export type CreateIngredient = Omit<Ingredient, "id" | "createdAt">

export interface Recipe {
  title: string
  matchScore: number
  foodWastePriorityReason: string
  estimatedTimeMinutes: number
  usedIngredients: string[]
  missingRequiredIngredients: string[]
  optionalIngredients: string[]
  steps: string[]
  explanation: string
}

export interface RecipeResponse {
  recipes: Recipe[]
}
