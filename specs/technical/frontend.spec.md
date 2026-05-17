# Technical Specification: Frontend

## Architektur
- **Framework:** Nuxt 4 (Vue)
- **Styling:** Tailwind CSS v4

## Komponenten

Das Frontend setzt sich aus folgenden Kern-Komponenten zusammen:
- `IngredientCard`: Anzeige eines einzelnen Lebensmittels (mit farblichem Status für Verfallsdatum).
- `IngredientSelector`: UI zur Auswahl, welche Zutaten an das LLM gesendet werden sollen.
- `RecipeCard`: Darstellung eines von der KI generierten Rezeptvorschlags (Card-based Action UI).
- `RecipeList`: Container-Komponente, die das Array der generierten Rezepte rendert.

## Mobile Verhalten (Responsive Design)

### Mobile First Ansatz
- Rezepte und Zutaten werden **vertikal gestapelt** gerendert (1-spaltig).
- Große Touch-Targets für Aktionen (z.B. Zutat auswählen, "Jetzt kochen" Button).

### Desktop Skalierung
- Optionales Grid-Layout für größere Bildschirme:
  - Darstellung von **2 Karten nebeneinander** (z.B. `grid-cols-2`).
