<script setup lang="ts">
import type { Recipe } from '~/types'

const props = defineProps<{
  recipes: Recipe[]
}>()
</script>

<template>
  <div class="flex flex-col gap-6">
    <RecipeCard 
      v-for="(recipe, index) in recipes" 
      :key="index" 
      :recipe="recipe" 
    />
  </div>
</template>
