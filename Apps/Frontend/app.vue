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
  <div class="min-h-screen bg-background text-text font-sans pb-12">
    <main class="container mx-auto p-4 max-w-lg">
      <header class="mb-8 mt-4">
        <h1 class="text-3xl font-bold text-primary mb-2">Food-Waste MVP</h1>
        <p class="text-muted text-sm">Verwalte deine Lebensmittel und finde Rezepte.</p>
      </header>

      <section class="mb-8">
        <h2 class="text-2xl font-bold mb-4 border-b border-border/20 pb-2">Meine Lebensmittel</h2>
        
        <div v-if="ingredientsLoading && ingredients.length === 0" class="text-muted py-4 text-center">
          Lade Lebensmittel...
        </div>
        
        <div v-else-if="ingredientsError" class="bg-primary/20 text-primary p-4 rounded mb-4">
          {{ ingredientsError }}
        </div>
        
        <div v-else class="flex flex-col gap-3 mb-6">
          <IngredientCard 
            v-for="item in ingredients" 
            :key="item.id" 
            :ingredient="item" 
          />
          <div v-if="ingredients.length === 0" class="text-center py-6 text-muted border border-dashed border-border/30 rounded-lg">
            Keine Lebensmittel vorhanden. Füge welche hinzu!
          </div>
        </div>

        <IngredientForm />
      </section>

      <section class="mb-8">
        <h2 class="text-2xl font-bold mb-4 border-b border-border/20 pb-2">Rezeptvorschläge finden</h2>
        
        <div class="mb-6">
          <button 
            @click="handleGenerateRecipes" 
            :disabled="recipesLoading || validIngredients.length === 0"
            class="w-full bg-text text-white font-semibold py-3 px-4 rounded-lg hover:bg-text/90 transition-colors disabled:opacity-50 flex justify-center items-center gap-2"
          >
            <span v-if="recipesLoading">Generiere Rezepte...</span>
            <span v-else>Ideen finden ({{ validIngredients.length }} Zutaten)</span>
          </button>
        </div>

        <div v-if="recipesError" class="bg-primary/20 text-primary p-4 rounded mb-4">
          {{ recipesError }}
        </div>

        <RecipeList v-if="recipes.length > 0" :recipes="recipes" />
      </section>
    </main>
  </div>
</template>
