<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useIngredients } from '~/composables/useIngredients'
import { useRecipes } from '~/composables/useRecipes'

const { ingredients, loading: ingredientsLoading, error: ingredientsError, fetchIngredients, getStatus } = useIngredients()
const { recipes, loading: recipesLoading, error: recipesError, generateRecipes } = useRecipes()

onMounted(() => {
  fetchIngredients()
})

const validIngredients = computed(() => {
  return ingredients.value.filter(ing => getStatus(ing.expiresAt) !== 'expired')
})

const handleGenerateRecipes = () => {
  const ids = validIngredients.value.map(i => i.id)
  if (ids.length > 0) {
    generateRecipes(ids)
  }
}
</script>

<template>
  <div class="min-h-screen bg-background text-text font-sans pb-16">
    <main class="container mx-auto p-4 max-w-lg">
      <header class="mb-8 mt-6">
        <h1 class="text-4xl font-extrabold text-text text-center tracking-tight mb-1">NoFoodWaste</h1>
        <p class="text-muted text-center text-sm font-medium">Dein intelligenter Küchenassistent</p>
      </header>

      <section class="mb-10">
        <h2 class="text-xl font-bold text-text mb-4">Meine Lebensmittel</h2>
        
        <div v-if="ingredientsLoading && ingredients.length === 0" class="text-muted py-6 text-center text-sm">
          Lade Lebensmittel...
        </div>
        
        <div v-else-if="ingredientsError" class="bg-primary/10 border border-primary/20 text-primary p-4 rounded-xl mb-4 text-sm">
          {{ ingredientsError }}
        </div>
        
        <div v-else class="flex flex-col gap-3 mb-6">
          <IngredientCard 
            v-for="item in ingredients" 
            :key="item.id" 
            :ingredient="item" 
          />
          <div v-if="ingredients.length === 0" class="text-center py-8 text-sm text-muted bg-white border border-dashed border-border/60 rounded-2xl shadow-sm">
            Keine Lebensmittel vorhanden. Füge welche hinzu!
          </div>
        </div>

        <IngredientForm />
      </section>

      <section class="mb-8">
        <h2 class="text-xl font-bold text-text mb-4">Rezeptvorschläge</h2>
        
        <div class="mb-6">
          <button 
            @click="handleGenerateRecipes" 
            :disabled="recipesLoading || validIngredients.length === 0"
            class="w-full bg-primary hover:bg-primary/95 text-white font-semibold py-3.5 px-4 rounded-xl shadow-sm transition-all duration-200 disabled:opacity-40 disabled:shadow-none flex justify-center items-center gap-2 cursor-pointer"
          >
            <span v-if="recipesLoading" class="flex items-center gap-2 justify-center">
              <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generiere Rezepte...
            </span>
            <span v-else class="flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
              Ideen finden ({{ validIngredients.length }} Zutaten)
            </span>
          </button>
        </div>

        <div v-if="recipesError" class="bg-primary/10 border border-primary/20 text-primary p-4 rounded-xl mb-4 text-sm">
          {{ recipesError }}
        </div>

        <RecipeList v-if="recipes.length > 0" :recipes="recipes" />
      </section>
    </main>
  </div>
</template>
