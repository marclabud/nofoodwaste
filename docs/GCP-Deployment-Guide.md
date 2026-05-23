# Google Cloud Run Deployment Guide for NoFoodWaste

This guide provides a comprehensive, step-by-step walkthrough to deploy the **NoFoodWaste** project from scratch to **Google Cloud Platform (GCP)**. 

To align with your [Secure & Cost-Effective Google Cloud Hosting Proposal](file:///Users/hector/dev/NoFoodWaste/docs/Secure-Demo-Hosting-Google-Proposal.md), this guide is tailored to:
*   A **Stateless FastAPI Backend** on Google Cloud Run.
*   **Google Cloud Firestore** (Native Mode) for production data storage (instead of stateful SQLite).
*   **Google Secret Manager** to securely hold the Gemini API key.
*   **Flexible Frontend Hosting** (either Google Cloud Run or Firebase Hosting).

---

## Prerequisites
Before you start, make sure you have:
1.  A **Google Account** (Gmail or Google Workspace).
2.  **Docker** or **Podman** installed and running on your local machine.
3.  The **Google Cloud SDK (`gcloud` CLI)** installed on your machine.
    *   *If you do not have it installed, run:* `brew install --cask google-cloud-sdk` (on macOS).

---

## Step 1: Initial Google Cloud Setup (From Scratch)

### 1.1 Create a GCP Account & Billing Account
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  Sign in with your Google account. If you're new to GCP, you will be prompted to agree to the Terms of Service and can sign up for the **$300 Free Trial**.
3.  Ensure you have a **Billing Account** set up. While Cloud Run and Firestore have generous always-free tiers (costing **0.00 CHF / month** for demo usage), Google Cloud requires a billing account to enable advanced services like Cloud Run and Secret Manager.

### 1.2 Authenticate your Local CLI
Open your terminal and authenticate your local `gcloud` command-line tool:
```bash
gcloud auth login
```
This will open your default browser. Select your Google account and click **Allow** to grant permissions.

### 1.3 Create a new Google Cloud Project
In Google Cloud, all resources live under a Project. Create a new project for this application:
```bash
# Choose a globally unique Project ID (e.g. nofoodwaste-demo-12345)
export PROJECT_ID="nofoodwaste-demo-$(date +%s)"
gcloud projects create $PROJECT_ID --name="NoFoodWaste Demo"
```

Set your active CLI context to this new project:
```bash
gcloud config set project $PROJECT_ID
```

### 1.4 Link Billing to the Project
To enable services, link your billing account to the newly created project:
1.  Get your Billing Account ID:
    ```bash
    gcloud beta billing accounts list
    ```
2.  Link it:
    ```bash
    gcloud beta billing projects link $PROJECT_ID --billing-account=[YOUR_BILLING_ACCOUNT_ID]
    ```

---

## Step 2: Enable Required APIs

Google Cloud services must be explicitly enabled before they can be used. Run the following command to enable the core APIs required for NoFoodWaste:

```bash
gcloud services enable \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    firestore.googleapis.com \
    secretmanager.googleapis.com \
    billingbudgets.googleapis.com
```

> [!NOTE]
> This command might take 1–2 minutes to complete as GCP provisions the APIs behind the scenes.

---

## Step 3: Provision Google Cloud Firestore (Database)

Because Cloud Run is stateless, running a local SQLite database file inside the container will reset your data every time the container scales down to 0 or restarts. To support production, we switch to **Google Cloud Firestore** (Native NoSQL mode).

Create the Firestore database in your chosen region (e.g., `europe-west6` for Zurich/Switzerland, or `us-central1`):
```bash
export REGION="europe-west6"  # Choose your preferred region

gcloud firestore databases create \
    --location=$REGION \
    --type=firestore-native
```
Firestore comes with an always-free tier of up to **50,000 reads** and **20,000 writes** per day, making it perfect for hosting this demo at absolutely zero cost.

---

## Step 4: Configure Secure API Keys in Secret Manager

Your backend requires a `GEMINI_API_KEY` to talk to Google AI Studio. Instead of hardcoding this API key in dockerfiles or passing it in plain-text environment variables, we store it securely in **Google Cloud Secret Manager**.

### 4.1 Create and Populate the Secret
Run this command to create a secret named `gemini-api-key` and save your key to it:
```bash
# Replace YOUR_ACTUAL_GEMINI_KEY with your API key from Google AI Studio
echo -n "YOUR_ACTUAL_GEMINI_KEY" | gcloud secrets create gemini-api-key \
    --data-file=- \
    --replication-policy="automatic"
```

---

## Step 5: Build & Package Containers (Artifact Registry)

Google Cloud Run deploys pre-built Docker containers. We will create a private registry in **GCP Artifact Registry** to host our container images.

### 5.1 Create the Repository
Create a Docker repository named `nofoodwaste-repo`:
```bash
gcloud artifacts repositories create nofoodwaste-repo \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository for NoFoodWaste"
```

### 5.2 Authenticate Docker with the Registry
Configure your local Docker daemon (or Podman) to authenticate with the Artifact Registry:
```bash
gcloud auth configure-docker $REGION-docker.pkg.dev
```

### 5.3 Build & Push the Backend Image
Navigate to the project root directory and build the FastAPI Backend Docker image:
```bash
# 1. Build the image locally
docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/nofoodwaste-repo/backend:latest ./Apps/Backend

# 2. Push it to your Google Cloud Artifact Registry
docker push $REGION-docker.pkg.dev/$PROJECT_ID/nofoodwaste-repo/backend:latest
```

*Note: If you are using Podman instead of Docker, substitute `docker` with `podman` in these commands.*

---

## Step 6: Create a Secure Service Account for the Backend

To maintain the **Principle of Least Privilege**, we create a dedicated Identity (Service Account) for our backend container. It will only have permissions to:
1.  Read and write to Cloud Firestore.
2.  Access the Gemini API key secret in Secret Manager.

### 6.1 Create the Service Account
```bash
gcloud iam service-accounts create nofoodwaste-backend-sa \
    --display-name="NoFoodWaste Backend Service Account"
```

### 6.2 Grant Firestore Access
```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:nofoodwaste-backend-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/datastore.user"
```

### 6.3 Grant Secret Manager Access (Least Privilege)
Grant access **only** to the specific secret containing the Gemini key, rather than all secrets:
```bash
gcloud secrets add-iam-policy-binding gemini-api-key \
    --member="serviceAccount:nofoodwaste-backend-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

---

## Step 7: Deploy the Backend to Cloud Run

Now we deploy the backend container. Notice how we restrict the instance scaling limits and inject the secret safely:

```bash
gcloud run deploy nofoodwaste-backend \
    --image=$REGION-docker.pkg.dev/$PROJECT_ID/nofoodwaste-repo/backend:latest \
    --region=$REGION \
    --service-account="nofoodwaste-backend-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --allow-unauthenticated \
    --max-instances=2 \
    --set-env-vars="DB_PROVIDER=firestore,ENVIRONMENT=production" \
    --set-secrets="GEMINI_API_KEY=gemini-api-key:latest" \
    --port=8000
```

### How this configuration protects your budget:
*   `--max-instances=2`: Caps maximum instances to 2, preventing billing runaway in the event of an automated DDoS attack.
*   `--allow-unauthenticated`: Enables public internet access to your API.
*   `--set-secrets="..."`: Safely mounts the `GEMINI_API_KEY` from Secret Manager directly into the process environment as an environment variable without storing it in plain text.

Once deployed, the CLI will output your live Backend Service URL, which looks like:
`https://nofoodwaste-backend-xxxxx-xx.a.run.app`

Make sure to copy this URL! We need it for the frontend.

---

## Step 8: Deploy the Frontend

You have two excellent choices for deploying your Nuxt static website in a secure and completely managed way.

### Option A: Deploy Frontend to Firebase Hosting (Recommended / Free)
As highlighted in your architecture proposal, **Firebase Hosting** is the gold standard for static single page apps. It has a globally distributed CDN, is completely free, and natively supports Firebase App Check.

1.  Initialize Firebase in your `Apps/Frontend` folder:
    ```bash
    cd Apps/Frontend
    npx -y firebase-tools login
    npx -y firebase-tools init hosting
    ```
    *Select your existing project `$PROJECT_ID`, configure public directory to `.output/public`, and configure as single-page app.*
2.  Create a production build pointing to your Backend Cloud Run URL:
    ```bash
    # Set the environment variable for Nuxt build
    export NUXT_PUBLIC_API_BASE="https://nofoodwaste-backend-xxxxx-xx.a.run.app"
    pnpm run generate
    ```
3.  Deploy:
    ```bash
    npx -y firebase-tools deploy --only hosting
    ```

---

### Option B: Deploy Frontend to Google Cloud Run
If you prefer to containerize the frontend and run it on Cloud Run using the `Dockerfile` and `Nginx` configurations present in the repository, follow these steps:

1.  **Build and Push the Frontend Container:**
    We build the Nuxt app, supplying the backend API URL as a build-time argument so that the client knows where to send API requests:
    ```bash
    # 1. Build Nuxt container with the backend API address
    docker build \
        --build-arg NUXT_PUBLIC_API_BASE="https://nofoodwaste-backend-xxxxx-xx.a.run.app" \
        -t $REGION-docker.pkg.dev/$PROJECT_ID/nofoodwaste-repo/frontend:latest \
        ./Apps/Frontend

    # 2. Push image to registry
    docker push $REGION-docker.pkg.dev/$PROJECT_ID/nofoodwaste-repo/frontend:latest
    ```

2.  **Deploy Frontend to Cloud Run:**
    ```bash
    gcloud run deploy nofoodwaste-frontend \
        --image=$REGION-docker.pkg.dev/$PROJECT_ID/nofoodwaste-repo/frontend:latest \
        --region=$REGION \
        --allow-unauthenticated \
        --max-instances=2 \
        --port=80
    ```

Once completed, the CLI will output your live Frontend URL (e.g., `https://nofoodwaste-frontend-xxxxx-xx.a.run.app`), which users can open to access the NoFoodWaste app!

---

## Step 9: Configure Billing Budgets (The Ultimate Safety Net)

To guarantee that you never get a surprise bill, set up a Google Cloud Billing Budget and Alert:

1.  Open the [GCP Billing Console Budgets page](https://console.cloud.google.com/billing/budgets).
2.  Click **Create Budget**.
3.  Name it `NoFoodWaste Budget Capping`.
4.  Set the **Time Period** to `Monthly` and the **Budget Type** to `Specified Amount` at **5.00 CHF** (or USD).
5.  Under **Trigger Alerts**, set standard thresholds (e.g. 50%, 90%, 100% of budget) to trigger instant email notifications so you are alerted immediately if any unexpected activity occurs.

---

## Summary of Live Services

Once the above steps are completed, your application is running entirely on Google Cloud with the following state-of-the-art serverless layout:

| Service | Host | Cost Model | Security |
| :--- | :--- | :--- | :--- |
| **Frontend** | Firebase Hosting (or Cloud Run) | $0 (Generous Free Tier CDN) | SSL / HTTPS by default |
| **Backend API** | Google Cloud Run | $0 (Up to 2M requests/mo free) | Capped at 2 instances; credentials loaded via IAM Service Account |
| **Database** | Google Cloud Firestore | $0 (Up to 50k reads, 20k writes/day free) | Locked down via IAM; accessed only by Backend Service Account |
| **AI Keys** | Google Secret Manager | $0 (Free tier covers 6 active secrets/mo) | Protected by Google IAM; never exposed in source code |
