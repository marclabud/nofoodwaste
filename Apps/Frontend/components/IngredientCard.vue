<script setup lang="ts">
import { ref, computed } from 'vue'
import type { Ingredient, CreateIngredient } from '~/types'
import { useIngredients } from '~/composables/useIngredients'

const props = defineProps<{
  ingredient: Ingredient
}>()

const { getStatus, deleteIngredient, updateIngredient } = useIngredients()

const status = computed(() => getStatus(props.ingredient.expiresAt))

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

const formatUnit = (unitStr: string) => {
  if (unitStr === 'piece') return 'Stück'
  return unitStr
}
</script>

<template>
  <div class="bg-white rounded-2xl border border-border/40 p-4 shadow-[0_2px_10px_rgba(0,0,0,0.03)] hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)] hover:-translate-y-[0.5px] transition-all duration-200 flex flex-col justify-center">
    <!-- View Mode -->
    <div v-if="!isEditing" class="flex justify-between items-center w-full gap-4">
      <div class="flex-1">
        <div class="font-bold text-text text-lg flex items-center gap-2">
          <span>{{ ingredient.name }}</span>
        </div>
        <div class="text-sm text-muted font-medium mt-1">
          {{ ingredient.quantity }} {{ formatUnit(ingredient.unit) }}
        </div>
        <div class="text-xs text-muted/80 font-medium mt-1.5 flex items-center gap-1">
          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="opacity-60"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
          MHD: {{ formatDate(ingredient.expiresAt) }}
        </div>
      </div>
      
      <div class="flex items-center gap-3">
        <!-- Status Badges -->
        <span v-if="status === 'expired'" class="px-3 py-1 rounded-full text-xs font-semibold bg-primary/10 text-primary whitespace-nowrap">
          Abgelaufen
        </span>
        <span v-else-if="status === 'expiring_today'" class="px-3 py-1 rounded-full text-xs font-semibold bg-accent/10 text-accent whitespace-nowrap">
          Läuft heute ab
        </span>
        <span v-else class="px-3 py-1 rounded-full text-xs font-semibold bg-secondary/10 text-secondary whitespace-nowrap">
          Frisch
        </span>

        <!-- Action Buttons -->
        <div class="flex gap-0.5 border-l border-border/40 pl-2">
          <button @click="isEditing = true" class="p-2 text-muted hover:text-primary transition-colors cursor-pointer rounded-lg hover:bg-background" aria-label="Bearbeiten">
            <!-- Pencil Icon -->
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z"></path>
            </svg>
          </button>
          <button @click="remove" :disabled="isDeleting" class="p-2 text-muted hover:text-primary transition-colors disabled:opacity-50 cursor-pointer rounded-lg hover:bg-background" aria-label="Löschen">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M3 6h18"></path>
              <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
              <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Edit Mode -->
    <div v-else class="w-full flex flex-col gap-4">
      <h3 class="text-sm font-bold text-text uppercase tracking-wide">Lebensmittel bearbeiten</h3>
      <div class="flex flex-col gap-3">
        <div>
          <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1">Name</label>
          <input v-model="editName" type="text" class="w-full bg-background border border-border rounded-xl p-2 text-text text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250" />
        </div>
        <div class="flex gap-3">
          <div class="flex-1">
            <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1">Menge</label>
            <input v-model="editQuantity" type="number" step="0.1" class="w-full bg-background border border-border rounded-xl p-2 text-text text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250" />
          </div>
          <div class="flex-1">
            <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1">Einheit</label>
            <select v-model="editUnit" class="w-full bg-background border border-border rounded-xl p-2 text-text text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250 cursor-pointer">
              <option value="g">g</option>
              <option value="kg">kg</option>
              <option value="ml">ml</option>
              <option value="l">l</option>
              <option value="piece">Stück</option>
            </select>
          </div>
        </div>
        <div>
          <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1">Verfallsdatum</label>
          <input v-model="editExpiresAt" type="date" class="w-full bg-background border border-border rounded-xl p-2 text-text text-sm focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250" />
        </div>
      </div>
      
      <div class="flex gap-2 justify-end pt-1 border-t border-border/30">
        <button @click="cancelEdit" class="px-4 py-2 text-sm font-semibold text-muted hover:text-text transition-colors rounded-xl hover:bg-background cursor-pointer">
          Abbrechen
        </button>
        <button @click="saveEdit" :disabled="isUpdating" class="px-4 py-2 text-sm font-semibold bg-primary text-white rounded-xl hover:bg-primary/95 transition-all shadow-sm disabled:opacity-50 cursor-pointer">
          {{ isUpdating ? 'Speichert...' : 'Speichern' }}
        </button>
      </div>
    </div>
  </div>
</template>
