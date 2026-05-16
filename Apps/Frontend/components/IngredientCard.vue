<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Ingredient, CreateIngredient } from '~/types'
import { useIngredients } from '~/composables/useIngredients'

const props = defineProps<{
  ingredient: Ingredient
}>()

const { getStatus, deleteIngredient, updateIngredient } = useIngredients()

const status = computed(() => getStatus(props.ingredient.expiresAt))

const statusClasses = computed(() => {
  if (isEditing.value) return 'border-primary/50 text-text'
  switch (status.value) {
    case 'expired':
      return 'border-muted text-muted opacity-60'
    case 'expiring_today':
      return 'border-orange text-orange'
    case 'valid':
    default:
      return 'border-primary/50 text-text'
  }
})

const isDeleting = ref(false)
const isEditing = ref(false)
const isUpdating = ref(false)

const editName = ref(props.ingredient.name)
const editQuantity = ref(props.ingredient.quantity)
const editUnit = ref(props.ingredient.unit)
const editExpiresAt = ref(props.ingredient.expiresAt)

const remove = async () => {
  isDeleting.value = true
  try {
    await deleteIngredient(props.ingredient.id)
  } catch (e) {
    console.error(e)
    isDeleting.value = false
  }
}

const saveEdit = async () => {
  isUpdating.value = true
  try {
    const updatedData: CreateIngredient = {
      name: editName.value,
      quantity: editQuantity.value,
      unit: editUnit.value,
      expiresAt: editExpiresAt.value
    }
    await updateIngredient(props.ingredient.id, updatedData)
    isEditing.value = false
  } catch (e) {
    console.error(e)
  } finally {
    isUpdating.value = false
  }
}

const cancelEdit = () => {
  isEditing.value = false
  editName.value = props.ingredient.name
  editQuantity.value = props.ingredient.quantity
  editUnit.value = props.ingredient.unit
  editExpiresAt.value = props.ingredient.expiresAt
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
  <div class="p-3 rounded-lg border bg-surface/50 flex flex-col justify-center" :class="statusClasses">
    <!-- View Mode -->
    <div v-if="!isEditing" class="flex justify-between items-center w-full">
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
      
      <div class="flex gap-1">
        <button @click="isEditing = true" class="p-2 text-muted hover:text-blue transition-colors" aria-label="Bearbeiten">
          <!-- Pencil Icon -->
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path>
          </svg>
        </button>
        <button @click="remove" :disabled="isDeleting" class="p-2 text-muted hover:text-primary transition-colors disabled:opacity-50" aria-label="Löschen">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 6h18"></path>
            <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
            <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
          </svg>
        </button>
      </div>
    </div>

    <!-- Edit Mode -->
    <div v-else class="w-full flex flex-col gap-3">
      <div>
        <label class="block text-xs text-muted mb-1">Name</label>
        <input v-model="editName" type="text" class="w-full bg-background border border-border/20 rounded p-1.5 text-text text-sm focus:outline-none focus:border-primary" />
      </div>
      <div class="flex gap-2">
        <div class="flex-1">
          <label class="block text-xs text-muted mb-1">Menge</label>
          <input v-model="editQuantity" type="number" step="0.1" class="w-full bg-background border border-border/20 rounded p-1.5 text-text text-sm focus:outline-none focus:border-primary" />
        </div>
        <div class="flex-1">
          <label class="block text-xs text-muted mb-1">Einheit</label>
          <select v-model="editUnit" class="w-full bg-background border border-border/20 rounded p-1.5 text-text text-sm focus:outline-none focus:border-primary">
            <option value="g">g</option>
            <option value="kg">kg</option>
            <option value="ml">ml</option>
            <option value="l">l</option>
            <option value="piece">Stück</option>
          </select>
        </div>
      </div>
      <div>
        <label class="block text-xs text-muted mb-1">Verfallsdatum</label>
        <input v-model="editExpiresAt" type="date" class="w-full bg-background border border-border/20 rounded p-1.5 text-text text-sm focus:outline-none focus:border-primary" />
      </div>
      
      <div class="flex gap-2 justify-end mt-1">
        <button @click="cancelEdit" class="px-3 py-1.5 text-sm text-muted hover:text-text transition-colors rounded border border-transparent hover:border-border/30">
          Abbrechen
        </button>
        <button @click="saveEdit" :disabled="isUpdating" class="px-3 py-1.5 text-sm bg-primary text-white rounded hover:bg-primary/90 transition-colors disabled:opacity-50">
          {{ isUpdating ? 'Speichert...' : 'Speichern' }}
        </button>
      </div>
    </div>
  </div>
</template>
