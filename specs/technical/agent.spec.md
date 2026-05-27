# Technical Specification: Cook Agent (`cook_agent`)

This specification defines the technical implementation, architecture, and behavior of the **Cook Agent** (`cook_agent`) inside the *No Food-Waste Recipe Finder* backend.

---

## 🏗️ Architecture & Framework
The agent is implemented using **Google ADK (Agent Development Kit) 2.0** as an autonomous, encapsulated software block.

* **Core Engine:** **Gemini 2.5 Flash** (configurable via environment variable `LLM_MODEL`, resolved by `llm_service.py`).
* **Framework:** `google.adk.agents.Agent`
* **Execution Context:** `google.adk.runners.InMemoryRunner` (inside `agent_service.py`)
* **Structured Input/Output:** Pydantic validation (`pydantic>=2.7.0`) via the `RecipeResponse` schema.

```text
FastAPI Endpunkt (main.py)
      │
      ▼
Zutaten-Filtern (MHD-Verfallprüfung)
      │
      ▼
Agent-Service (agent_service.py) [Resolves model via llm_service.py]
 └── [InMemoryRunner]
      └── [cook_agent] (Google ADK 2.0)
            ├── Prompts (system_recipe_assistant.md)
            └── Output Schema (RecipeResponse)
                  │
                  ▼
            [Gemini 2.5 Flash] ──► Generiert structured JSON
                  │
                  ▼
Daten-Normalisierung (Local Post-Processing in agent_service.py)
      │ (Dividiert matchScore / 100 falls > 1.0, klammert auf [0.0, 1.0])
      ▼
Valides JSON-Response an Nuxt-Frontend
```

---

## ⚙️ Agent Configuration

The agent is instantiated programmatically inside [agent_service.py](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/agent_service.py) with the following attributes:

```python
cook_agent = Agent(
    name="cook_agent",
    model=model_name,              # e.g., "gemini-2.5-flash" (resolved via llm_provider)
    instruction=load_system_prompt(), # Loaded from system_recipe_assistant.md
    output_schema=RecipeResponse,  # Pydantic model for Structured Outputs
    output_key="recipe_response"
)
```

---

## 🔌 Interface Definition (I/O)

### 1. Input Format (User Prompt)
The agent receives a stringified JSON representation of the available ingredients.
* **Fields omitted to save tokens:** `id` and `createdAt` are stripped out by the endpoint handler.
* **MHD-Filter:** Already filtered in [main.py](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/main.py) so that expired ingredients are never sent to the LLM.

**Example Input JSON:**
```json
{
  "ingredients": [
    {
      "name": "Tomaten",
      "quantity": 4.0,
      "unit": "piece",
      "expiresAt": "2026-05-25"
    },
    {
      "name": "Eier",
      "quantity": 6.0,
      "unit": "piece",
      "expiresAt": "2026-05-23"
    }
  ]
}
```

### 2. Output Format (Structured Outputs)
The agent's output is governed by Pydantic models in [models.py](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/models.py). The Google ADK generates the native OpenAPI 3.0 schema from `RecipeResponse` and forces Gemini to respond strictly within this structure.

```python
class Recipe(BaseModel):
    title: str = Field(..., description="Kreativer, ansprechender Name für das Rezept")
    matchScore: float = Field(
        ...,
        description="The match score of the recipe, representing how well the recipe fits the user's available ingredients and food waste priorities. Must be a decimal between 0.0 and 1.0 (e.g., 0.95 for 95%)."
    )
    foodWastePriorityReason: str = Field(..., description="Erklärung, warum dieses Rezept Lebensmittelverschwendung verringert (z.B. Nutzung ablaufender Eier)")
    estimatedTimeMinutes: int = Field(..., description="Geschätzte Koch- und Zubereitungszeit")
    usedIngredients: list[str] = Field(..., description="Verwendete Zutaten aus dem Bestand")
    missingRequiredIngredients: list[str] = Field(..., description="Pflichtzutaten, die fehlen und zusätzlich benötigt werden")
    optionalIngredients: list[str] = Field(..., description="Optionale Zutaten zur Verfeinerung")
    steps: list[str] = Field(..., description="Schritt-für-Schritt Zubereitungsschritte (kurz und präzise)")
    explanation: str = Field(..., description="Detaillierte fachliche Begründung für diesen Rezeptvorschlag")

class RecipeResponse(BaseModel):
    recipes: list[Recipe]
```

---

## 🧠 Behavior and Core Prompt Logic
The agent's behavioral core is described in [system_recipe_assistant.md](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/prompts/system_recipe_assistant.md):

1. **Food-Waste-Fokus:** Rezepte müssen vorrangig Zutaten mit nahem Verfallsdatum vollständig verwerten.
2. **Trennung von Zutaten:** Fehlende Zutaten müssen klar ausgewiesen werden, damit der Benutzer weiß, was er zusätzlich benötigt.
3. **Einfachheit:** Kurze, verständliche Schritte für schnelle Alltagsentscheidungen.

---

## 🔒 Security Guardrails (Härtung)
To protect the backend from abuse, prompt injection, or jailbreaks, the following logic is embedded in the agent's instructions:

* **Context Enforcement:** If a query contains non-food, non-cooking, or nonsensical instructions (e.g., trying to write code, answering general knowledge), the agent is instructed to bypass normal generation and **return an empty `recipes` array** instead of plain text error messages.
* **Separation of Instructions:** User input is treated strictly as raw data (JSON strings) passed through `InMemoryRunner.run_debug(prompt_user)`. It cannot override the system instruction.

---

## 🛠️ Local Post-Processing & Normalization (Robustness Layer)
Since Large Language Models (LLMs) can occasionally return the `matchScore` as an integer percentage (e.g., `95.0` or `95` for 95%) rather than a decimal float (e.g., `0.95`), the backend executes a local post-processing step in `agent_service.py` directly after parsing the JSON response:

```python
# Extract and parse response
recipe_response = RecipeResponse.model_validate_json(final_text)

# Normalize matchScore for each generated recipe
for recipe in recipe_response.recipes:
    # If the LLM returned an integer percentage score like 95.0 instead of 0.95, divide it by 100
    if recipe.matchScore > 1.0:
        recipe.matchScore = recipe.matchScore / 100.0
    # Clamping boundaries to strictly stay in the [0.0, 1.0] interval
    recipe.matchScore = min(max(recipe.matchScore, 0.0), 1.0)
```

This guarantees that:
1. Pydantic schema consistency is maintained.
2. The Nuxt 4 frontend can safely render the score using `Math.round(recipe.matchScore * 100)` to display exactly **`95% Match`** (instead of `9500%`).

