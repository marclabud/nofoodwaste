# ADR 0004: OpenAPI-Integration und automatisierte Typsynchronisierung im Nuxt 4 Frontend

## Status
Akzeptiert

## Kontext (Context)
Die Anwendung *NoFoodWaste* besteht aus einem Python-Backend (FastAPI, SQLite, Google ADK 2.0) und einem TypeScript-Frontend (Nuxt 4). 

Bisher wurden Datentypen für Lebensmittel/Zutaten und Rezepte auf beiden Seiten unabhängig voneinander gepflegt (Pydantic-Modelle in `models.py` auf Backend-Seite und TypeScript-Interfaces in `types/index.ts` auf Frontend-Seite). Diese redundante Definition führt bei Weiterentwicklungen zwangsläufig zu einem "Schema-Drift" und erhöht den Wartungsaufwand sowie das Risiko von Laufzeitfehlern bei inkompatiblen Schnittstellen.

Da wir in der Produktion das Nuxt 4 Frontend als statische Website (`nuxt generate`) über einen leichtgewichtigen Nginx-Container ausliefern, ist der Einsatz einer komplexen Nuxt-BFF-Proxy-Middleware (Backend-for-Frontend) im Produktivbetrieb ungeeignet. Stattdessen benötigen wir eine rein deklarative, build-zeitige Synchronisierung der API-Verträge.

## Entscheidung (Decision)
Wir etablieren das **FastAPI-Backend** als das führende System und die **Single Source of Truth** für das API-Schema.

Wir integrieren den OpenAPI-Standard und automatisieren die Typsynchronisierung wie folgt:
1. **Nutzung von `openapi-typescript`:** Wir installieren die CLI-Utility `openapi-typescript` als Entwicklungsabhängigkeit (`devDependency`) im Nuxt 4 Frontend.
2. **Generierung zur Entwicklungszeit:** Über das npm-Skript `"openapi:generate"` wird das vom FastAPI-Server bereitgestellte Schema unter `http://localhost:8000/openapi.json` abgerufen und in eine voll typisierte TypeScript-Definitionsdatei `types/openapi.d.ts` kompiliert.
3. **Refactoring der Frontend-Typen:** Die manuellen Interfaces in `types/index.ts` werden gelöscht und durch direkte Type-Aliase auf die generierten OpenAPI-Schema-Komponenten (`components['schemas']['...']`) ersetzt.

```typescript
// types/index.ts
import type { components } from './openapi'

export type Ingredient = components['schemas']['Ingredient']
export type CreateIngredient = components['schemas']['IngredientCreate']
export type Recipe = components['schemas']['Recipe']
export type RecipeResponse = components['schemas']['RecipeResponse']
```

## Konsequenzen (Consequences)

### Vorteile
* **Garantierte Übereinstimmung (Zero-Drift):** Jede Änderung an Backend-Modellen (z. B. neue Rezept-Eigenschaften) wird per Knopfdruck sofort fehlerfrei ins Frontend übertragen.
* **Compile-Time Typensicherheit:** Der TypeScript-Compiler (`nuxt typecheck` / `vue-tsc`) fängt Abweichungen in Event-Handlern, Composables oder Vue-Templates sofort zur Build-Zeit ab.
* **Saubere Trennung & Performance:** In der Produktion bleibt das Frontend komplett statisch und schlank (served by Nginx). Es ist keine Node.js-Laufzeitumgebung auf Nuxt-Ebene im Produktivnetz notwendig.
* **Rückwärtskompatibilität:** Da die exportierten Typennamen in `types/index.ts` identisch bleiben, müssen bestehende Vue-Komponenten oder Composables (`useIngredients`, `useRecipes`) nicht angepasst werden.

### Nachteile
* **Lokale Ausführungs-Abhängigkeit:** Um den Generierungs-Befehl ausführen zu können, muss die Python-FastAPI-Anwendung lokal unter Port `8000` gestartet sein.

## Referenzen & Verknüpfte Dokumente
* **ADR 0002:** [ADR 0002: Nutzung von OpenAPI 3.0 als Schema-Standard für LLM-Antworten](file:///Users/hector/dev/NoFoodWaste/docs/adr/0002-openapi-schema-fuer-llms.md)
* **Frontend package.json:** [package.json](file:///Users/hector/dev/NoFoodWaste/Apps/Frontend/package.json)
* **API Definitions:** [types/index.ts](file:///Users/hector/dev/NoFoodWaste/Apps/Frontend/types/index.ts)
* **Generated File:** [types/openapi.d.ts](file:///Users/hector/dev/NoFoodWaste/Apps/Frontend/types/openapi.d.ts)
