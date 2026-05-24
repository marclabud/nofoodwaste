<script setup lang="ts">
import type { Recipe } from '~/types'

const props = defineProps<{
  recipe: Recipe
}>()
</script>

<template>
  <div class="bg-white border border-border/40 rounded-2xl overflow-hidden flex flex-col shadow-[0_2px_12px_rgba(0,0,0,0.03)] hover:shadow-[0_4px_24px_rgba(0,0,0,0.06)] transition-all duration-200">
    <div class="p-5 border-b border-border/20 bg-white">
      <h3 class="text-xl font-bold text-text mb-3 leading-tight">{{ recipe.title }}</h3>
      
      <div class="flex items-center gap-3 text-sm text-muted mb-2">
        <span class="flex items-center gap-1 px-3 py-1 rounded-full text-xs font-semibold bg-secondary/10 text-secondary">
          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
          {{ Math.round(recipe.matchScore * 100) }}% Match
        </span>
        <span class="flex items-center gap-1 font-semibold text-xs">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="opacity-75"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
          {{ recipe.estimatedTimeMinutes }} Min
        </span>
      </div>

      <!-- AI Insight Banner Box -->
      <div v-if="recipe.foodWastePriorityReason" class="mt-4 p-3 bg-accent/5 border border-accent/20 rounded-xl text-sm text-text font-medium flex items-start gap-2.5">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-accent mt-0.5 shrink-0">
          <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
        </svg>
        <div class="flex flex-col gap-0.5">
          <span class="text-[10px] font-bold text-accent uppercase tracking-wider">AI Insight</span>
          <span class="text-muted leading-snug">{{ recipe.foodWastePriorityReason }}</span>
        </div>
      </div>
    </div>

    <div class="p-5 flex-1 flex flex-col justify-between">
      <div>
        <!-- Ingredients Grid -->
        <div class="grid grid-cols-2 gap-4 mb-5">
          <!-- Used Ingredients -->
          <div>
            <h4 class="font-bold text-text text-sm mb-2.5 flex items-center gap-1.5">
              Verwendet
              <span class="text-[10px] bg-secondary/10 text-secondary px-2 py-0.5 rounded-full font-bold">{{ recipe.usedIngredients.length }}</span>
            </h4>
            <ul class="text-sm text-muted space-y-1.5">
              <li v-for="ing in recipe.usedIngredients" :key="ing" class="flex items-start gap-1.5">
                <svg class="text-secondary shrink-0 mt-0.5" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                  <polyline points="20 6 9 17 4 12"></polyline>
                </svg>
                <span class="leading-tight">{{ ing }}</span>
              </li>
            </ul>
          </div>

          <!-- Missing Ingredients -->
          <div>
            <h4 class="font-bold text-text text-sm mb-2.5 flex items-center gap-1.5">
              Fehlt noch
              <span class="text-[10px] bg-primary/10 text-primary px-2 py-0.5 rounded-full font-bold">{{ recipe.missingRequiredIngredients?.length || 0 }}</span>
            </h4>
            <ul class="text-sm text-muted space-y-1.5">
              <li v-for="ing in recipe.missingRequiredIngredients" :key="ing" class="flex items-start gap-1.5">
                <span class="h-1.5 w-1.5 rounded-full bg-primary/50 shrink-0 mt-2 ml-1"></span>
                <span class="leading-tight">{{ ing }}</span>
              </li>
              <li v-if="!recipe.missingRequiredIngredients?.length" class="text-xs text-secondary font-medium italic leading-tight flex items-center gap-1">
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                Alles da!
              </li>
            </ul>
          </div>
        </div>

        <!-- Optional Ingredients -->
        <div v-if="recipe.optionalIngredients?.length" class="mb-5 bg-background/40 rounded-xl p-3 border border-border/40">
          <h4 class="font-bold text-text text-xs uppercase tracking-wider mb-2 opacity-85">Optionale Veredelung</h4>
          <ul class="text-xs text-muted flex flex-wrap gap-1.5">
            <li v-for="ing in recipe.optionalIngredients" :key="ing" class="bg-white px-2.5 py-1 rounded-lg border border-border/30 font-medium">
              + {{ ing }}
            </li>
          </ul>
        </div>

        <!-- Preparation Steps -->
        <div>
          <h4 class="font-bold text-text text-sm mb-3 border-t border-border/20 pt-4">Zubereitung</h4>
          <ol class="text-sm text-muted space-y-3">
            <li v-for="(step, idx) in recipe.steps" :key="idx" class="flex gap-2">
              <span class="font-extrabold text-primary shrink-0 text-sm">{{ idx + 1 }}.</span>
              <span class="leading-relaxed">{{ step }}</span>
            </li>
          </ol>
        </div>
      </div>
      
      <!-- Explanation Text -->
      <div v-if="recipe.explanation" class="mt-6 p-3 bg-background/30 rounded-xl border border-dashed border-border/60">
        <p class="text-xs text-muted font-medium italic leading-relaxed">{{ recipe.explanation }}</p>
      </div>
    </div>

    <!-- CTA Button Area -->
    <div class="p-5 border-t border-border/20 bg-background/20">
      <button class="w-full bg-primary hover:bg-primary/95 text-white font-bold py-3 px-4 rounded-xl shadow-sm hover:shadow transition-all duration-200 cursor-pointer flex justify-center items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>
        Jetzt kochen
      </button>
    </div>
  </div>
</template>
