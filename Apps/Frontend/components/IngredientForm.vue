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
  <div class="bg-white p-5 rounded-2xl border border-border/40 shadow-[0_2px_10px_rgba(0,0,0,0.03)] hover:shadow-[0_4px_16px_rgba(0,0,0,0.06)] transition-all duration-200">
    <h3 class="text-lg font-bold text-text mb-4 flex items-center gap-2">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="text-primary"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="16"></line><line x1="8" y1="12" x2="16" y2="12"></line></svg>
      Neues Lebensmittel
    </h3>
    <form @submit.prevent="submit" class="flex flex-col gap-4">
      <div>
        <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1.5">Name</label>
        <input v-model="name" type="text" required class="w-full bg-background border border-border rounded-xl p-2.5 text-text focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250 text-sm" placeholder="z.B. Tomaten" />
      </div>
      
      <div class="flex gap-4">
        <div class="flex-1">
          <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1.5">Menge</label>
          <input v-model="quantity" type="number" step="0.1" min="0.1" required class="w-full bg-background border border-border rounded-xl p-2.5 text-text focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250 text-sm" />
        </div>
        <div class="flex-1">
          <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1.5">Einheit</label>
          <select v-model="unit" class="w-full bg-background border border-border rounded-xl p-2.5 text-text focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250 text-sm cursor-pointer">
            <option value="g">g</option>
            <option value="kg">kg</option>
            <option value="ml">ml</option>
            <option value="l">l</option>
            <option value="piece">Stück</option>
          </select>
        </div>
      </div>
      
      <div>
        <label class="block text-xs font-bold text-muted uppercase tracking-wider mb-1.5">Verfallsdatum</label>
        <input v-model="expiresAt" type="date" required class="w-full bg-background border border-border rounded-xl p-2.5 text-text focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/20 transition-all duration-250 text-sm" />
      </div>

      <button type="submit" :disabled="isSubmitting" class="w-full bg-primary hover:bg-primary/95 text-white font-semibold py-3 px-4 rounded-xl shadow-sm hover:shadow transition-all duration-200 disabled:opacity-50 cursor-pointer flex justify-center items-center gap-2 mt-2">
        <span v-if="isSubmitting" class="flex items-center gap-2 justify-center">
          <svg class="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Speichert...
        </span>
        <span v-else class="flex items-center gap-1.5">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          Lebensmittel speichern
        </span>
      </button>
    </form>
  </div>
</template>
