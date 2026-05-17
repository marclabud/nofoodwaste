# Technical Specification: LLM Integration

## Ziel
Das LLM übernimmt im System:
- Zutatenmatching
- Rezeptfindung
- Food-Waste-Priorisierung
- Rezeptformulierung

## Modell Konfiguration
- **Provider:** OpenAI
- **Modell:** `chatgpt-5.2` (oder konfigurierbares Modell über Umgebungsvariable `LLM_MODEL`)
- **Parameter:** `instant: True`
- **Authentifizierung:** API-Key wird sicher im Backend verarbeitet (niemals im Frontend).

## Prompt

Der System-Prompt ist (gemäß `system_recipe_assistant.md`):
```text
Du bist ein strenger Rezeptassistent für Food-Waste-Reduktion.
Deine EINZIGE Aufgabe ist es, 1 bis 3 einfache Rezepte auf Basis der bereitgestellten Lebensmittel zu generieren.

Regeln:
- Nutze möglichst viele vorhandene Lebensmittel.
- Bevorzuge Lebensmittel mit nahem Verfalldatum.
- Nutze keine verfallenen Lebensmittel.
- Nenne fehlende Pflichtzutaten separat.
- Nenne optionale Zutaten separat.
- Gib kurze Kochschritte.
... (Sicherheitsrichtlinien & Systemgrenzen einhalten)
```

## I/O Beispiele (JSON)

### Erwarteter LLM-Input
```json
{
  "ingredients": [
    {
      "name": "Tomaten",
      "quantity": 4,
      "unit": "piece",
      "expiresAt": "2026-05-20"
    },
    {
      "name": "Eier",
      "quantity": 6,
      "unit": "piece",
      "expiresAt": "2026-05-18"
    }
  ]
}
```

### Erwartete LLM-Ausgabe (via Structured Outputs)
```json
{
  "recipes": [
    {
      "title": "Gebratener Reis mit Tomaten und Ei",
      "matchScore": 0.92,
      "foodWastePriorityReason": "Eier laufen morgen ab.",
      "estimatedTimeMinutes": 25,
      "usedIngredients": ["Tomaten", "Eier"],
      "missingRequiredIngredients": ["Öl", "Salz", "Reis"],
      "optionalIngredients": ["Frühlingszwiebeln"],
      "steps": [
        "Tomaten würfeln.",
        "Eier verquirlen.",
        "Alles anbraten."
      ],
      "explanation": "Das Rezept verwendet alle Eier und verhindert so Verderb."
    }
  ]
}
```
