# Git-Starter-Template: Monorepo & Agentic AI Blueprint

Dieses Dokument beschreibt die Struktur und den Inhalt eines **standardisierten Git-Starter-Templates**. Der Projektarchitekt nutzt dieses Template, um innerhalb weniger Minuten ein neues, stabiles Monorepo aufzusetzen, das perfekt für die nachfolgende, autonome Entwicklung durch **Antigravity 2.0-Agenten** vorbereitet ist.

---

## 1. Verzeichnisstruktur des Starter-Templates

Das Starter-Template enthält im Git-Repository bereits die vollständige Verzeichnisstruktur mitsamt leeren Platzhaltern für Backend und Frontend, um dem Agenten von Anfang an feste Pfade vorzugeben.

```text
<template-root>/
├── Apps/
│   ├── Frontend/             # Leerer Ordner oder minimales Nuxt-Skelett
│   └── Backend/              # Leerer Ordner oder minimales Python-Skelett
├── specs/
│   ├── business/
│   │   └── business-spec.md  # Leere Vorlage für fachliche Spezifikation (mit TOC)
│   └── technical/            # Technische Richtlinien
├── docs/
│   └── Antigravity_Agent_Context.md # Onboarding-Leitplanken für Agenten
├── package.json              # Zentrale Paketmanager-Verwaltung (Corepack)
├── pnpm-workspace.yaml       # pnpm Workspace-Konfiguration
└── .gitignore                # Standard-Ausschlüsse für Node, Python, SQLite & OS-Dateien
```

---

## 2. Root-Konfigurationsdateien

Diese Dateien liegen direkt im Stammverzeichnis des Templates und garantieren ein einheitliches Build- und Paketmanagement.

### 2.1 `package.json` (mit Corepack & Scripts)
Diese Konfiguration nagelt den Paketmanager via **Corepack** fest und stellt dem Agenten globale Steuerungsskripte zur Verfügung.

```json
{
  "name": "project-starter-monorepo",
  "version": "1.0.0",
  "private": true,
  "packageManager": "pnpm@10.33.0",
  "engines": {
    "node": ">=24.0.0",
    "pnpm": ">=10.33.0"
  },
  "scripts": {
    "dev": "pnpm -r dev",
    "build": "pnpm -r build",
    "lint": "pnpm -r lint",
    "test": "pnpm -r test",
    "clean": "pnpm -r clean"
  }
}
```

### 2.2 `pnpm-workspace.yaml`
Konfiguriert `pnpm`, um alle Ordner unter `Apps/` als eigenständige Workspace-Pakete zu behandeln.

```yaml
packages:
  - "Apps/*"
```

---

## 3. Vorlage: `specs/business/business-spec.md`
*(Vom Architekten auszufüllen)*

Diese Datei dient dem Agenten als **Single Source of Truth** für alle fachlichen Regeln und UI-Vorgaben. Sie enthält bereits das folgende Inhaltsverzeichnis (TOC) mitsamt Strukturhinweisen:

```markdown
# Business & UX Specification: [Projektname] MVP

## 1. Produktvision & Ziele
- [Kurzbeschreibung des Produkts: Welches Problem wird gelöst?]
- [Zielgruppe und Kernnutzen]
- [MVP-Ziel: Was soll in dieser ersten Phase bewiesen werden?]
- [Plattform-Ausrichtung: z.B. Mobile-First, Web-only, Desktop-first]

## 2. Functional Scope (Funktionsumfang)
- [✓ Enthalten im MVP (Aufzählung der Features)]
- [✗ Nicht enthalten im MVP (Ausschlüsse zur Eingrenzung des Scopes)]

## 3. Benutzerfluss (User Flow)
- [Schritt-für-Schritt Ablauf der Benutzerinteraktionen (1. ..., 2. ...)]

## 4. Fachliche Datenmodelle
- [TypeScript- oder Pydantic-Strukturen der wichtigsten Entitäten]

## 5. Geschäftsregeln (Business Rules)
- [Berechnungen, Formeln, Priorisierungslogiken]
- [Validierungsregeln und Systemgrenzen]
- [Verhalten bei ungültigen Eingaben]

## 6. UI-Konzept & Layouts
- [ASCII-Skizze der Hauptoberfläche]
- [Zustands- und Farbdefinitionen für UI-Karten / Badges]
- [Details und Verhalten einzelner Komponenten (z.B. Eingabeformulare, Listen)]

## 7. AI-Interaktionsgefühl & Tonality (falls anwendbar)
- [Rolle und Persona der KI: z.B. pragmatischer Koch, wissenschaftlicher Berater]
- [Sprachstil der Ausgaben: z.B. kurz, prägnant, neutral]

## 8. Barrierefreiheit (Accessibility)
- [Anforderungen an Kontraste (z.B. WCAG AA)]
- [Touch-Targets (z.B. min. 44x44px)]
- [Semantisches HTML5]
```

