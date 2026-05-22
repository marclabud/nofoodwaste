# Technical Specification: API & Validation

This specification defines the REST API endpoints, JSON request/response payloads, and the validation pipeline of the *No Food-Waste Recipe Finder* backend.

---

## 🔌 REST API Endpoints

### 1. System Health
Verify if the FastAPI backend is running and healthy.

* **URL:** `GET /health`
* **Response Payload (200 OK):**
  ```json
  {
    "status": "ok",
    "message": "FastAPI server is running!"
  }
  ```

---

### 2. Ingredients Management (CRUD)

#### 2.1. Add Ingredient
Create and store a new ingredient. The backend automatically generates a `uuid4` as `id` and an ISO UTC timestamp as `createdAt`.

* **URL:** `POST /ingredients`
* **Request Payload (`IngredientCreate`):**
  ```json
  {
    "name": "Tomaten",
    "quantity": 4.0,
    "unit": "piece",
    "expiresAt": "2026-05-25"
  }
  ```
* **Response Payload (`Ingredient` - 200 OK):**
  ```json
  {
    "id": "e9b28271-8bc6-4654-be8c-9b16ea9846b0",
    "name": "Tomaten",
    "quantity": 4.0,
    "unit": "piece",
    "expiresAt": "2026-05-25",
    "createdAt": "2026-05-22T05:22:15.123456+00:00"
  }
  ```

#### 2.2. Get All Ingredients
Retrieve all ingredients stored in the database, ordered by expiration date (`expiresAt` ASC).

* **URL:** `GET /ingredients`
* **Response Payload (List of `Ingredient` - 200 OK):**
  ```json
  [
    {
      "id": "e9b28271-8bc6-4654-be8c-9b16ea9846b0",
      "name": "Tomaten",
      "quantity": 4.0,
      "unit": "piece",
      "expiresAt": "2026-05-25",
      "createdAt": "2026-05-22T05:22:15.123456+00:00"
    }
  ]
  ```

#### 2.3. Update Ingredient
Update an existing ingredient by its ID.

* **URL:** `PUT /ingredients/{ingredient_id}`
* **Request Payload (`IngredientCreate`):**
  ```json
  {
    "name": "Tomaten",
    "quantity": 5.0,
    "unit": "piece",
    "expiresAt": "2026-05-28"
  }
  ```
* **Response Payload (`Ingredient` - 200 OK):**
  ```json
  {
    "id": "e9b28271-8bc6-4654-be8c-9b16ea9846b0",
    "name": "Tomaten",
    "quantity": 5.0,
    "unit": "piece",
    "expiresAt": "2026-05-28",
    "createdAt": "2026-05-22T05:22:15.123456+00:00"
  }
  ```

#### 2.4. Delete Ingredient
Delete an ingredient from the database by its ID.

* **URL:** `DELETE /ingredients/{ingredient_id}`
* **Response Payload (200 OK):**
  ```json
  {
    "message": "Ingredient deleted"
  }
  ```
* **Error Response (404 Not Found):**
  ```json
  {
    "detail": "Ingredient not found"
  }
  ```

---

### 3. Recipe Generation (Agent-gestützt)
Triggers the Google ADK 2.0 Cook Agent to generate customized recipe recommendations.

* **URL:** `POST /recipes/generate`
* **Request Payload (`GenerateRecipeRequest`):**
  ```json
  {
    "ingredient_ids": [
      "e9b28271-8bc6-4654-be8c-9b16ea9846b0"
    ]
  }
  ```
* **Response Payload (`RecipeResponse` - 200 OK):**
  ```json
  {
    "recipes": [
      {
        "title": "Tomaten-Kartoffel-Pfanne",
        "matchScore": 0.95,
        "foodWastePriorityReason": "Die Tomaten haben das früheste Verfallsdatum und werden vollständig verwertet.",
        "estimatedTimeMinutes": 35,
        "usedIngredients": ["Tomaten"],
        "missingRequiredIngredients": ["Kartoffeln", "Salz", "Öl"],
        "optionalIngredients": ["Zwiebeln"],
        "steps": [
          "Kartoffeln kochen und in Scheiben schneiden.",
          "Tomaten würfeln.",
          "Pfanne erhitzen, Kartoffeln anbraten und am Schluss Tomaten dazugeben."
        ],
        "explanation": "Dieses Rezept verwertet deine Tomaten vollständig und kombiniert sie mit gängigen Vorratskammer-Zutaten."
      }
    ]
  }
  ```

---

## 🛡️ Validation & Robustness Layer

### 1. Request Validation (FastAPI & Pydantic)
Before executing database modifications or invoking the AI Agent, the backend performs strict type-safe and business validations:

* **Zutaten-Erfassung:**
  * **Name:** Muss ein nicht-leerer String sein.
  * **Menge (Quantity):** Muss eine Fließkommazahl `> 0` sein (mittels Pydantic-Typisierung erzwungen).
  * **Einheit (Unit):** Muss exakt einer der erlaubten Literale entsprechen (`"g"`, `"kg"`, `"ml"`, `"l"`, `"piece"`).
  * **Verfallsdatum (ExpiresAt):** Muss ein valider String im Datumsformat `YYYY-MM-DD` sein.

* **Zutaten-Filterung vor LLM-Generierung:**
  * Die übergebenen `ingredient_ids` müssen in der Datenbank existieren. Wenn keine gültigen Zutaten gefunden werden, antwortet das Backend mit `400 Bad Request`.
  * **Ausschluss verfallener Zutaten:** Die Anwendung ermittelt das aktuelle Tagesdatum (`YYYY-MM-DD`). Zutaten, deren `expiresAt < today` ist, werden vor der Agenten-Abfrage herausgefiltert. Sollten dadurch keine verwendbaren Zutaten verbleiben, bricht die Anfrage mit `400 Bad Request` ("No non-expired ingredients found") ab.

---

### 2. Response Normalization & Validation (Post-Processing)
Nachdem der ADK-Agent die Antwort von Gemini empfangen und geparst hat, greift die Python-seitige Bereinigungsebene in `llm_service.py`:

* **Structured Outputs:** Gemini 2.5 Flash wird durch das native OpenAPI-JSON-Schema von Pydantic (`RecipeResponse`) gezwungen, eine perfekt geformte JSON-Struktur auszugeben. 
* **Match-Score Normalisierung (Robustness Layer):**
  Um Darstellungsfehler im Frontend (z. B. `9500% Match`) auszuschließen, prüft das Backend jedes Rezept:
  1. Liefert Gemini einen Prozentwert als ganze Zahl (z. B. `95.0` statt `0.95`), wird dieser automatisch durch `100.0` geteilt.
  2. Der `matchScore` wird mittels `min(max(v, 0.0), 1.0)` fest auf das Intervall `[0.0, 1.0]` geklammert.
* **Typensicherheit:** Jedes Rezept wird gegen die Pydantic-Klasse `Recipe` validiert. Erst nach erfolgreicher Validierung und Normalisierung wird die Antwort als `RecipeResponse` an das Frontend ausgeliefert.
