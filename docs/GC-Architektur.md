# NoFoodWaste: Google Cloud Architektur-Beschreibung

Dieses Dokument beschreibt die Systemarchitektur der **NoFoodWaste**-Anwendung auf der Google Cloud Platform (GCP) und Firebase aus architektonischer Sicht.

---

## 1. Systemarchitektur im Überblick

Das folgende Diagramm veranschaulicht den Datenfluss und die Interaktion der einzelnen Komponenten:

```mermaid
graph TD
    User["Endbenutzer / Browser"]
    
    subgraph "Google Cloud & Firebase (GCP Project)"
        subgraph "Präsentationsschicht"
            FH["Firebase Hosting (Globales CDN / Nuxt Statische Assets)"]
        end
        
        subgraph "Logikschicht"
            CR["Google Cloud Run (FastAPI Python App in Docker)"]
            SM["GCP Secret Manager (Verschlüsselter Gemini API-Key)"]
            SA["Service Account (Minimale Berechtigungen / IAM)"]
        end
        
        subgraph "Datenschicht"
            CF["Cloud Firestore (Serverlose NoSQL Datenbank)"]
        end
    end
    
    subgraph "Externe Dienste"
        Gemini["Google AI Studio (Gemini LLM API)"]
    end
    
    %% Datenflüsse und Interaktionen
    User -->| "1. Lädt HTML/JS/CSS" | FH
    User -->| "2. API-Anfragen / REST" | CR
    CR -.->| "Nimmt Identität an" | SA
    CR -->| "3. Liest Key zur Laufzeit" | SM
    CR -->| "4. Speichert/Liest Zutaten" | CF
    CR -->| "5. Generiert Rezepte" | Gemini
```

---

## 2. Die Architekturkomponenten im Detail

### 2.1 Präsentationsschicht (Frontend): Firebase Hosting
* **Technologie:** Statisch generierte Nuxt.js-Anwendung (Single Page Application / Static Site Generation).
* **Architektur-Rolle:** Firebase Hosting fungiert als globales **Content Delivery Network (CDN)**. Anstatt einen Server (z. B. Node.js) dauerhaft für das Ausliefern der HTML- und JS-Dateien zu betreiben, werden die vorab generierten Dateien weltweit an den Edge-Standorten von Google gecacht.
* **Vorteile:**
  * **Extrem schnelle Ladezeiten:** Die Assets werden physisch so nah wie möglich am Benutzer ausgeliefert.
  * **Unendliche Skalierbarkeit:** Ein plötzlicher Ansturm von Nutzern bringt das Frontend nicht zum Absturz.
  * **Kostenfrei im Basisbereich:** Keine Kosten für ungenutzte Server-CPU.

### 2.2 Logikschicht (Backend): Google Cloud Run
* **Technologie:** In Docker-Container verpackte FastAPI-Python-Anwendung (ausgeführt auf Intel x86_64-Architektur).
* **Architektur-Rolle:** Cloud Run ist eine **zustandslose (stateless) Container-Plattform**, die auf Knative basiert. Sie führt das Backend nur aus, wenn tatsächlich HTTP-Anfragen eingehen.
* **Vorteile:**
  * **Scale-to-Zero:** Wenn niemand die App nutzt, fährt Cloud Run die Container auf 0 Instanzen herunter. Es entstehen **keine Kosten** für ungenutzte Serverzeit.
  * **Automatische Skalierung:** Bei hoher Last startet Cloud Run innerhalb von Millisekunden zusätzliche Container-Instanzen (konfiguriert auf maximal 2 Instanzen, um Kostenattacken zu vermeiden).
  * **Zustandslosigkeit:** Das Backend speichert keine Daten lokal im Container. Alle Daten fließen direkt in die Datenbank. Dies erlaubt das problemlose Skalieren und Austauschen von Instanzen.

### 2.3 Datenschicht: Cloud Firestore
* **Technologie:** Vollständig verwaltete, serverlose NoSQL-Dokumentendatenbank.
* **Architektur-Rolle:** Firestore speichert die Zutaten und Rezepte strukturiert in Dokumenten und Sammlungen (Collections).
* **Vorteile:**
  * **Kein Wartungsaufwand:** Keine Sharding-, Replikations- oder Backup-Sorgen.
  * **Skalierbarkeit:** Firestore skaliert automatisch und verarbeitet problemlos Millionen von gleichzeitigen Verbindungen.
  * **Sicherheitsintegration:** Kann über Firebase Security Rules (für direkten Clientzugriff) oder IAM-Rollen (für Backendzugriff) abgesichert werden.

---

## 3. Sicherheitsarchitektur & Zugriffskontrolle

Ein wesentlicher Teil dieser Cloud-Architektur ist das Sicherheitskonzept, das auf dem Prinzip der **minimalen Rechtevergabe (Least Privilege)** basiert:

1. **Schutz von API-Keys (Secret Manager):**
   Der sensible API-Schlüssel für Google AI Studio (Gemini) wird niemals im Quellcode oder im Klartext in Umgebungsvariablen hinterlegt. Er liegt verschlüsselt im **GCP Secret Manager** und wird beim Start des Cloud Run-Containers sicher ins RAM injiziert.
2. **Identitätsbasierte Rechte (IAM & Service Accounts):**
   Das Cloud Run-Backend läuft unter einer eigens dafür erstellten Identität, dem Service Account `nofoodwaste-backend-sa`. Dieser Account hat *ausschließlich* Berechtigungen für:
   * Den Lese- und Schreibzugriff auf die Firestore-Datenbank (`roles/datastore.user`).
   * Das Auslesen des spezifischen Secrets im Secret Manager (`roles/secretmanager.secretAccessor`).
   Selbst wenn ein Angreifer eine Schwachstelle im Backend ausnutzen würde, hätte er keinen Zugriff auf andere Google Cloud-Ressourcen oder Ihr Abrechnungskonto.
3. **Kapselung der LLM-API:**
   Der Benutzer-Browser kommuniziert niemals direkt mit der Gemini API. Das Backend fungiert als sicheres Gateway. Dadurch bleibt Ihr Gemini API-Key für die Außenwelt absolut unsichtbar.

---

## 4. Live-Endpunkte & URLs

Die produktive Anwendung ist auf der Google Cloud Platform und Firebase unter den folgenden Adressen live geschaltet und voll funktionsfähig:

### 🌐 Frontend (Firebase Hosting)
* **Haupt-URL (Projekt-Standard):** [https://my-first-project-9510f.web.app](https://my-first-project-9510f.web.app)
* **Alternative Firebase-Domain:** [https://my-first-project-9510f.firebaseapp.com](https://my-first-project-9510f.firebaseapp.com)

### ⚙️ Backend (Google Cloud Run API)
* **Backend Service URL:** [https://nofoodwaste-backend-301426404374.europe-west6.run.app](https://nofoodwaste-backend-301426404374.europe-west6.run.app)
* **API Swagger-Dokumentation (interaktiv):** [https://nofoodwaste-backend-301426404374.europe-west6.run.app/docs](https://nofoodwaste-backend-301426404374.europe-west6.run.app/docs)
