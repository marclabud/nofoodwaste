# Technical Specification: API & Validation

## REST API-Endpunkte

### Lebensmittel (Ingredients)
Verwaltung des Inventars.

```http
POST /ingredients
GET /ingredients
PUT /ingredients/:id
DELETE /ingredients/:id
```

### Rezepte (Recipes)
Generierung der AI-gestützten Rezepte.

```http
POST /recipes/generate
```

## Backend-Validierung

### Vor dem LLM-Aufruf (Request Validation)
Bevor die Daten an das KI-Modell gesendet werden, validiert das Backend:
- Es muss **mindestens 1 Zutat** ausgewählt sein.
- Es dürfen **keine verfallenen Zutaten** (expiresAt < today) an das LLM geschickt werden.
- Mengen (quantity) müssen **> 0** sein.

### Nach dem LLM-Aufruf (Response Validation)
Die API zwingt das LLM zu Structured Outputs. Die Antwort wird validiert auf:
- valides JSON
- Array enthält **1–3 Rezepte**
- Titel vorhanden
- Schritte vorhanden
- Arrays (usedIngredients, missingRequiredIngredients, optionalIngredients, steps) sind korrekt formatiert.
