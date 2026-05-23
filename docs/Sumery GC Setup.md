## 🔑 Identity & Project Context

* **Active Developer Account:** `marcsurlechemin@gmail.com`
* **Active Project ID:** `project-0c5cd6d6-c335-4e02-ac2` *(Display Name: "My First Project")*
* **Billing Account ID:** `017770-4B9C4B-A727E9` *(Display Name: "Mein Rechnungskonto")*
    * *Status:* Verified active budget tracking and financial controls (`billingEnabled: true`).
* **Target Cloud Deployment Region:** `europe-west6` *(Zurich, Switzerland)*

---

## 💻 Local Environment (`.zshrc`)

The local macOS workstation utilizes a standalone Python deployment isolated via `pyenv` to shield the Google Cloud CLI (`gcloud`) from standard runtime or shim path discrepancies.

### System Path Hooks:
```bash
# Explicitly directs gcloud execution to the static Python 3.13.11 library core
export CLOUDSDK_PYTHON="/Users/hector/.pyenv/versions/3.13.11/bin/python3.13"

# Exposes Homebrew-managed gcloud binaries globally to your active shell paths
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
🚀 Enabled Infrastructure & System Architecture
The core cloud architecture has been updated and provisioned for a secure, decoupled, containerized serverless topology:

Plaintext
                  ┌──────────────────────────────────────────────┐
                  │          Google Cloud Project                │
                  │     project-0c5cd6d6-c335-4e02-ac2           │
                  └──────────────────────┬───────────────────────┘
                                         │
       ┌──────────────────┬──────────────┴──────────────┬──────────────────┐
       ▼                  ▼                             ▼                  ▼
┌──────────────┐   ┌──────────────┐              ┌──────────────┐   ┌──────────────┐
│  Cloud Run   │   │  Artifact    │              │  Firestore   │   │    Secret    │
│  (Serverless │   │  Registry    │              │  (Database)  │   │   Manager    │
│   Compute)   │   │ (Containers) │              │ Native Mode  │   │  (API Keys/  │
└──────────────┘   └──────────────┘              │ europe-west6 │   │ Credentials) │
                                                 │ [Free Tier]  │   └──────────────┘
                                                 └──────────────┘
1. NoSQL Storage Layer (Firestore)
Instance Identifier: (default)

Operational Topology: Native Mode (FIRESTORE_NATIVE)

Availability Zone: europe-west6 (Zurich)

Financial Profile: freeTier: true enabled. This structural tag covers early staging limits seamlessly (up to 50,000 reads, 20,000 writes, and 20,000 deletes daily) prior to pulling from the centralized billing budgets account.

2. Container Compute Pipelines
run.googleapis.com (Cloud Run): Activated for scale-to-zero microservices deployment.

artifactregistry.googleapis.com (Artifact Registry): Activated to secure, version, and manage compiled Docker container footprints.

3. Application Security & Monitoring Core
secretmanager.googleapis.com (Secret Manager): Activated. Preloaded to securely inject environment flags and keys (including decoupled Gemini developer hashes) safely at the container runtime tier.

billingbudgets.googleapis.com (Billing Budgets API): Activated to map, ingest, and flag operational expenses back to the native budget account parameters.

⚠️ Core Architectural Caveat
Gemini API Isolation: The active external developer key originates from Google AI Studio and scales using the independent Google AI Ultra platform subscription layer.

The legacy cloud environment shadow project gen-lang-client-0803762660 generated natively during initial AI Studio onboarding remains entirely separate and must be safely bypassed in favor of routing application resource costs natively through your budgeted workspace (project-0c5cd6d6-c335-4e02-ac2).