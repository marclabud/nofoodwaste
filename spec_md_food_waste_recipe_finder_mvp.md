# SPEC.MD

# Food-Waste Recipe Finder — MVP Spezifikation

## Ziel

Ein Benutzer verwaltet vorhandene Lebensmittel mit Mengen und Verfalldaten.

Das System:
- speichert Lebensmittel,
- verhindert die Nutzung verfallener Lebensmittel,
- sendet gültige Lebensmittel an ein LLM,
- erhält 1–3 Rezeptvorschläge,
- zeigt diese in einer klaren Food-Waste-orientierten Oberfläche an.

Das System ist:
- mobile-first,
- LLM-zentriert,
- bewusst einfach gehalten,
- ohne klassische Rezeptdatenbank im MVP.

# Functional Scope

## Enthalten im MVP

```text
✓ Lebensmittel erfassen
✓ Lebensmittel speichern
✓ Verfallsprüfung
✓ Zutaten auswählen
✓ LLM-Rezeptsuche
✓ Rezeptanzeige
✓ Food-Waste-Hinweise
```

## Nicht im MVP

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

# Benutzerfluss

```text
1. Lebensmittel erfassen
2. Lebensmittel speichern
3. Verfallene Lebensmittel werden deaktiviert
4. Benutzer wählt Zutaten
5. Zutaten werden an LLM gesendet
6. LLM liefert 1–3 Rezepte
7. Rezepte werden als Karten angezeigt
```

# Datenmodell

## Ingredient

```ts
type Ingredient = {
  id: string

  name: string

  quantity: number

  unit:
    | "g"
    | "kg"
    | "ml"
    | "l"
    | "piece"

  expiresAt: string

  createdAt: string
}
```

## Recipe

```ts
type Recipe = {
  title: string

  matchScore: number

  foodWastePriorityReason: string

  estimatedTimeMinutes: number

  usedIngredients: string[]

  missingRequiredIngredients: string[]

  optionalIngredients: string[]

  steps: string[]

  explanation: string
}
```

# Verfallslogik

## Regel

Ein Lebensmittel gilt als verfallen wenn:

```ts
expiresAt < today
```

## Verhalten

| Zustand | Verhalten |
|---|---|
| gültig | auswählbar |
| läuft heute ab | auswählbar + Warnung |
| verfallen | deaktiviert |

## Beispiel

```text
Tomaten
✓ auswählbar

Eier
⚠ laufen heute ab

Milch
✗ verfallen
```

# UI-Spezifikation

# Hauptseite

## Layout

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

# Lebensmittelkarte

## Darstellung

```text
🍅 Tomaten
4 Stück
Gültig bis 20.05.2026
```

## Statusfarben

| Zustand | Farbe |
|---|---|
| gültig | grün |
| bald ablaufend | orange |
| verfallen | grau/rot |

# Zutatenauswahl

## Verhalten

Nur gültige Lebensmittel:

```text
✓ auswählbar
```

Verfallene Lebensmittel:

```text
✗ deaktiviert
```

# Rezeptausgabe

## Designprinzip

Die Rezeptausgabe verwendet:

```text
Card-based Action UI
```

Ziel:
- schnelle Entscheidung,
- hohe Lesbarkeit,
- mobile Optimierung,
- sichtbare Food-Waste-Priorisierung.

# Rezeptkarten-Layout

## Gesamtaufbau

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

# Rezeptkarten-Inhalt

## Kopfbereich

```text
🍅 Gebratener Reis mit Tomaten und Ei

92 % Zutaten-Match

⚠ Nutzt Eier, die morgen ablaufen

⏱ 25 Minuten
```

# Zutatenbereiche

## Verwendete Zutaten

```text
✓ Tomaten
✓ Reis
✓ Eier
```

## Fehlende Zutaten

```text
Fehlt:
- Öl
- Salz
- Pfeffer
```

## Optionale Zutaten

```text
Optional:
- Frühlingszwiebeln
- Sojasauce
```

# Kochschritte

## Darstellung

Kurze nummerierte Schritte:

```text
1. Reis kochen
2. Tomaten würfeln
3. Eier verquirlen
4. Alles anbraten
5. Würzen und servieren
```

# Erklärung

## Zweck

