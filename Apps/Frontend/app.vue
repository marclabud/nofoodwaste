<script setup lang="ts">
import { onMounted } from 'vue'
import { useIngredients } from '~/composables/useIngredients'

const { ingredients, loading, error, fetchIngredients } = useIngredients()

onMounted(() => {
  fetchIngredients()
})
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
        
        <div v-if="loading && ingredients.length === 0" class="text-muted py-4 text-center">
          Lade Lebensmittel...
        </div>
        
        <div v-else-if="error" class="bg-primary/20 text-primary p-4 rounded mb-4">
          {{ error }}
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
    </main>
  </div>
</template>