---

## 4. Vorlage: `docs/Antigravity_Agent_Context.md`
*(Die Onboarding-Leitplanken für den Agenten)*

Diese Datei sorgt dafür, dass sich der Agent nach dem Klonen des Repositories sofort im Projekt zurechtfindet und die architektonischen Regeln einhält.

```markdown
# Technical Onboarding & Context Handbook
*(For Antigravity 2.0 Building Agents)*

## 1. Handshake & Workspace Rules
- **Workspace-Grenze**: Du darfst ausschließlich Dateien innerhalb dieses Git-Repositories modifizieren. 
- **Verantwortlichkeit**: Du bist für die Implementierung, das lokale Testen und die funktionale Verifikation verantwortlich. Alle grundlegenden Architekturmuster werden vom menschlichen Architekten vorgegeben.

## 2. Tech Stack & Tools
- **Package Manager**: pnpm (über Corepack auf Version `10.33.0` gepinnt).
- **Corepack aktivieren**: Führe vor Installationsschritten immer `corepack enable` aus.
- **Frontend**: Nuxt 4 / React / Svelte (gemäß Vorgabe in Apps/Frontend).
- **Backend**: Python FastAPI / Node.js (gemäß Vorgabe in Apps/Backend).

## 3. Design System & Style Guide
- [Hier trägt der Architekt das Farbkonzept, Hex-Codes und Schriftarten des Projekts ein]
- [Vorgaben zum CSS-Framework: z.B. Tailwind v4 custom theme]

## 4. API Contract & Schnittstellen
- [Hier stehen die genauen JSON-Payloads und REST-Endpoints]

## 5. Deployment & Localdev
- **Entwicklungs-Server**: Starte die gesamte Anwendung (Frontend & Backend) parallel aus dem Stammverzeichnis mittels:
  ```bash
  corepack enable
  pnpm install
  pnpm dev
  ```
- **Container-Builds (falls vorhanden)**:
  - [Befehle für Docker, Podman oder Docker Compose]
```

---

## 5. Namensempfehlungen für das Repository

Um maximale Transparenz und Auffindbarkeit in Entwickler- und Agenten-Systemen zu gewährleisten, wird der folgende Name für das Starter-Template empfohlen:

### 🏆 Empfohlener Name: `agent-nuxt4-tw4-blueprint`

#### Begründung für diese Namenswahl:
*   **`agent`**: Markiert sofort den Fokus auf generative KI-Entwicklung und die Integration von Google ADK 2.0 Agents.
*   **`nuxt4`**: Spezifiziert präzise das genutzte moderne Frontend-Framework (Nuxt 4).
*   **`tw4`**: Verwendet das etablierte, kurze Akronym für Tailwind CSS v4, was Tipparbeit im Terminal einspart.
*   **`blueprint`**: Signalisiert unmissverständlich, dass es sich um eine bewährte, fertige und stabile Architektur-Schablone handelt (und nicht nur um einen minimalistischen Scratch-Starter).

#### Alternative:
*   `agent-nuxt4-tailwindcss4-starter` (Sehr explizit, aber lang in der Eingabe bei Klon-Befehlen).

---

## 6. Setup- & Bootstrapping-Leitfaden für den Architekten

Folge dieser Schritt-für-Schritt-Anleitung, um das Starter-Template-Repository von Grund auf neu aufzusetzen und auf GitHub als wiederverwendbares Template freizugeben.

### Schritt 1: GitHub-Repository erstellen
1.  Erstelle ein neues, leeres Repository auf GitHub mit dem Namen: `agent-nuxt4-tw4-blueprint`.
2.  Navigiere auf GitHub in die **Settings** des Repositories -> Reiter **General**.
3.  Aktiviere das Kontrollkästchen: **„Template repository“**.
    *Dies ermöglicht es anderen Entwicklern und Architekten, mit einem Klick auf „Use this template“ ein neues Projekt auf dieser Basis zu starten.*

