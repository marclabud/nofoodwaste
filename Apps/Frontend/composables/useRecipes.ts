import type { Recipe } from '~/types'

export const useRecipes = () => {
  const config = useRuntimeConfig()
  const apiUrl = 'http://localhost:8000'
  
  const recipes = useState<Recipe[]>('recipes', () => [])
  const loading = useState<boolean>('recipes-loading', () => false)
  const error = useState<string | null>('recipes-error', () => null)

  const generateRecipes = async (ingredientIds: string[]) => {
    loading.value = true
    error.value = null
    recipes.value = []
    
    try {
      const response = await $fetch<{ recipes: Recipe[] }>(`${apiUrl}/recipes/generate`, {
        method: 'POST',
        body: { ingredient_ids: ingredientIds }
      })
      
      if (response && response.recipes) {
        recipes.value = response.recipes
      }
    } catch (e: any) {
      error.value = e.message || 'Fehler beim Generieren der Rezepte'
    } finally {
      loading.value = false
    }
  }

  const clearRecipes = () => {
    recipes.value = []
    error.value = null
  }

  return {
    recipes,
    loading,
    error,
    generateRecipes,
    clearRecipes
  }
}