Der Benutzer soll verstehen:

```text
Warum wurde dieses Rezept vorgeschlagen?
```

## Beispiel

```text
Dieses Rezept wurde gewählt, weil:
- alle Eier verwendet werden
- 92 % der Zutaten genutzt werden
- keine zusätzlichen Einkäufe nötig sind
```

# Aktionen

## Buttons

```text
[ Jetzt kochen ]
```

# Mobile Verhalten

## Mobile First

Rezepte werden:

```text
vertikal gestapelt
```

## Desktop

Optionales Grid:

```text
2 Karten nebeneinander
```

# LLM-Integration

# Ziel

Das LLM übernimmt:

```text
✓ Zutatenmatching
✓ Rezeptfindung
✓ Priorisierung
✓ Rezeptformulierung
```

# Prompt

```text
Du bist ein Rezeptassistent für Food-Waste-Reduktion.

Aufgabe:
Finde 1 bis 3 einfache Rezepte auf Basis vorhandener Lebensmittel.

Regeln:
- Nutze möglichst viele vorhandene Lebensmittel.
- Bevorzuge Lebensmittel mit nahem Verfalldatum.
- Nutze keine verfallenen Lebensmittel.
- Nenne fehlende Pflichtzutaten separat.
- Nenne optionale Zutaten separat.
- Gib kurze Kochschritte.
- Antworte ausschliesslich als valides JSON.
```

# LLM-Input

## Beispiel

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
      "name": "Reis",
      "quantity": 500,
      "unit": "g",
      "expiresAt": "2026-06-30"
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

# Erwartete LLM-Ausgabe

```json
{
  "recipes": [
    {
      "title": "Gebratener Reis mit Tomaten und Ei",
      "matchScore": 0.92,
      "foodWastePriorityReason": "Eier laufen morgen ab.",
      "estimatedTimeMinutes": 25,
      "usedIngredients": [
        "Tomaten",
        "Reis",
        "Eier"
      ],
      "missingRequiredIngredients": [
        "Öl",
        "Salz",
        "Pfeffer"
      ],
      "optionalIngredients": [
        "Frühlingszwiebeln",
        "Sojasauce"
      ],
      "steps": [
        "Reis kochen.",
        "Tomaten würfeln.",
        "Eier verquirlen.",
        "Alles gemeinsam anbraten.",
        "Mit Salz und Pfeffer würzen."
      ],
      "explanation": "Das Rezept verwendet alle Eier und benötigt kaum zusätzliche Zutaten."
    }
  ]
}
```

# Backend-Validierung

## Vor LLM-Aufruf

```text
- mindestens 1 Zutat
- keine verfallenen Zutaten
- Mengen > 0
```

## Nach LLM-Aufruf

```text
- valides JSON
- 1–3 Rezepte
- Titel vorhanden
- Schritte vorhanden
- Arrays korrekt
```

# Technologievorschlag

# Frontend

Empfohlen:

```text
Nuxt 4
Tailwind CSS v4
```

## Komponenten

```text
IngredientCard
IngredientSelector
RecipeCard
RecipeList
```

# Backend

Empfohlen:

```text
FastAPI
```

## Verantwortlichkeiten

```text
- Inventar speichern
- Verfallsprüfung
- LLM-Aufruf
- JSON-Validierung
```

# Speicherung

## MVP

```text
SQLite
```

Später:

```text
PostgreSQL
```

# API-Endpunkte

## Lebensmittel

```http
POST /ingredients
GET /ingredients
DELETE /ingredients/:id
```

## Rezepte

```http
POST /recipes/generate
```

# Nichtfunktionale Anforderungen

| Bereich | Ziel |
|---|---|
| Antwortzeit | < 10 Sekunden |
| Mobile UX | optimiert |
| Accessibility | grundlegende Kontraste |
| JSON-Validierung | verpflichtend |
| Fehlerhandling | verständliche Meldungen |

# MVP-Ziel

Das MVP soll beweisen:

```text
Kann ein LLM aus vorhandenen Zutaten sinnvoll Food-Waste-orientierte Rezepte erzeugen?
```

Nicht Ziel:

```text
perfekte Kochplattform
```

Sondern:

```text
schnelle nachhaltige Entscheidungsunterstützung
```

