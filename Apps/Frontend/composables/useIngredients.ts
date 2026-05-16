import type { Ingredient, CreateIngredient } from '~/types'

export const useIngredients = () => {
  const config = useRuntimeConfig()
  const apiUrl = 'http://localhost:8000' // Hardcoded for MVP, ideally should be config.public.apiBase
  
  const ingredients = useState<Ingredient[]>('ingredients', () => [])
  const loading = useState<boolean>('ingredients-loading', () => false)
  const error = useState<string | null>('ingredients-error', () => null)

  const fetchIngredients = async () => {
    loading.value = true
    error.value = null
    try {
      const response = await $fetch<Ingredient[]>(`${apiUrl}/ingredients`)
      ingredients.value = response
    } catch (e: any) {
      error.value = e.message || 'Failed to fetch ingredients'
    } finally {
      loading.value = false
    }
  }

  const addIngredient = async (ingredient: CreateIngredient) => {
    loading.value = true
    error.value = null
    try {
      const newIngredient = await $fetch<Ingredient>(`${apiUrl}/ingredients`, {
        method: 'POST',
        body: ingredient
      })
      ingredients.value.push(newIngredient)
      // Sort ingredients by expiresAt
      ingredients.value.sort((a, b) => new Date(a.expiresAt).getTime() - new Date(b.expiresAt).getTime())
    } catch (e: any) {
      error.value = e.message || 'Failed to add ingredient'
      throw e
    } finally {
      loading.value = false
    }
  }

  const deleteIngredient = async (id: string) => {
    loading.value = true
    error.value = null
    try {
      await $fetch(`${apiUrl}/ingredients/${id}`, {
        method: 'DELETE'
      })
      ingredients.value = ingredients.value.filter(i => i.id !== id)
    } catch (e: any) {
      error.value = e.message || 'Failed to delete ingredient'
      throw e
    } finally {
      loading.value = false
    }
  }

  const updateIngredient = async (id: string, ingredient: CreateIngredient) => {
    loading.value = true
    error.value = null
    try {
      const updatedIngredient = await $fetch<Ingredient>(`${apiUrl}/ingredients/${id}`, {
        method: 'PUT',
        body: ingredient
      })
      const index = ingredients.value.findIndex(i => i.id === id)
      if (index !== -1) {
        ingredients.value[index] = updatedIngredient
      }
      ingredients.value.sort((a, b) => new Date(a.expiresAt).getTime() - new Date(b.expiresAt).getTime())
    } catch (e: any) {
      error.value = e.message || 'Failed to update ingredient'
      throw e
    } finally {
      loading.value = false
    }
  }

  const getStatus = (expiresAt: string) => {
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    
    const expiryDate = new Date(expiresAt)
    expiryDate.setHours(0, 0, 0, 0)
    
    const timeDiff = expiryDate.getTime() - today.getTime()
    const diffDays = Math.ceil(timeDiff / (1000 * 3600 * 24))

    if (diffDays < 0) return 'expired'
    if (diffDays === 0) return 'expiring_today'
    return 'valid'
  }

  return {
    ingredients,
    loading,
    error,
    fetchIngredients,
    addIngredient,
    updateIngredient,
    deleteIngredient,
    getStatus
  }
}