### Schritt 2: Lokalen Workspace initialisieren
Führe folgende Befehle im Terminal aus, um die Monorepo-Struktur zu bootstrappen:
```bash
# Verzeichnis erstellen & betreten
mkdir agent-nuxt4-tw4-blueprint && cd agent-nuxt4-tw4-blueprint

# Git initialisieren
git init

# Corepack für pnpm aktivieren & package.json erstellen
corepack enable
pnpm init
```

Öffne die generierte `package.json` und passe sie an, um die Versionen festzunageln (Corepack-Pinning):
```json
{
  "name": "agent-nuxt4-tw4-blueprint",
  "version": "1.0.0",
  "private": true,
  "packageManager": "pnpm@10.33.0",
  "engines": {
    "node": ">=24.0.0",
    "pnpm": ">=10.33.0"
  },
  "scripts": {
    "dev": "pnpm -r dev",
    "build": "pnpm -r build",
    "lint": "pnpm -r lint",
    "test": "pnpm -r test"
  }
}
```

Erstelle die Workspace-Zuweisung `pnpm-workspace.yaml` im Stammverzeichnis:
```yaml
packages:
  - "Apps/*"
```

### Schritt 3: Ordnerstruktur anlegen
```bash
mkdir -p Apps/Frontend Apps/Backend docs specs/business specs/technical
```

### Schritt 4: Frontend mit Nuxt 4 & Tailwind CSS v4 aufsetzen
1.  Initialisiere das Nuxt 4-Projekt im entsprechenden Verzeichnis:
    ```bash
    npx -y nuxi@latest init --packageManager pnpm Apps/Frontend
    ```
2.  Installiere Tailwind CSS v4 im Frontend-Ordner:
    ```bash
    cd Apps/Frontend
    pnpm add -D @nuxtjs/tailwindcss tailwindcss
    ```
3.  Konfiguriere das Tailwind-Modul in `Apps/Frontend/nuxt.config.ts` und richte die `@import "tailwindcss";` Anweisung in der globalen CSS-Datei ein.
4.  Kehre zurück ins Stammverzeichnis:
    ```bash
    cd ../..
    ```

### Schritt 5: Backend aufsetzen
1.  Richte das Python-Skelett in `Apps/Backend` ein (z. B. mit `requirements.txt` inklusive `google-adk>=2.0.0` und `fastapi`).
2.  Erstelle die Grundstruktur mit `main.py` und `llm_service.py` als Startpunkt für den Agenten.

### Schritt 6: Template-Dokumente einpflegen
1.  Erstelle die leere Sourcedatei `specs/business/business-spec.md` und kopiere das Inhaltsverzeichnis (TOC) aus **Kapitel 3** hinein.
2.  Erstelle die Datei `docs/Antigravity_Agent_Context.md` und füge die Vorlage aus **Kapitel 4** ein, um die Agenten-Leitplanken festzulegen.
3.  Erstelle eine Standard-`.gitignore` im Stammverzeichnis, um `node_modules`, Python-`venv`, `.env` und SQLite-Datenbankdateien auszuschließen.

### Schritt 7: Commit & Push auf GitHub
```bash
# Alle Dateien hinzufügen
git add .

# Initialer Commit
git commit -m "feat: initial scaffolding for agent-nuxt4-tw4-blueprint"

# Remote-Verbindung herstellen und pushen
git branch -M main
git remote add origin https://github.com/<dein-nutzername>/agent-nuxt4-tw4-blueprint.git
git push -u origin main
```

---

## 7. Projekt-Kickstart für neue Projekte (Der goldene Pfad)

Wenn ein neues Projekt ansteht, sieht der Workflow für den Menschen (Architekten) und den AI-Agenten wie folgt aus:

1.  **Architekt**: Klickt auf GitHub beim Repository `agent-nuxt4-tw4-blueprint` auf **„Use this template“**, um ein neues Projekt-Repo (z. B. `my-new-app`) zu erstellen und klont es lokal.
2.  **Architekt**: Befüllt die Datei `specs/business/business-spec.md` mit den konkreten fachlichen Anforderungen und dem UI-Konzept des neuen Projekts.
3.  **Architekt**: Trägt im `docs/Antigravity_Agent_Context.md` die genauen API-Schnittstellen und Style-Tokens ein.
4.  **Agent (Antigravity 2.0)**: Onboardet sich vollautomatisch, indem er `Antigravity_Agent_Context.md` liest, führt `corepack enable` und `pnpm install` aus und beginnt autonom mit dem fehlerfreien Bau der Anwendung innerhalb der definierten Workspace-Schranken!

