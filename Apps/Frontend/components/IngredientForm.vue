<script setup lang="ts">
import { ref } from 'vue'
import type { CreateIngredient } from '~/types'
import { useIngredients } from '~/composables/useIngredients'

const { addIngredient } = useIngredients()

const name = ref('')
const quantity = ref(1)
const unit = ref<"g" | "kg" | "ml" | "l" | "piece">('piece')
const expiresAt = ref('')

const isSubmitting = ref(false)

const submit = async () => {
  if (!name.value || !expiresAt.value || quantity.value <= 0) return

  isSubmitting.value = true
  try {
    const newIng: CreateIngredient = {
      name: name.value,
      quantity: quantity.value,
      unit: unit.value,
      expiresAt: expiresAt.value
    }
    await addIngredient(newIng)
    
    // Reset form
    name.value = ''
    quantity.value = 1
    unit.value = 'piece'
    expiresAt.value = ''
  } catch (err) {
    console.error(err)
  } finally {
    isSubmitting.value = false
  }
}
</script>

<template>
  <div class="bg-surface p-4 rounded-lg border border-border/20">
    <h2 class="text-xl font-semibold text-text mb-4">Neues Lebensmittel</h2>
    <form @submit.prevent="submit" class="flex flex-col gap-4">
      <div>
        <label class="block text-sm text-muted mb-1">Name</label>
        <input v-model="name" type="text" required class="w-full bg-background border border-border/20 rounded p-2 text-text focus:outline-none focus:border-primary" placeholder="z.B. Tomaten" />
      </div>
      
      <div class="flex gap-4">
        <div class="flex-1">
          <label class="block text-sm text-muted mb-1">Menge</label>
          <input v-model="quantity" type="number" step="0.1" min="0.1" required class="w-full bg-background border border-border/20 rounded p-2 text-text focus:outline-none focus:border-primary" />
        </div>
        <div class="flex-1">
          <label class="block text-sm text-muted mb-1">Einheit</label>
          <select v-model="unit" class="w-full bg-background border border-border/20 rounded p-2 text-text focus:outline-none focus:border-primary">
            <option value="g">g</option>
            <option value="kg">kg</option>
            <option value="ml">ml</option>
            <option value="l">l</option>
            <option value="piece">Stück</option>
          </select>
        </div>
      </div>
      
      <div>
        <label class="block text-sm text-muted mb-1">Verfallsdatum</label>
        <input v-model="expiresAt" type="date" required class="w-full bg-background border border-border/20 rounded p-2 text-text focus:outline-none focus:border-primary" />
      </div>

      <button type="submit" :disabled="isSubmitting" class="w-full bg-primary hover:bg-primary/90 text-white font-semibold py-2 px-4 rounded transition-colors disabled:opacity-50">
        {{ isSubmitting ? 'Wird gespeichert...' : 'Hinzufügen' }}
      </button>
    </form>
  </div>
</template>
