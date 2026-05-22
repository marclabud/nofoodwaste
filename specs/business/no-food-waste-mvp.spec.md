# Business Specification: Food-Waste Recipe Finder MVP

## Ziel

Ein Benutzer verwaltet vorhandene Lebensmittel mit Mengen und Verfalldaten.

Das System:
- speichert Lebensmittel,
- verhindert die Nutzung verfallener Lebensmittel,
- sendet gültige Lebensmittel an einen intelligenten Rezept-Agenten (Google ADK 2.0 / Gemini 2.5 Flash),
- erhält 1–3 strukturierte, typensichere Rezeptvorschläge,
- zeigt diese in einer klaren Food-Waste-orientierten Oberfläche an.

Das System ist:
- mobile-first,
- LLM-zentriert,
- bewusst einfach gehalten,
- ohne klassische Rezeptdatenbank im MVP.

## Functional Scope

### Enthalten im MVP
```text
✓ Lebensmittel erfassen
✓ Lebensmittel speichern
✓ Lebensmittel bearbeiten
✓ Verfallsprüfung
✓ Zutaten auswählen
✓ Agentengestützte Rezeptgenerierung (Google ADK 2.0)
✓ Rezeptanzeige
✓ Food-Waste-Hinweise
```

### Nicht im MVP
```text
✗ Benutzerkonten
✗ Barcode-Scanner
✗ Einkaufsliste
✗ Allergene
✗ Nutrition Tracking
✗ RAG-Datenbank
✗ Multi-User
✗ Social Features
✗ Rezept speichern
```

## Benutzerfluss

```text
1. Lebensmittel erfassen
2. Lebensmittel speichern
3. Verfallene Lebensmittel werden deaktiviert
4. Benutzer wählt Zutaten
5. Zutaten werden an den Rezept-Agenten gesendet
6. Der Agent liefert 1–3 strukturierte Rezepte zurück
7. Rezepte werden als Karten angezeigt
```

## Fachliche Datenmodelle

### Ingredient
```ts
type Ingredient = {
  id: string
  name: string
  quantity: number
  unit: "g" | "kg" | "ml" | "l" | "piece"
  expiresAt: string
  createdAt: string
}
```

### Recipe
```ts
type Recipe = {
  title: string
  matchScore: number // Dezimalwert zwischen 0.0 und 1.0 (wird im Backend auf dieses Intervall normalisiert)
  foodWastePriorityReason: string
  estimatedTimeMinutes: number
  usedIngredients: string[]
  missingRequiredIngredients: string[]
  optionalIngredients: string[]
  steps: string[]
  explanation: string
}
```

## Geschäftsregeln: Agenten-Verhalten & Match-Score

### Berechnung des Match-Scores
Der Match-Score wird nicht über eine starre mathematische Formel berechnet, sondern vom Rezept-Agenten (Gemini 2.5 Flash) semantisch geschätzt. Dabei gelten folgende Kriterien:
1. **Zutaten-Abdeckung:** Verhältnis zwischen den vom Benutzer bereitgestellten (verwendeten) Zutaten und den zusätzlich benötigten Pflichtzutaten.
2. **Food-Waste-Priorisierung:** Ein Bonus fließt in den Score ein, wenn Zutaten mit sehr nahem Verfallsdatum vollständig verwertet werden.
3. **Normalisierung:** Der Score wird im Backend robust validiert und auf einen Wert zwischen `0.0` und `1.0` normalisiert (z. B. `0.95` für 95% Match), damit das Frontend ihn verlässlich rendern kann.

### Prompt-Security & Leitplanken des Agenten
Der Rezept-Agent (`cook_agent`) ist durch ein strukturiertes System-Prompt (`system_recipe_assistant.md`) abgesichert:
* **Themenfokus:** Er beantwortet ausschließlich Anfragen im Kontext von Kochen, Rezepten und Lebensmitteln.
* **Jailbreak-Schutz:** Systemanweisungen können nicht durch Benutzereingaben überschrieben werden.
* **Schadcode-Schutz:** Bei unsinnigen, schädlichen oder themenfremden Eingaben führt der Agent keine Aktionen aus und liefert ein leeres Rezept-Array zurück.

## Geschäftsregeln: Verfallslogik

### Regel
Ein Lebensmittel gilt als verfallen wenn:
```ts
expiresAt < today
```

### Verhalten
| Zustand | Verhalten |
|---|---|
| gültig | auswählbar |
| läuft heute ab | auswählbar + Warnung |
| verfallen | deaktiviert |

## UI-Konzept & Layouts

### Hauptseite Layout
```text
┌──────────────────────────┐
│ Meine Lebensmittel       │
├──────────────────────────┤
│ Zutatenliste             │
│ + Neues Lebensmittel     │
├──────────────────────────┤
│ Rezeptvorschläge finden  │
└──────────────────────────┘
```

### Lebensmittelkarte
```text
🍅 Tomaten
4 Stück
Gültig bis 20.05.2026
```
| Zustand | Statusfarbe |
|---|---|
| gültig | grün |
| bald ablaufend | orange |
| verfallen | grau/rot |

### Zutatenauswahl
Nur gültige Lebensmittel: `✓ auswählbar`
Verfallene Lebensmittel: `✗ deaktiviert`

## Rezeptausgabe (UI & UX)

### Designprinzip
Die Rezeptausgabe verwendet: `Card-based Action UI`
Ziel: schnelle Entscheidung, hohe Lesbarkeit, sichtbare Food-Waste-Priorisierung.

### Rezeptkarten-Layout
```text
┌──────────────────────────────┐
│ 🍅 Rezepttitel               │
│ Match-Score                  │
│ Food-Waste-Hinweis           │
│ Kochzeit                     │
├──────────────────────────────┤
│ Verwendete Zutaten           │
│ Fehlende Zutaten             │
│ Optionale Zutaten            │
├──────────────────────────────┤
│ Kochschritte                 │
├──────────────────────────────┤
│ Aktionen                     │
└──────────────────────────────┘
```

### Beispielhafter Inhalt der Rezeptkarte
```text
🍅 Gebratener Reis mit Tomaten und Ei
92 % Zutaten-Match
⚠ Nutzt Eier, die morgen ablaufen
⏱ 25 Minuten

Verwendete Zutaten:
✓ Tomaten, ✓ Reis, ✓ Eier

Fehlende Zutaten:
- Öl, - Salz, - Pfeffer

Kochschritte:
1. Reis kochen
2. Tomaten würfeln
3. Eier verquirlen
...

Aktionen:
[ Jetzt kochen ]
```

### Erklärung des Vorschlags
Der Benutzer soll verstehen: *Warum wurde dieses Rezept vorgeschlagen?*
Beispiel: Dieses Rezept wurde gewählt, weil alle Eier verwendet werden, 92% der Zutaten genutzt werden und keine zusätzlichen Einkäufe nötig sind.

## MVP-Ziel
Das MVP soll beweisen: **Kann ein LLM aus vorhandenen Zutaten sinnvoll Food-Waste-orientierte Rezepte erzeugen?**
Nicht Ziel: perfekte Kochplattform.
Sondern: schnelle nachhaltige Entscheidungsunterstützung.
