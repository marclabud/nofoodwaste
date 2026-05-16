export interface Ingredient {
  id: string
  name: string
  quantity: number
  unit: "g" | "kg" | "ml" | "l" | "piece"
  expiresAt: string
  createdAt: string
}

export type CreateIngredient = Omit<Ingredient, "id" | "createdAt">
