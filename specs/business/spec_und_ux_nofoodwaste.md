# Spec und UX — NoFoodWaste

# 1. Produktvision

„NoFoodWaste“ ist eine mobile Anwendung zur Reduktion von Lebensmittelverschwendung im privaten Haushalt.

Benutzer erfassen ihre vorhandenen Lebensmittel inklusive:

- Name
- Menge
- Einheit
- Verfallsdatum

Die Anwendung analysiert anschließend die verfügbaren Zutaten und generiert mithilfe eines AI-Agenten drei passende Rezeptvorschläge.

Ziel:

- Lebensmittel vor Ablauf verbrauchen
- einfache Rezeptideen liefern
- spontane Resteverwertung unterstützen
- Foodwaste reduzieren

Die Anwendung ist mobile-first konzipiert.

# 2. Kernfunktionen

## 2.1 Lebensmittel erfassen

Benutzer können neue Lebensmittel erfassen.

### Eingabefelder

| Feld          | Typ     | Pflicht |
| ------------- | ------- | ------- |
| Name          | Text    | Ja      |
| Menge         | Zahl    | Ja      |
| Einheit       | Auswahl | Ja      |
| Verfallsdatum | Datum   | Ja      |

### Unterstützte Einheiten

- Stück
- g
- kg
- ml
- l

### Verhalten

- Lebensmittel werden sofort gespeichert
- Nach dem Speichern erscheint das Lebensmittel in der Liste
- Das Formular kann ein- und ausgeklappt werden

# 3. Lebensmittel-Liste

Die Anwendung zeigt alle vorhandenen Lebensmittel in einer Liste.

## Pro Lebensmittel sichtbar

- Name
- Menge + Einheit
- Verfallsdatum

## Aktionen

| Aktion     | Beschreibung           |
| ---------- | ---------------------- |
| Bearbeiten | Lebensmittel anpassen  |
| Löschen    | Lebensmittel entfernen |

## Sortierung

Die Liste wird standardmäßig sortiert nach:

1. bald ablaufende Lebensmittel
2. alphabetisch

# 4. Rezeptsuche

Benutzer können basierend auf vorhandenen Zutaten Rezeptideen generieren.

## Verhalten

- Die Rezeptgenerierung wird manuell gestartet
- Die Anwendung analysiert alle vorhandenen Lebensmittel
- Genau drei Rezepte werden generiert

## Ziel

Die Rezepte sollen:

- möglichst viele vorhandene Zutaten verwenden
- bald ablaufende Zutaten priorisieren
- realistisch kochbar sein
- einfache Alltagsgerichte darstellen

# 5. AI-Agent „Koch“

## Rolle des AI-Agenten

Der AI-Agent verhält sich wie:

- ein pragmatischer Koch
- ein Foodwaste-Berater
- ein kreativer Resteverwerter

Der Agent arbeitet natürlichsprachig.

## Ziele des Agenten

Der Agent soll:

- Foodwaste minimieren
- vorhandene Zutaten priorisieren
- möglichst vollständige Verwertung fördern
- einfache Rezeptideen liefern
- unnötige zusätzliche Zutaten vermeiden

## Ausgabeformat

Der Agent liefert genau drei Rezepte.

Pro Rezept:

| Feld               | Beschreibung                    |
| ------------------ | ------------------------------- |
| Titel              | Name des Rezepts                |
| Match Score        | Passung der vorhandenen Zutaten |
| Zeit               | Geschätzte Zubereitungszeit     |
| Foodwaste-Hinweis  | Warum das Rezept sinnvoll ist   |
| Verwendete Zutaten | Vorhandene Zutaten              |
| Fehlende Zutaten   | Zusätzlich benötigte Zutaten    |
| Optionale Zutaten  | Erweiterungen                   |
| Schritte           | Kochanleitung                   |

# 6. UX- und Designvision

Die Anwendung soll sich anfühlen wie:

- ein intelligenter Küchenassistent
- eine hochwertige moderne Consumer-App
- ruhig, klar und vertrauenswürdig
- AI-unterstützt ohne „techy“ zu wirken

Der visuelle Charakter kombiniert:

- Minimalismus
- Food-Emotion
- moderne Kartenlayouts
- subtile AI-Ästhetik
- ruhige Farbflächen
- starke Typografie

Das Ziel ist:

„Lebensmittel retten soll sich gut anfühlen.“

