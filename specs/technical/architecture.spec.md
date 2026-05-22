# Technical Specification: Architecture

## Systemdiagramm & Technologie
Das System ist in ein dediziertes Frontend und Backend getrennt, organisiert in einem modernen Monorepo-Ansatz via `pnpm` Workspaces.

- **Frontend:** Nuxt 4 & TailwindCSS 4 (Pfad: `Apps/Frontend`)
  - **Verantwortlichkeiten:**
    - Erfassung und Verwaltung von Lebensmitteln (CRUD-Interaktion)
    - Präsentation der Lebensmittelbestände mit farblicher Warnlogik nach MHD
    - Interaktive Zutatenauswahl und Abfrage der Rezeptgenerierung
    - Rendering der Rezeptkarten ("Card-based Action UI") mit Match-Prozenten
- **Backend:** Python (FastAPI, Pfad: `Apps/Backend`)
  - **Verantwortlichkeiten:**
    - REST-API für Lebensmittel (CRUD-Endpoints) und Datenbank-Interaktion
    - Lokale Verfallsprüfung der Bestände
    - **Agentengestützte KI-Integration:** Utilizes **Google ADK (Agent Development Kit) 2.0** with **Gemini 2.5 Flash** (via `LLM_MODEL`). 
      - Der Rezept-Agent (`cook_agent`) läuft gekapselt im `InMemoryRunner`.
      - **Structured Outputs:** Pydantic-Modelle erzwingen standardisierte JSON-Antworten direkt auf Provider-Ebene.
      - **Robustness Layer:** Lokales Python-Post-Processing (in `llm_service.py`) zur Normalisierung ungenauer Modellwerte (z. B. `matchScore` Begrenzung auf `[0.0, 1.0]`).
- **Package Manager:** `pnpm` (Workspace setup)

## Speicherung (Datenbank)

### MVP-Phase
- **Datenbanksystem:** SQLite (`food_waste.db`)
- **Vorteil:** Leichtgewichtig, dateibasiert, automatisch initialisiert bei Applikationsstart (in `database.py`), ideal für die Entwicklung und Schulungen ohne externe Infrastruktur.

### Skalierung (Später)
- **Datenbanksystem:** PostgreSQL (z. B. via Firebase Data Connect oder gehostete SQL-Instanz)

## Nichtfunktionale Anforderungen

| Bereich | Ziel | Umsetzung |
|---|---|---|
| **Antwortzeit** | < 10 Sekunden (insbesondere für LLM-Aufruf) | Asynchrone Abfrage über Gemini 2.5 Flash (mittels Google ADK) |
| **Mobile UX** | hochgradig optimiert (Mobile First) | Responsive CSS-Layouts exakt nach den Vorgaben der Design-Spec |
| **Accessibility** | grundlegende Kontraste (AA) | Kontraststarke Farben basierend auf den Einstein-Design-Tokens |
| **JSON-Validierung** | Verpflichtend für jede LLM-Antwort | Pydantic-Schema-Erzwingung (`RecipeResponse`) auf Provider-Ebene via ADK 2.0 |
| **Fehlerhandling** | Verständliche, nutzerzentrierte Meldungen (UI) | API-Fehler (z. B. 500er LLM-Exceptions) werden im Frontend abgefangen und nutzerfreundlich ausgegeben |
| **Sicherheit** | Schutz vor Prompt-Injection & Jailbreaks | Kapselung des Agenten-Verhaltens durch isolierte Systemgrenzen und automatische Leerrückgabe bei Missbrauch |
