# Technical Specification: Architecture

## Systemdiagramm & Technologie
Das System ist in ein dediziertes Frontend und Backend getrennt (Monorepo-Ansatz).

- **Frontend:** Nuxt 4 & TailwindCSS 4 (located in `Apps/Frontend`)
- **Backend:** Python (FastAPI, located in `Apps/Backend`)
  - **Verantwortlichkeiten:**
    - Inventar speichern (CRUD für Lebensmittel)
    - Verfallsprüfung
    - **LLM Integration:** Utilizes OpenAI's **Structured Outputs** feature (via Pydantic) to ensure highly reliable, schema-validated JSON responses for recipe generation.
- **Package Manager:** `pnpm` (Workspace setup)

## Speicherung (Datenbank)

### MVP-Phase
- **Datenbanksystem:** SQLite
- Leichtgewichtig und ohne externen Server aufsetzbar.

### Skalierung (Später)
- **Datenbanksystem:** PostgreSQL

## Nichtfunktionale Anforderungen

| Bereich | Ziel |
|---|---|
| Antwortzeit | < 10 Sekunden (insbesondere für LLM-Aufruf) |
| Mobile UX | hochgradig optimiert (Mobile First) |
| Accessibility | grundlegende Kontraste (AA) |
| JSON-Validierung | verpflichtend für jede LLM-Antwort |
| Fehlerhandling | verständliche, nutzerzentrierte Meldungen (UI) |