# 7. Designprinzipien

## 7.1 Mobile First

Die gesamte UX wird primär für Smartphones entworfen.

Optimierung für:

- Thumb Navigation
- vertikales Scrollen
- große Touch-Flächen
- schnelle Eingabe

## 7.2 Ruhe statt Überladung

Die Überarbeitung reduziert:

- harte Rahmen
- starke Linien
- visuelles Rauschen

Mehr Fokus auf:

- Weißraum
- Typografie
- weiche Layer
- Karten statt Borders

## 7.3 Emotionalisierung

Foodwaste ist emotional.

Die App soll:

- positiv motivieren
- frisch wirken
- gesund wirken
- modern wirken

Nicht:

- technisch kalt
- warnend
- moralisch belehrend

# 8. Farbkonzept

## Background

```txt
#F7F5F2
```

## Surface

```txt
#FFFFFF
```

## Primary

```txt
#D84C3F
```

## Secondary

```txt
#6BA368
```

## Accent

```txt
#F4A261
```

## Text Primary

```txt
#1F1F1F
```

## Text Secondary

```txt
#666666
```

# 9. Typografie

## Primärschrift

Inter

## Typografische Hierarchie

### Hero

```txt
40–48px
Bold
```

### Section Titles

```txt
28–32px
Bold
```

### Card Titles

```txt
22–24px
SemiBold
```

### Body

```txt
16–18px
Regular
```

### Meta Information

```txt
14px
Medium
```

# 10. Layoutsystem

## Grid

```txt
4px Base Grid
16px Side Padding
24px Vertical Rhythm
```

## Karten

Die App basiert vollständig auf:

- Soft Cards
- Floating Sections
- Depth through Shadows

Keine starken roten Borders mehr.

## Shadow System

```css
box-shadow:
0 2px 10px rgba(0,0,0,0.04);
```

# 11. Lebensmittel-Liste UX

## Neue Gestaltung

Neue Gestaltung:

- weiße Floating Cards
- soft shadows
- farbige Ablaufindikatoren

## Priorisierung durch Farbe

### Frisch

Soft Green Accent

### Bald ablaufend

Warm Orange

### Kritisch

Soft Red

# 12. Add-Food-Formular

## Ziel

Das Formular soll:

- leicht wirken
- nicht wie ein Adminpanel
- wie ein moderner Mobile Flow

## Struktur

Nicht als harter Kasten.

Sondern:

- Bottom Sheet oder
- Expandable Card

## CTA Button

```txt
Lebensmittel speichern
```

# 13. Rezeptkarten

## Neue Richtung

Die Rezeptkarten werden zum emotionalen Zentrum der Anwendung.

## Kartenaufbau

### Header

- Rezeptname
- Match Score
- Zeit

### AI Insight Box

Beispiel:

```txt
„Verwendet alle frischen Zutaten vor Ablauf.“
```

### Zutatenbereiche

#### Verwendet

Grün

#### Fehlt noch

Neutral

#### Optional

Secondary Text

### CTA

```txt
Rezept ansehen
```

# 14. AI-Interaktionsgefühl

Die AI soll nicht wie:

- Chatbot
- technische KI

wirken.

Sondern wie:

- intelligenter Kochassistent

## Sprachstil

- kurz
- pragmatisch
- positiv

Nicht:

- generisch
- übererklärend
- künstlich enthusiastisch

# 15. Accessibility

- große Touch Targets
- hoher Kontrast
- klare Typografie
- keine rein farbbasierte Bedeutung
- gute Lesbarkeit bei Tageslicht

# 16. MVP-Abgrenzung

## Im MVP enthalten

- Lebensmittel erfassen
- Lebensmittel bearbeiten/löschen
- Verfallsdaten
- AI-Rezeptgenerierung
- genau 3 Rezepte
- mobile UI

## Nicht im MVP

- Login
- Cloud Sync
- Scanner
- Favoriten
- Bewertungen
- Sharing
- Mehrbenutzerbetrieb
- Offline-Modus
- Einkaufslisten

# 17. Zielwirkung

Die App soll sich anfühlen wie:

```txt
ruhig
modern
intelligent
hilfreich
leichtgewichtig
hochwertig
food-orientiert
```

Nicht wie:

```txt
ERP
Formularsoftware
Adminpanel
klassische CRUD-App
```

