<script setup lang="ts">
import type { Recipe } from '~/types'

const props = defineProps<{
  recipe: Recipe
}>()
</script>

<template>
  <div class="bg-surface border border-border/30 rounded-xl overflow-hidden flex flex-col shadow-sm">
    <div class="p-4 border-b border-border/20 bg-primary/5">
      <h3 class="text-xl font-bold text-text mb-2">{{ recipe.title }}</h3>
      
      <div class="flex flex-wrap gap-2 text-sm text-muted mb-3">
        <span class="flex items-center gap-1">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-primary"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          {{ recipe.estimatedTimeMinutes }} Min
        </span>
        <span class="flex items-center gap-1">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-primary"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
          {{ Math.round(recipe.matchScore * 100) }}% Match
        </span>
      </div>

      <div v-if="recipe.foodWastePriorityReason" class="bg-orange/10 border border-orange/30 text-orange-700 p-2 rounded text-sm flex items-start gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mt-0.5 shrink-0"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
        <span>{{ recipe.foodWastePriorityReason }}</span>
      </div>
    </div>

    <div class="p-4 flex-1">
      <div class="mb-4">
        <h4 class="font-semibold text-text mb-1 flex justify-between items-center text-sm">
          Verwendet 
          <span class="text-xs text-muted font-normal bg-background px-1.5 rounded">{{ recipe.usedIngredients.length }}</span>
        </h4>
        <ul class="text-sm text-muted list-disc list-inside">
          <li v-for="ing in recipe.usedIngredients" :key="ing">{{ ing }}</li>
        </ul>
      </div>

      <div v-if="recipe.missingRequiredIngredients?.length" class="mb-4">
        <h4 class="font-semibold text-text mb-1 text-sm">Fehlt noch:</h4>
        <ul class="text-sm text-muted list-disc list-inside">
          <li v-for="ing in recipe.missingRequiredIngredients" :key="ing">{{ ing }}</li>
        </ul>
      </div>

      <div v-if="recipe.optionalIngredients?.length" class="mb-4">
        <h4 class="font-semibold text-text mb-1 text-sm opacity-80">Optional:</h4>
        <ul class="text-sm text-muted list-disc list-inside opacity-80">
          <li v-for="ing in recipe.optionalIngredients" :key="ing">{{ ing }}</li>
        </ul>
      </div>

      <div>
        <h4 class="font-semibold text-text mb-2 text-sm border-t border-border/20 pt-3">Zubereitung</h4>
        <ol class="text-sm text-muted list-decimal list-inside space-y-1.5">
          <li v-for="(step, idx) in recipe.steps" :key="idx" class="pl-1">{{ step }}</li>
        </ol>
      </div>
      
      <div class="mt-4 pt-3 border-t border-border/20">
        <p class="text-xs text-muted italic">{{ recipe.explanation }}</p>
      </div>
    </div>

    <div class="p-4 border-t border-border/20 bg-background/50">
      <button class="w-full bg-primary text-white font-semibold py-2 px-4 rounded hover:bg-primary/90 transition-colors shadow-sm">
        Jetzt kochen
      </button>
    </div>
  </div>
</template>
