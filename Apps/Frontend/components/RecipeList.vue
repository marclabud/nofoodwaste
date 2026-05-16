<script setup lang="ts">
import type { Recipe } from '~/types'

const props = defineProps<{
  recipes: Recipe[]
}>()
</script>

<template>
  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <RecipeCard 
      v-for="(recipe, index) in recipes" 
      :key="index" 
      :recipe="recipe" 
    />
  </div>
</template>
