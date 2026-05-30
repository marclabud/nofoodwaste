# GCP Schlüssellose Authentifizierung & Multi-Service-Account-Strategie

Dieses Dokument beschreibt das Sicherheitsfeature der schlüssellosen Authentifizierung (Keyless Authentication) auf Google Cloud Platform (GCP) sowie das Prinzip der getrennten Dienstkonten (Principle of Least Privilege) für den Einsatz in beliebigen Cloud-Projekten.

---

## 🛡️ Teil 1: Das Sicherheitsfeature "Schlüssellose Authentifizierung"

Traditionell wurden für den Zugriff auf Google Cloud-Ressourcen lokale JSON-Schlüsseldateien (`service.json` oder `credentials.json`) heruntergeladen und auf Servern oder in Repositories hinterlegt. Dies birgt erhebliche Risiken (Diebstahl, versehentliches Commit in GitHub).

**Die moderne Lösung:** Wir verknüpfen Identitäten direkt in der Cloud-Infrastruktur. Anwendungen nutzen die **Application Default Credentials (ADC)** des Google Cloud SDKs.

### Funktionsweise:
1. **Dienstkonto (Service Account) anlegen**: Ein virtueller Benutzer in GCP mit spezifischen Rechten.
2. **Laufzeit-Verknüpfung**: Die Compute-Ressource (z.B. Google Cloud Run, GKE, App Engine) wird mit diesem Dienstkonto gestartet.
3. **Automatische Authentifizierung**: Die Client-Bibliotheken (SDKs) im Code erkennen beim Start die Cloud-Umgebung und holen sich automatisch temporäre, rotierende Zugriffstoken. **Es wird kein statischer Schlüssel im Code oder Container benötigt.**

---

## 👥 Teil 2: Multi-Service-Account-Strategie (Getrennte Dienstkonten)

### Ist es sinnvoll, mehrere Service-Accounts anzulegen?
**Ja, absolut. Dies ist ein fundamentaler Pfeiler der Cloud-Sicherheit!**

Durch die Verwendung getrennter Dienstkonten für verschiedene Komponenten wird das **Prinzip der minimalen Rechtevergabe (Principle of Least Privilege)** umgesetzt. Sollte eine Komponente kompromittiert werden (z. B. durch eine Sicherheitslücke im Code), bleibt der Schaden auf die Rechte dieses einen Kontos begrenzt.

#### Beispiel-Architektur für ein typisches Projekt:

```
                      ┌───────────────────────────────────┐
                      │        GCP Projekt                │
                      └─────────────────┬─────────────────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         ▼                              ▼                              ▼
┌──────────────────┐           ┌──────────────────┐           ┌──────────────────┐
│   CI/CD Pipeline │           │  Backend-Service │           │ Frontend-Service │
│ (GitHub Actions) │           │   (Cloud Run)    │           │ (Firebase/Run)   │
└────────┬─────────┘           └────────┬─────────┘           └────────┬─────────┘
         │                              │                              │
         ▼                              ▼                              ▼
 ┌───────────────┐              ┌───────────────┐              ┌───────────────┐
 │   SA: github  │              │  SA: backend  │              │  SA: frontend │
 └───────┬───────┘              └───────┬───────┘              └───────┬───────┘
         │                              │                              │
         ▼                              ▼                              ▼
Rechte:                         Rechte:                         Rechte:
- Artifacts schreiben          - Firestore Lesen/Schreiben     - Statische Assets
- Cloud Run deployen            - Secret Manager (API-Key)      - CDN invalidieren
```

1. **Backend Service-Account (`nofoodwaste-backend-sa`)**
   * *Berechtigungen:* Lese-/Schreibzugriff auf die Firestore-Datenbank, Zugriff auf den Gemini-API-Schlüssel im Secret Manager.
   * *Keine Berechtigung für:* Bereitstellung neuer Container-Images, Zugriff auf Abrechnungsdaten oder Löschen des Projekts.

2. **Frontend Service-Account (`nofoodwaste-frontend-sa`)**
   * *Berechtigungen:* Hosting-Bereitstellung, Zugriff auf öffentliche APIs.
   * *Keine Berechtigung für:* Datenbankzugriff (Firestore) oder Backend-Secrets.

3. **CI/CD Deployment Service-Account (`github-deployer-sa`)**
   * *Berechtigungen:* Schreiben in die Artifact Registry, Aktualisieren von Cloud Run-Diensten.
   * *Keine Berechtigung für:* Direkten Lesezugriff auf Kundendaten in Firestore.

---

## 🚀 Teil 3: Generisches Kochrezept (How-To) für andere Projekte

Dieses Muster lässt sich mit folgenden `gcloud`-Befehlen auf jedes GCP-Projekt anwenden:

### 1. Variablen definieren
```bash
export PROJECT_ID="ihr-gcp-projekt-id"
export REGION="europe-west6"
export SERVICE_NAME="mein-app-service"
export SA_NAME="sa-${SERVICE_NAME}"
```

### 2. Isoliertes Dienstkonto erstellen
```bash
gcloud iam service-accounts create ${SA_NAME} \
    --display-name="Dienstkonto fuer ${SERVICE_NAME}" \
    --project=${PROJECT_ID}
```

### 3. Rechte zuweisen (Beispiel: Nur Firestore & Secret Manager)
```bash
# Firestore Lese-/Schreibrechte
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/datastore.user"

# Secret Manager Zugriff (nur auf ein spezifisches Secret!)
gcloud secrets add-iam-policy-binding mein-api-key-secret \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

### 4. Anwendung schlüssellos in Cloud Run ausführen
Beim Deployen wird dem Service das isolierte Dienstkonto angehängt. Der Code im Container nutzt automatisch die Berechtigungen dieses Kontos.
```bash
gcloud run deploy ${SERVICE_NAME} \
    --image=${REGION}-docker.pkg.dev/${PROJECT_ID}/mein-repo/${SERVICE_NAME}:latest \
    --region=${REGION} \
    --service-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --allow-unauthenticated
```
