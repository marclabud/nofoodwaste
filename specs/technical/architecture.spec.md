# Technical Specification: Architecture

## Systemdiagramm & Technologie
Das System ist in ein dediziertes Frontend und Backend getrennt (Monorepo-Ansatz).

### Frontend
- **Framework:** Nuxt 4 (Vue)
- **Styling:** Tailwind CSS v4

### Backend
- **Framework:** FastAPI (Python)
- **Verantwortlichkeiten:**
  - Inventar speichern (CRUD für Lebensmittel)
  - Verfallsprüfung
  - LLM-Aufruf an Provider (OpenAI)
  - JSON-Validierung

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
