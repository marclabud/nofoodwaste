# 🛠️ Workshop Repo Construction Guide: Deconstructive Git Workflow

This guide details the **Deconstructive Git Workflow (Working Backwards)**, which is the fastest and most reliable method to prepare the starter template and individual module branches in your training repository: `workshop-nofoodwaste-mvp`.

---

## 💡 Why This Workflow?
Instead of coding "forwards" from a blank slate—which often introduces broken imports, workspace mismatches, or syntax errors—you start with the **100% completed, fully functional solution** and strip away code backwards. 

This guarantees that:
1. **Workspace configs** are correct on all branches.
2. **Dependency trees** and package versions match perfectly.
3. **CORS and API proxies** are fully operational.
4. You have a **perfect safety net** to reset any stuck student during the class (`git checkout module-X`).

---

## 🏃‍♂️ Step-by-Step Construction Guide

### Step 1: Initialize the New Repository & Copy the Solution
Create a brand new local directory for the training repo and copy your *entire* completed workspace into it (excluding `.git`, `node_modules`, and `.venv`).

```bash
# 1. Create a new directory and initialize Git
mkdir workshop-nofoodwaste-mvp
cd workshop-nofoodwaste-mvp
git init -b main

# 2. Copy the completed files from your current workspace
cp -R /Users/hector/dev/NoFoodWaste/* .

# 3. Clean up build caches and node modules to keep the copy clean
rm -rf node_modules Apps/Frontend/node_modules Apps/Frontend/.nuxt Apps/Frontend/dist Apps/Frontend/.output
rm -rf Apps/Backend/.venv Apps/Backend/__pycache__ Apps/Backend/food_waste.db
```

---

### Step 2: Commit the Final Solution to `module-4`
We begin by establishing the final completed codebase as the target solution branch (`module-4`).

```bash
# Create the branch representing the completed code (Module 4 / Solution)
git checkout -b module-4
git add .
git commit -m "feat: complete NoFoodWaste MVP solution (Module 4)"
```

---

### Step 3: Deconstruct the Code (Backwards Flow)

#### 🗺️ Phase A: Create `module-3` (Strip the Frontend UI)
We will take `module-4`, remove the spec-driven UI views, and leave empty skeleton Vue files so students can code the layout.

```bash
# 1. Branch from module-4
git checkout -b module-3

# 2. Strip Frontend UI Cards/Components:
# Open app.vue, IngredientCard.vue, IngredientForm.vue, RecipeCard.vue.
# Delete the templates and Tailwind styles, leaving only blank grids and empty <script setup> placeholders.

# 3. Commit the changes
git add .
git commit -m "milestone: prepare Module 3 (FastAPI & Agent working, Frontend UI stripped)"
```

#### 🗺️ Phase B: Create `module-2` (Strip the AI Agent)
From `module-3`, we remove the Google ADK 2.0 integration and the system prompts.

```bash
# 1. Branch from module-3
git checkout -b module-2

# 2. Strip LLM Integration:
# - Delete the prompt file: rm Apps/Backend/prompts/system_recipe_assistant.md
# - Empty llm_service.py: Strip out the Cook Agent instantiation and InMemoryRunner block, 
#   returning an empty list or raising a NotImplementedError.
# - Empty the /recipes/generate endpoint in main.py.

# 3. Commit the changes
git add .
git commit -m "milestone: prepare Module 2 (SQLite CRUD working, LLM & Prompt stripped)"
```

#### 🗺️ Phase C: Create `module-1` (Strip the Database CRUD & Handlers)
From `module-2`, we remove the database queries and FastAPI handler logic.

```bash
# 1. Branch from module-2
git checkout -b module-1

# 2. Strip SQLite CRUD & Endpoint Handlers:
# - Empty database.py query functions (create_ingredient, get_ingredients, etc.).
# - Empty models.py (remove fields from IngredientBase, Ingredient, Recipe).
# - Empty the router methods in main.py (make them return static empty arrays/objects).
# - Empty composables/useIngredients.ts in the frontend (remove fetch calls).

# 3. Commit the changes
git add .
git commit -m "milestone: prepare Module 1 (Spec and Monorepo setup only, CRUD/API stripped)"
```

#### 🗺️ Phase D: Create `main` (Strip the Spec - The Blank Slate)
Finally, we return to `main` and remove the Spec files themselves so the training starts on a truly blank canvas.

```bash
# 1. Switch back to main and merge the clean, stripped foundation
git checkout main
git merge module-1 --no-ff

# 2. Strip the Spec files
rm -rf specs/business/*

# 3. Commit the final clean Starter Template
git add .
git commit -m "init: starter template blank slate (Monorepo ready, specs stripped)"
```

---

### Step 4: Publish to GitHub
Now, create your remote GitHub repository at `github.com/yourusername/workshop-nofoodwaste-mvp` and push all your branches simultaneously:

```bash
# Link the remote repository
git remote add origin git@github.com:yourusername/workshop-nofoodwaste-mvp.git

# Push ALL branches to GitHub in one command
git push origin --all
```
