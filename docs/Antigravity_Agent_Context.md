# Technical Onboarding & Context Handbook: NoFoodWaste
*(For Antigravity 2.0 Building Agents)*

This document serves as the **Technical Source of Truth** and the architectural onboarding handbook. Any agentic AI system (such as Antigravity 2.0) working in this repository must strictly adhere to the guidelines, version constraints, and configurations detailed below.

---

## 1. Handshake-Prinzip: Mensch & Agent

### Workspace-Begrenzung
Das Stammverzeichnis dieses Git-Repositories ist das absolute Ende des Aktionsraums des Agenten. Der Agent darf sich **ausschließlich** innerhalb dieses Workspace-Verzeichnisses bewegen, dort Code analysieren, modifizieren, testen und verifizieren. Der Zugriff auf globale Verzeichnisse außerhalb des Projekts (mit Ausnahme lokaler Pyenv- oder Node-Bibliotheken zur Ausführung) ist untersagt.

### Rollenteilung
1.  **Der Mensch (Architekt)**: Definiert die fachlichen Anforderungen ([no-food-waste-mvp.spec.md](file:///Users/hector/dev/NoFoodWaste/specs/business/no-food-waste-mvp.spec.md)), stellt das technische Regelwerk bereit (`Antigravity_Agent_Context.md`) und verifiziert die Builds.
2.  **Der Agent (Entwickler)**: Führt Codeänderungen durch, implementiert Features, behebt Bugs und führt automatisierte Validierungen innerhalb des Workspace aus.

---

## 2. Tech Stack & Corepack-Konfiguration

Der gesamte Monorepo-Build baut auf einem deterministischen, reproduzierbaren Setup auf. Der Paketmanager ist auf Repository-Ebene festgenagelt.

### 2.1 Corepack & pnpm Pinning
*   **Paketmanager**: `pnpm` (Workspace Setup).
*   **Version Pinning**: `pnpm@10.33.0` (in `package.json` über `packageManager` definiert).
*   **Corepack-Aktivierung**: Vor jeder Interaktion mit Node-Skripten muss Corepack aktiviert werden, um Versions-Drift und Lockfile-Beschädigungen zu verhindern:
    ```bash
    corepack enable
    pnpm install
    ```
*   **Wichtige Regel für den Agenten**: Führe niemals globale npm/pnpm-Installationen durch, die die gepinnte Workspace-Version überschreiben.

### 2.2 Monorepo Layout
```text
/Users/hector/dev/NoFoodWaste/
├── Apps/
│   ├── Frontend/             # Nuxt 4 & TailwindCSS v4
│   └── Backend/              # Python 3.13 & FastAPI
├── specs/
│   ├── business/             # Fachliche Spezifikationen (Single Source of Truth)
│   └── technical/            # Technische Teilspezifikationen
├── docs/                     # Dokumentation & Onboarding-Handbücher
├── package.json              # Monorepo-Konfiguration (Corepack, Engines, Workspaces)
├── pnpm-workspace.yaml       # pnpm Workspace-Definition
└── run-podman.sh             # Lokale Podman Container-Orchestrierung
```

### 2.3 Technologie-Spezifikationen
*   **Frontend**: Nuxt 4 (Vue 3, TypeScript) & TailwindCSS v4.
*   **Backend**: Python 3.13 (FastAPI) & Google ADK 2.0.
*   **Datenbank**: SQLite (`food_waste.db`), leichtgewichtig und dateibasiert, automatisch initialisiert beim Serverstart.

---

## 3. Design System & Style-Tokens

Das Frontend implementiert die Design-Vision **„Warm Premium Off-White Sand“** und ist als **Tailwind v4 Custom Theme** in [main.css](file:///Users/hector/dev/NoFoodWaste/Apps/Frontend/assets/css/main.css) verankert.

### 3.1 Farb-Mapping
Jeder Agent muss sich strikt an diese definierten CSS-Variablen halten:

*   `--color-background: #F7F5F2` (Warmes Premium Off-White Sand)
*   `--color-surface: #FFFFFF` (Card- und Containerhintergründe)
*   `--color-primary: #D84C3F` (Terrakotta / Soft Red – für Buttons und Löschaktionen)
*   `--color-secondary: #6BA368` (Soft Green – für Frische-Indikatoren und Match-Scores)
*   `--color-accent: #F4A261` (Warm Orange – für AI-Insights und MHD-Warnungen)
*   `--color-text: #1F1F1F` (Tiefes Anthrazit für exzellente Lesbarkeit)
*   `--color-muted: #666666` (Dezentes Grau für Untertitel und Metadaten)
*   `--color-border: #EBE8E2` (Sehr weiches Warm-Grau für dezente Trennlinien)

### 3.2 Layout & Typografie
*   **Schriftart**: `Inter` (saubere Grotesk-Schrift).
*   **Grid**: 4px Base Grid mit 16px (1rem) seitlichem Padding und 24px (1.5rem) vertikalem Rhythmus.
*   **Schatten (Shadows)**: `box-shadow: 0 2px 10px rgba(0, 0, 0, 0.03)` mit weichen Übergängen und Micro-Interaktionen bei Hover-Effekten (`-translate-y-[0.5px]`).

---

## 4. API-Schnittstellen (API Contract)

Die Kommunikation zwischen Frontend und Backend erfolgt über eine standardisierte REST-API. Alle Endpunkte sind typensicher validiert.

### 4.1 CRUD-Endpunkte für Zutaten (`/ingredients`)

#### 1. Abfragen (`GET /ingredients`)
*   **Response**: `List[Ingredient]` (Status 200).
*   **Sortierung**: Erfolgt im Client automatisch nach MHD-Urringlichkeit, gefolgt von alphabetischer Sortierung.

#### 2. Erstellen (`POST /ingredients`)
*   **Input Body**: `IngredientCreate`
    ```json
    {
      "name": "Tomaten",
      "quantity": 4.0,
      "unit": "piece",
      "expiresAt": "2026-05-30"
    }
    ```
*   **Response**: `Ingredient` (enthält automatisch generierte `id` und `createdAt` ISO-Timestamp).

#### 3. Bearbeiten (`PUT /ingredients/{id}`)
*   **Input Body**: `IngredientCreate` (aktualisierte Werte).
*   **Response**: `Ingredient` (aktualisierter Datensatz, `createdAt` bleibt unverändert).

#### 4. Löschen (`DELETE /ingredients/{id}`)
*   **Response**: `{"message": "Ingredient deleted"}` (Status 200).

### 4.2 Rezeptgenerierung (`/recipes/generate`)

#### 1. Anfrage (`POST /recipes/generate`)
*   **Input Body**: `GenerateRecipeRequest`
    ```json
    {
      "ingredient_ids": ["uuid-1", "uuid-2"]
    }
    ```
*   **Inferenzfilter-Regel**: Der Endpoint filtert vor der LLM-Übergabe abgelaufene Zutaten (`expiresAt < today`) aus Sicherheitsgründen heraus und reduziert Payload-Informationen (keine `id` oder `createdAt` an die KI übergeben).
*   **Response**: `RecipeResponse` (Structured Output mit exakt 3 Rezepten).

---

## 5. Google ADK 2.0 & LLM-Inferenz

Die intelligente Rezeptgenerierung basiert vollständig auf **Google ADK (Agent Development Kit) 2.0** im Backend ([agent_service.py](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/agent_service.py)).

### 5.1 Model Provider & Choice
*   Die Modell-Auswahl ist vom Agenten entkoppelt und wird über den `LLMProvider` in [llm_service.py](file:///Users/hector/dev/NoFoodWaste/Apps/Backend/llm_service.py) bereitgestellt.
*   **Constants**: Das Backend definiert im Agenten-File Constants zur Auswahl:
    *   `LLM_GEMINI_FLASH = "gemini-2.5-flash"`
    *   `LLM_GEMINI_PRO = "gemini-2.5-pro"`
    *   `LLM_DEFAULT = "default"`
*   Der Agent instanziiert sich über die resolved Modellbezeichnung:
    ```python
    cook_agent = Agent(
        name="cook_agent",
        model=llm_provider.get_model(CHOSEN_LLM),
        instruction=load_system_prompt(),
        output_schema=RecipeResponse,
        output_key="recipe_response"
    )
    ```

### 5.2 Structured Outputs & Robustness Layer
*   ADK 2.0 erzwingt über das zugewiesene Pydantic-Schema `RecipeResponse` native, standardisierte JSON-Antworten von Gemini.
*   **Match-Score Normalisierung**: Nach der Inferenz führt das Backend in der Pipeline ein Post-Processing durch:
    ```python
    if recipe.matchScore > 1.0:
        recipe.matchScore = recipe.matchScore / 100.0
    recipe.matchScore = min(max(recipe.matchScore, 0.0), 1.0)
    ```

### 5.3 Sicherheitsleitplanken (Guardrails)
*   **Context Lock**: Wenn der Benutzer unsinnigen Text, Schadcode oder systemfremde Eingaben sendet, blockiert der Agent die Generierung und gibt ein **leeres Rezept-Array** (`recipes: []`) zurück, anstatt Fehlermeldungen der KI im Klartext auszugeben.

---

## 6. Deployment & Ausführung (Workflows)

### 6.1 Lokale Entwicklung (localdev)

#### Voraussetzungen:
1.  Node.js >= 24
2.  Python >= 3.13
3.  Gemini API-Schlüssel (in `Apps/Backend/.env` als `GEMINI_API_KEY` gesetzt).

#### Starten der Anwendung:
*   Aktivieren Sie Corepack und installieren Sie die Abhängigkeiten im Stammverzeichnis:
    ```bash
    corepack enable
    pnpm install
    ```
*   Führen Sie beide Services (Frontend & Backend) parallel aus dem Stammverzeichnis aus:
    ```bash
    pnpm dev
    ```
*   **Port-Belegung**:
    *   Nuxt Frontend: `http://localhost:3000`
    *   FastAPI Backend: `http://localhost:8000` (Swagger UI: `/docs`)

---

## 6.2 Deployment via Podman

Die lokale Kapselung in Containern erfolgt über das native **Podman**-Setup ohne Docker Compose über das Steuerungsskript `run-podman.sh`.

#### Wichtige Befehle:

1.  **Container-Bilder bauen**:
    ```bash
    pnpm run podman:build
    # oder direkt:
    ./run-podman.sh build
    ```
2.  **Container starten**:
    ```bash
    pnpm run podman:up
    # oder direkt:
    ./run-podman.sh up
    ```
    *   Erstellt automatisch die Ressourcen `nofoodwaste-net` (Podman-Netzwerk) und `nofoodwaste-sqlite` (persistentes Volume für die SQLite-Datenbank).
3.  **Container stoppen**:
    ```bash
    pnpm run podman:down
    # oder direkt:
    ./run-podman.sh down
    ```
4.  **Status & Protokolle (Logs) prüfen**:
    ```bash
    pnpm run podman:status
    pnpm run podman:logs
    ```
