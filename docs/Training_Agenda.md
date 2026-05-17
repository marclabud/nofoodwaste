# Umsetzungsplan Schulung: Spec-Driven Softwareentwicklung

Dieser Plan führt die Teilnehmer schrittweise durch den Spec-Driven-Ansatz, vom manuellen Setup bis hin zur KI-gestützten, vertikalen Feature-Entwicklung anhand des "Food-Waste Recipe Finder" Beispiels.

---

## Modul 1A: Das Fundament (Die Spec)
Das Ziel dieses Moduls ist es, die Basis für die reibungslose Zusammenarbeit zwischen Entwicklern und KI-Agenten zu schaffen.

* **Spec-Driven Basis:** Gemeinsames Erstellen der Spezifikation als `.md` Datei (Single Source of Truth).
* **Design & Styling Spec:** 
  * Erstellen von Tailwind-Tokens als Teil der Spezifikation (Fokus auf Farben).
  * Design-Spezifikationen anlegen: `srf-einstein.md` und `einstein-tokens.json`.

## Modul 1B: Projekt-Setup (Monorepo)
Nachdem die Spezifikation steht, wird das Projekt aufgesetzt. Um Frontend und Backend sauber zu trennen, wählen wir einen Monorepo-Ansatz.

### Verzeichnisstruktur
Überblick über die geplante Architektur:

```text
NoFoodWaste/
├── package.json           # Root Konfiguration (pnpm workspaces)
├── spec.md                # Die Spezifikation
├── docs/                  # Dokumentation & Design Tokens
│   ├── srf-einstein.md
│   └── einstein-tokens.json
└── Apps/
    ├── Frontend/          # Nuxt 4 Projekt
    │   └── package.json
    └── Backend/           # Python FastAPI Projekt
        ├── main.py
        └── requirements.txt
```

### Konfigurationsdateien

**1. Projekt Root (`/package.json`)**
Definiert die Workspaces (Monorepo-Verwaltung):
```json
{
  "name": "ws-labud-informatik",
  "private": true,
  "workspaces": [
    "Apps/*
  ],
  "packageManager": "pnpm@10.33.0",
  "scripts": {
    "dev": "pnpm -r dev",
    "build": "pnpm -r build"
  }
}
```

**2. Frontend (`/Apps/Frontend/package.json`)**
Das eigentliche Frontend-Projekt (vereinfachter Auszug für die Schulung):
```json
{
  "name": "frontend",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "nuxt dev",
    "build": "nuxt build"
  },
  "dependencies": {
    "@nuxt/ui": "^4.2.1",
    "nuxt": "^4.2.2"
  }
}
```

## Modul 2: Vertikale Feature-Entwicklung (CRUD)
In diesem Modul setzen wir die ersten Kernfunktionen der Spec von der Datenbank bis zur Benutzeroberfläche um.

* **Schritt 1: Lebensmittel anlegen**
  * Vertikale Umsetzung (Frontend bis Backend).
  * Fokus auf das Einhalten der in der Spec definierten Datenmodelle.
* **Schritt 2: Lebensmittel ändern**
  * Iteratives Erweitern der bestehenden Logik (z. B. Verfallslogik anpassen).

## Modul 3: LLM-Integration (KI als Feature)
Hier integrieren wir die eigentliche "Intelligenz" der Applikation und lernen, wie LLMs sicher und strukturiert in eine klassische Architektur eingebettet werden.

* **Schritt 3: LLM-Abfrage auf Rezepte einbauen**
  * Backend-Logik für die OpenAI-Anbindung.
  * Prompts auslagern und härten (Prompt Security).
  * *Schema over Prompt:* Nutzung von Pydantic und Structured Outputs, um valides JSON für die Rezepte zu erzwingen.

## Modul 4: Frontend Vollendung
Zum Abschluss wird das Ergebnis der KI im Frontend nutzbar gemacht.

* **Schritt 4: Rezepte anzeigen bauen**
  * Das Frontend nutzt die vom LLM generierten und vom Backend validierten strukturierten Daten.
  * Bau der UI-Komponenten (Card-based Action UI) exakt nach den Vorgaben der Markdown-Spezifikation.
