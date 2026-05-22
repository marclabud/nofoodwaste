# Release- & Deployment-Plan: No Food-Waste MVP

Dieses Dokument beschreibt das Vorgehen, um eine produktionsbereite (Production-ready) Version der **No Food-Waste** Applikation im Verzeichnis `/Users/hector/dev/NoFoodWaste/dist` bereitzustellen. 

Das Ziel ist es, den optimierten, statischen Frontend-Build und den bereinigten Backend-Quellcode an einem zentralen Ort zu bündeln, um ein einfaches Deployment (z. B. auf Servern, Cloud-Plattformen oder in Docker-Containern) zu ermöglichen.

---

## 🏗️ Ziel-Struktur im Verzeichnis `/dist`

Nach dem Build- und Packaging-Prozess wird das Verzeichnis `/dist` wie folgt strukturiert sein:

```text
NoFoodWaste/dist/
├── frontend/               # Statisch generiertes Nuxt-Frontend (HTML/JS/CSS)
│   └── index.html          # Bereit für Nginx, Apache oder Cloud CDN
├── backend/                # Bereinigter Python FastAPI Code (ohne Dev-Dateien)
│   ├── main.py
│   ├── database.py
│   ├── models.py
│   ├── llm_service.py
│   ├── prompts/
│   │   └── system_recipe_assistant.md
│   └── requirements.txt
└── start_production.sh     # Optionaler Produktions-Starter (Uvicorn + Nginx/Static Server)
```

---

## 🛠️ Schritt-für-Schritt Build-Prozess

### Schritt 1: Bereinigung & Vorbereitung
Bevor ein Release gebaut wird, müssen alte Build-Artefakte und temporäre Caches entfernt werden.
```bash
# Im Projekt-Root
rm -rf dist/
mkdir -p dist/frontend
mkdir -p dist/backend
```

### Schritt 2: Frontend-Produktions-Build (Nuxt)
Nuxt wird als statisch generierte Applikation (SSG - Static Site Generation) kompiliert, um maximale Performance, SEO-Optimierung und günstiges Hosting zu ermöglichen.

1. **Konfiguration der API-URL:**
   Für die Produktion muss die API-URL auf die echte Backend-URL verweisen (nicht mehr standardmäßig `localhost`). Dies geschieht über Umgebungsvariablen.
2. **Build-Befehl:**
   ```bash
   cd Apps/Frontend
   pnpm install
   pnpm run generate
   ```
   Dieser Befehl generiert die vollständige statische Website im Verzeichnis `.output/public/` (oder `dist/` je nach Nuxt-Version).
3. **Kopieren der Assets:**
   ```bash
   cp -R .output/public/* ../../dist/frontend/
   ```

### Schritt 3: Backend-Packaging (FastAPI)
Das Backend wird für die Produktion verpackt. Lokale SQLite-Datenbankdateien (`*.db`), Logfiles, virtuelle Umgebungen (`.venv`) und Pycache-Ordner werden **ausgeschlossen**, um die Release-Größe minimal zu halten.

1. **Dateien kopieren:**
   ```bash
   cd ../Backend
   cp -R main.py database.py models.py llm_service.py requirements.txt ../../dist/backend/
   cp -R prompts/ ../../dist/backend/prompts/
   ```

---

## ⚙️ Produktions-Konfiguration (`.env`)

Für das Live-System im Backend (`/dist/backend/.env`) müssen die Entwicklungseinstellungen gehärtet werden:

```env
# 1. API Keys für LLM Integration (Live-Schlüssel)
GEMINI_API_KEY=PROD_GEMINI_API_KEY_HERE
LLM_MODEL=gemini-2.5-flash

# 2. Sicherheits- & Performance-Einstellungen
DEBUG=False                  # Deaktiviert detaillierte Fehlerausgaben im API-Response
ENVIRONMENT=production

# 3. CORS (Erlaubt nur Zugriffe von der echten Frontend-Domain)
# In main.py entsprechend konfigurieren (z. B. allow_origins=["https://deine-domain.de"])
```

---

## 🚀 Ausführung in der Produktion

### 1. Backend starten
Im Produktionsmodus wird der FastAPI-Server über **Uvicorn** (ohne `--reload`) gestartet, idealerweise gebunden an alle Schnittstellen (`0.0.0.0`):
```bash
cd dist/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Starten (Uvicorn führt die FastAPI-App aus)
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 2. Frontend ausliefern
Die statischen Dateien im Verzeichnis `dist/frontend/` können über jeden gängigen Webserver wie **Nginx**, **Apache** oder Static-Hosting-Dienste (wie Firebase Hosting oder Vercel) extrem performant ausgeliefert werden.
