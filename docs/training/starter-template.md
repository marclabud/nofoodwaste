# 🎒 Workshop Repository Setup: workshop-nofoodwaste-mvp

This document outlines the repository structure, branch strategy, and file-by-file contents for the **NoFoodWaste Spec-Driven AI Agent Workshop** starter template.

---

## 🎯 Repository Name: `workshop-nofoodwaste-mvp`

---

## 🗂️ Starter Template Structure (`main` branch)

The starter template is designed as a `pnpm` monorepo containing a Vue/Nuxt 4 frontend and a Python/FastAPI backend, with SQLite as the database provider.

```text
workshop-nofoodwaste-mvp/
├── package.json               # Root Workspace definition (Pre-configured)
├── pnpm-workspace.yaml        # Workspace configuration (Pre-configured)
├── README.md                  # Instructions for setup & run (Pre-configured)
├── run-podman.sh              # Local shell orchestrator (Pre-configured)
│
├── specs/                     # [Empty for Module 1]
│   └── business/              
│
├── Apps/
│   ├── Backend/
│   │   ├── requirements.txt   # Python deps: fastapi, google-adk, pydantic (Pre-configured)
│   │   ├── main.py            # FastAPI main router (Pre-configured routes, empty handlers)
│   │   ├── models.py          # Ingredient & Recipe schemas (Empty/Skeleton)
│   │   ├── database.py        # SQLite helper methods (Pre-configured connection, empty CRUD)
│   │   ├── llm_service.py     # Cook Agent integration (Empty skeleton)
│   │   ├── .env.example       # Example env keys (Pre-configured)
│   │   └── prompts/           # LLM Instruction files [Empty for Module 3]
│   │
│   └── Frontend/
│       ├── package.json       # Nuxt & Tailwind packages (Pre-configured)
│       ├── nuxt.config.ts     # Nuxt configuration with Proxy & UI (Pre-configured)
│       ├── app.vue            # Main layout skeleton (Empty grid, pre-configured headers)
│       ├── composables/       
│       │   ├── useIngredients.ts # State & HTTP requests for ingredients (TODOs)
│       │   └── useRecipes.ts     # API Call for recipes (TODOs)
│       └── components/        
│           ├── IngredientCard.vue # Visual card for ingredients (TODO styling)
│           ├── IngredientForm.vue # Simple input form for inventory (TODO layout)
│           └── RecipeCard.vue     # Visual representation of AI recipe (TODO mapping)
```

---

## 🛠️ File-by-File Breakdown: Pre-configured vs. TODOs

### 1. Root Monorepo & Setup (100% Pre-configured)
* **`pnpm-workspace.yaml` / `package.json`**: Pre-defined so that running `pnpm install` in the root installs all Nuxt UI and Python virtualenv setups seamlessly.
* **`run-podman.sh`**: Pre-written native shell script that mounts volumes, handles network routing, and runs the production OCI containers.

### 2. The `specs/` Directory (Module 1 Sandbox)
* **Starter (`main`):** Completely empty.
* **Workshop Task:** In Module 1A, students write `no-food-waste-mvp.spec.md` defining the UI actions, the API parameters, and the design parameters based on a provided business brief.

### 3. `Apps/Backend` (Modules 2 & 3 Sandbox)
* **`requirements.txt` (Pre-configured):** Already has the exact pinned versions of `fastapi`, `uvicorn`, `pydantic`, and `google-adk`.
* **`database.py` (Pre-configured Connection, Empty CRUD):**
  * *Pre-configured:* SQLite database initialization (`sqlite3.connect`) and table creation (`CREATE TABLE IF NOT EXISTS`).
  * *TODO for Students:* Writing the CRUD functions: `create_ingredient`, `get_ingredients`, and `delete_ingredient` using standard Python SQLite methods.
* **`models.py` (TODO Schemas):**
  * *Pre-configured:* Imports and empty classes.
  * *TODO for Students:* Writing the Pydantic classes: `IngredientCreate`, `Ingredient` (extending Pydantic `BaseModel`), and `Recipe` (specifying properties like `title`, `matchScore`, `steps`, `foodWastePriorityReason` as requested by the Spec).
* **`main.py` (Pre-configured Router, Empty Handlers):**
  * *Pre-configured:* CORS Middleware setup (crucial to prevent local blocks) and standard router bindings.
  * *TODO for Students:* Connecting the endpoint functions to call the functions they wrote in `database.py`.
* **`llm_service.py` & `prompts/` (Module 3 - TODO Agent Logic):**
  * *Pre-configured:* File reading helper (`load_system_prompt`).
  * *TODO for Students:* 
    1. Write `prompts/system_recipe_assistant.md` containing the Markdown prompt detailing the cooking instructions, anti-jailbreak guidelines, and food waste scoring.
    2. Write the **Google ADK 2.0 Agent setup** in `llm_service.py`: Instantiating `Agent` with `Gemini 2.5 Flash`, assigning the system prompt, and defining `output_schema=RecipeResponse` to force structured validation.

### 4. `Apps/Frontend` (Modules 2 & 4 Sandbox)
* **`nuxt.config.ts` (Pre-configured):**
  * Pre-configured with the backend API proxy (e.g. `/api/*` proxies to `http://localhost:8000/*` to avoid dev-time CORS errors).
  * TailwindCSS 4 and Nuxt UI auto-imports pre-configured.
* **`composables/` (TODO States & API Fetches):**
  * *TODO for Students:*
    * `useIngredients.ts`: Implement `ref<Ingredient[]>` state, plus async methods `fetchIngredients()`, `addIngredient()`, and `deleteIngredient()` utilizing `useFetch('/api/ingredients')`.
    * `useRecipes.ts`: Implement `generateRecipes(selectedIds)` using post requests.
* **`components/` (TODO Visual Styling & Event Emitting):**
  * *Pre-configured:* Skeleton Vue templates with standard `<script setup>` and empty `<template>` blocks.
  * *TODO for Students:* 
    * `IngredientForm.vue`: Build a sleek card containing inputs for Name, Quantity, Unit (dropdown), and Expiry Date. Emit `submit` event.
    * `IngredientCard.vue`: Render the ingredient detail with conditional coloring (e.g., Red badge for items expiring today, grey for items in inventory) and a delete button.
    * `RecipeCard.vue`: Render the AI output (displaying Title, Match Score as a clean percentage badge, step-by-step instructions, and the crucial *Food Waste Priority Reason*).

---

## 🧭 Branch Progression Strategy for the Trainer

| Branch | Module | State of the codebase | Milestone reached |
| :--- | :--- | :--- | :--- |
| **`main`** | - | **Pure Starter Template** | Blank slate monorepo, clean dependencies installed. |
| **`module-1`** | **1** | Has `specs/business/no-food-waste-mvp.spec.md` | Spec is locked. Design tokens and variables are agreed upon. |
| **`module-2`** | **2** | Has SQLite DB CRUD and REST endpoints working | Backend can store and fetch ingredients. Frontend can CRUD ingredients. |
| **`module-3`** | **3** | Has `llm_service.py` with ADK 2.0 Agent and Gemini | The backend can securely send ingredients to Gemini and get type-safe recipes. |
| **`module-4`** | **4** | Has Nuxt 4 UI Cards, UI Lists, and state bindings | **Full MVP completes!** The application is fully reactive and working. |
