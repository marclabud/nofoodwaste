<script setup lang="ts">
import { computed } from 'vue'
import type { Ingredient } from '~/types'
import { useIngredients } from '~/composables/useIngredients'

const props = defineProps<{
  ingredient: Ingredient
}>()

const { getStatus, deleteIngredient } = useIngredients()

const status = computed(() => getStatus(props.ingredient.expiresAt))

const statusClasses = computed(() => {
  switch (status.value) {
    case 'expired':
      return 'border-muted text-muted opacity-60'
    case 'expiring_today':
      return 'border-orange text-orange'
    case 'valid':
    default:
      return 'border-primary/50 text-text' // Or some green if we had it, fallback to default
  }
})

const isDeleting = ref(false)

const remove = async () => {
  isDeleting.value = true
  try {
    await deleteIngredient(props.ingredient.id)
  } catch (e) {
    console.error(e)
    isDeleting.value = false
  }
}

const formatDate = (dateStr: string) => {
  const parts = dateStr.split('-')
  if (parts.length === 3) {
    return `${parts[2]}.${parts[1]}.${parts[0]}`
  }
  return dateStr
}
</script>

<template>
  <div class="p-3 rounded-lg border bg-surface/50 flex justify-between items-center" :class="statusClasses">
    <div>
      <div class="font-medium text-lg flex items-center gap-2">
        <span>{{ ingredient.name }}</span>
        <span v-if="status === 'expired'" class="text-xs px-2 py-0.5 rounded-full bg-muted/20 text-muted">Verfallen</span>
        <span v-if="status === 'expiring_today'" class="text-xs px-2 py-0.5 rounded-full bg-orange/20 text-orange">Läuft heute ab</span>
      </div>
      <div class="text-sm opacity-80 mt-1">
        {{ ingredient.quantity }} {{ ingredient.unit }}
      </div>
      <div class="text-xs opacity-70 mt-1">
        Gültig bis {{ formatDate(ingredient.expiresAt) }}
      </div>
    </div>
    
    <button @click="remove" :disabled="isDeleting" class="p-2 text-muted hover:text-primary transition-colors disabled:opacity-50" aria-label="Löschen">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 6h18"></path>
        <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
        <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
      </svg>
    </button>
  </div>
</template>
