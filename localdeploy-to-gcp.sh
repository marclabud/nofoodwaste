#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   NoFoodWaste - Google Cloud Deployer Script       ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Container Engine Detection
CONTAINER_CMD=""
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
    echo -e "${GREEN}[✔] Container Engine: Podman detected.${NC}"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
    echo -e "${GREEN}[✔] Container Engine: Docker detected.${NC}"
else
    echo -e "${RED}[✘] Error: Neither Docker nor Podman was found in your PATH.${NC}"
    exit 1
fi

# Ensure the container engine is running
if ! $CONTAINER_CMD info &>/dev/null; then
    if [ "$CONTAINER_CMD" = "podman" ]; then
        echo -e "${YELLOW}[!] Podman virtual machine is not running. Attempting to start...${NC}"
        if ! podman machine start; then
            echo -e "${RED}[✘] Error: Failed to start Podman machine.${NC}"
            echo -e "    Please run 'podman machine init' first if you haven't set it up, or check manually."
            exit 1
        fi
        echo -e "${GREEN}[✔] Podman virtual machine started successfully.${NC}"
        sleep 3
    else
        echo -e "${RED}[✘] Error: Docker daemon is not running.${NC}"
        echo -e "    Please start your Docker Desktop application and try again."
        exit 1
    fi
fi


# 2. Check GCP CLI and Auth
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}[✘] Error: Google Cloud SDK (gcloud) is not installed.${NC}"
    echo -e "    Please run: brew install --cask google-cloud-sdk"
    exit 1
fi

# Auto-detect active gcloud project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}[!] No active gcloud project set.${NC}"
    read -p "Please enter your GCP Project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
else
    echo -e "${GREEN}[✔] GCP Project ID: $PROJECT_ID${NC}"
fi

REGION="europe-west6"
echo -e "${GREEN}[✔] Target Region: $REGION (Zurich, Switzerland)${NC}"

# 3. Load Gemini API Key from backend .env
ENV_FILE="./Apps/Backend/.env"
GEMINI_API_KEY=""
if [ -f "$ENV_FILE" ]; then
    # Extracts value for GEMINI_API_KEY from the local environment file
    GEMINI_API_KEY=$(grep -E "^GEMINI_API_KEY=" "$ENV_FILE" | cut -d'=' -f2-)
fi

if [ -z "$GEMINI_API_KEY" ] || [[ "$GEMINI_API_KEY" == *"api_key_hier"* ]]; then
    echo -e "${YELLOW}[!] Valid Gemini API Key not found in $ENV_FILE.${NC}"
    read -sp "Please paste your GEMINI_API_KEY from Google AI Studio: " GEMINI_API_KEY
    echo ""
else
    echo -e "${GREEN}[✔] Loaded Gemini API Key from Backend .env file.${NC}"
fi

echo -e "\n${BLUE}--- Summary of Configurations ---${NC}"
echo -e "Project ID:       ${YELLOW}$PROJECT_ID${NC}"
echo -e "Region:           ${YELLOW}$REGION${NC}"
echo -e "Container Runner: ${YELLOW}$CONTAINER_CMD${NC}"
echo -e "Secret Key:       ${YELLOW}**** (Loaded)${NC}"
echo -e "${BLUE}---------------------------------${NC}"

echo -e "\n${BLUE}--- Frontend Deployment Option ---${NC}"
echo -e "How would you like to deploy the Frontend?"
echo -e "  [1] Firebase Hosting (Recommended, Static CDN, 100% Free)"
echo -e "  [2] Google Cloud Run (Containerized Nginx on Cloud Run)"
echo -e "  [3] Skip Frontend Deployment for now"
read -p "Select choice (1, 2, or 3): " -n 1 -r REPLY_FRONTEND
echo ""

# Validate choice and dependencies early before making changes on GCP
if [[ $REPLY_FRONTEND == "1" ]]; then
    echo -e "${BLUE}Checking dependencies for Firebase Hosting...${NC}"
    if ! command -v node &> /dev/null; then
        echo -e "${RED}[✘] Error: Node.js (node/npm) is not installed. It is required for Firebase Hosting deployment.${NC}"
        echo -e "    Please install Node.js (https://nodejs.org) and try again."
        exit 1
    fi
    if ! command -v pnpm &> /dev/null; then
        echo -e "${RED}[✘] Error: pnpm is not installed. It is required for generating the static Nuxt frontend.${NC}"
        echo -e "    Please install pnpm: npm install -g pnpm"
        exit 1
    fi
    echo -e "${GREEN}[✔] Node.js and pnpm are installed.${NC}"
elif [[ $REPLY_FRONTEND == "2" ]]; then
    echo -e "${GREEN}[✔] Container engine ($CONTAINER_CMD) will build and run the frontend container.${NC}"
fi

read -p "Do you want to proceed with the deployment? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled by user.${NC}"
    exit 0
fi

# Enable required GCP APIs

echo -e "\n${BLUE}Enabling required Google Cloud APIs (this may take a minute)...${NC}"
gcloud services enable \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    firestore.googleapis.com \
    secretmanager.googleapis.com \
    billingbudgets.googleapis.com --quiet
echo -e "${GREEN}[✔] Core APIs successfully enabled.${NC}"

# ====================================================
# STEP 4: Secret Manager Setup
# ====================================================
echo -e "\n${BLUE}[Step 4/8] Configuring Google Cloud Secret Manager...${NC}"
if gcloud secrets describe gemini-api-key &>/dev/null; then
    echo -e "${GREEN}[✔] Secret 'gemini-api-key' already exists. Adding new version...${NC}"
    echo -n "$GEMINI_API_KEY" | gcloud secrets versions add gemini-api-key --data-file=-
else
    echo -e "${YELLOW}[!] Creating new secret 'gemini-api-key'...${NC}"
    echo -n "$GEMINI_API_KEY" | gcloud secrets create gemini-api-key --data-file=- --replication-policy="automatic"
    echo -e "${GREEN}[✔] Secret created successfully.${NC}"
fi

# ====================================================
# STEP 5: Artifact Registry & Build Backend
# ====================================================
echo -e "\n${BLUE}[Step 5/8] Preparing Artifact Registry & Container Build...${NC}"
REPO_NAME="nofoodwaste-repo"
if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$REGION" &>/dev/null; then
    echo -e "${YELLOW}[!] Creating Docker repository '$REPO_NAME' in region '$REGION'...${NC}"
    gcloud artifacts repositories create "$REPO_NAME" \
        --repository-format=docker \
        --location="$REGION" \
        --description="Docker repository for NoFoodWaste"
else
    echo -e "${GREEN}[✔] Docker repository '$REPO_NAME' already exists.${NC}"
fi

echo -e "${BLUE}Configuring container authentication with Artifact Registry...${NC}"
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

BACKEND_IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/backend:latest"
echo -e "${BLUE}Building Backend Container using $CONTAINER_CMD for linux/amd64...${NC}"
$CONTAINER_CMD build --platform linux/amd64 -t "$BACKEND_IMAGE" ./Apps/Backend

echo -e "${BLUE}Pushing Backend Image to Artifact Registry...${NC}"
$CONTAINER_CMD push "$BACKEND_IMAGE"
echo -e "${GREEN}[✔] Backend image pushed successfully.${NC}"

# ====================================================
# STEP 6: Service Account Setup
# ====================================================
echo -e "\n${BLUE}[Step 6/8] Configuring Secure Service Account...${NC}"
SA_NAME="nofoodwaste-backend-sa"
SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
    echo -e "${YELLOW}[!] Creating service account '$SA_NAME'...${NC}"
    gcloud iam service-accounts create "$SA_NAME" --display-name="NoFoodWaste Backend Service Account"
    echo -e "${BLUE}Waiting 10 seconds for service account propagation (eventual consistency)...${NC}"
    sleep 10
else
    echo -e "${GREEN}[✔] Service account '$SA_NAME' already exists.${NC}"
fi

echo -e "${BLUE}Binding Cloud Firestore permissions (datastore.user)...${NC}"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/datastore.user" --quiet >/dev/null

echo -e "${BLUE}Binding Secret Manager secretAccessor permission...${NC}"
gcloud secrets add-iam-policy-binding gemini-api-key \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/secretmanager.secretAccessor" --quiet >/dev/null

echo -e "${GREEN}[✔] Service Account configured securely with least-privileges.${NC}"

# ====================================================
# STEP 7: Deploy Backend to Cloud Run
# ====================================================
echo -e "\n${BLUE}[Step 7/8] Deploying Backend API to Google Cloud Run...${NC}"
gcloud run deploy nofoodwaste-backend \
    --image="$BACKEND_IMAGE" \
    --region="$REGION" \
    --service-account="$SA_EMAIL" \
    --allow-unauthenticated \
    --max-instances=2 \
    --set-env-vars="DB_PROVIDER=firestore,ENVIRONMENT=production,ALLOWED_ORIGINS=*" \
    --set-secrets="GEMINI_API_KEY=gemini-api-key:latest" \
    --port=8000 --quiet

# Extract deployed service URL
BACKEND_URL=$(gcloud run services describe nofoodwaste-backend --region="$REGION" --format='value(status.url)')
echo -e "${GREEN}[✔] Backend deployed successfully at: ${YELLOW}$BACKEND_URL${NC}"

# ====================================================
# STEP 8: Deploy Frontend Options
# ====================================================
echo -e "\n${BLUE}[Step 8/8] Frontend Deployment...${NC}"

if [[ $REPLY_FRONTEND == "1" ]]; then
    echo -e "${BLUE}Deploying Frontend to Firebase Hosting...${NC}"
    if [ ! -d "./Apps/Frontend" ]; then
        echo -e "${RED}[✘] Error: Apps/Frontend directory not found.${NC}"
        exit 1
    fi
    
    cd Apps/Frontend
    
    # Always write/update Firebase files to match the active PROJECT_ID
    echo -e "${BLUE}Updating Firebase configurations for project '$PROJECT_ID'...${NC}"
    cat <<EOF > firebase.json
{
  "hosting": {
    "site": "$PROJECT_ID",
    "public": ".output/public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
EOF

    cat <<EOF > .firebaserc
{
  "projects": {
    "default": "$PROJECT_ID"
  }
}
EOF

    # Export Backend URL for Nuxt build generator
    export NUXT_PUBLIC_API_BASE="$BACKEND_URL"
    echo -e "${BLUE}Generating static site with API Base: $NUXT_PUBLIC_API_BASE...${NC}"
    pnpm install --no-frozen-lockfile
    pnpm run generate
    

    echo -e "${BLUE}Deploying via Firebase CLI...${NC}"
    npx firebase-tools deploy --only hosting --project "$PROJECT_ID"
    cd ../..
    echo -e "${GREEN}[✔] Frontend successfully deployed to Firebase Hosting!${NC}"
    
    # Secure CORS configuration: Update backend env vars with the actual Firebase domains
    echo -e "\n${BLUE}Restricting Backend CORS ALLOWED_ORIGINS to Firebase Hosting domains...${NC}"
    FRONTEND_URL="https://$PROJECT_ID.web.app,https://$PROJECT_ID.firebaseapp.com"
    echo -e "Target Origins: ${YELLOW}$FRONTEND_URL${NC}"
    if gcloud run services update nofoodwaste-backend \
        --region="$REGION" \
        --update-env-vars="^|^ALLOWED_ORIGINS=$FRONTEND_URL" --quiet; then
        echo -e "${GREEN}[✔] Backend CORS successfully restricted to production domains.${NC}"
    else
        echo -e "${RED}[✘] Warning: Failed to update Backend CORS settings. ALLOWED_ORIGINS remains '*'.${NC}"
    fi
    
elif [[ $REPLY_FRONTEND == "2" ]]; then
    FRONTEND_IMAGE="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/frontend:latest"
    echo -e "${BLUE}Building Frontend Container with API URL for linux/amd64...${NC}"
    $CONTAINER_CMD build \
        --platform linux/amd64 \
        --build-arg NUXT_PUBLIC_API_BASE="$BACKEND_URL" \
        -t "$FRONTEND_IMAGE" ./Apps/Frontend
        
    echo -e "${BLUE}Pushing Frontend Image to Artifact Registry...${NC}"
    $CONTAINER_CMD push "$FRONTEND_IMAGE"
    
    echo -e "${BLUE}Deploying Frontend to Cloud Run...${NC}"
    gcloud run deploy nofoodwaste-frontend \
        --image="$FRONTEND_IMAGE" \
        --region="$REGION" \
        --allow-unauthenticated \
        --max-instances=2 \
        --port=80 --quiet
        
    FRONTEND_URL=$(gcloud run services describe nofoodwaste-frontend --region="$REGION" --format='value(status.url)')
    echo -e "${GREEN}[✔] Frontend deployed successfully to Cloud Run at: ${YELLOW}$FRONTEND_URL${NC}"
    
    # Secure CORS configuration: Update backend env vars with the actual Cloud Run frontend URL
    echo -e "\n${BLUE}Restricting Backend CORS ALLOWED_ORIGINS to Cloud Run Frontend URL...${NC}"
    echo -e "Target Origin: ${YELLOW}$FRONTEND_URL${NC}"
    if gcloud run services update nofoodwaste-backend \
        --region="$REGION" \
        --update-env-vars="^|^ALLOWED_ORIGINS=$FRONTEND_URL" --quiet; then
        echo -e "${GREEN}[✔] Backend CORS successfully restricted to production domains.${NC}"
    else
        echo -e "${RED}[✘] Warning: Failed to update Backend CORS settings. ALLOWED_ORIGINS remains '*'.${NC}"
    fi
else
    echo -e "${YELLOW}Skipped Frontend Deployment. You can deploy it manually later!${NC}"
    echo -e "${YELLOW}[!] Note: Backend ALLOWED_ORIGINS is currently set to '*' (open to all).${NC}"
    echo -e "${YELLOW}    Once deployed, update it securely using (escaping commas with ^|^ if multiple URLs are provided):${NC}"
    echo -e "${YELLOW}    gcloud run services update nofoodwaste-backend --region=\"$REGION\" --update-env-vars=\"^|^ALLOWED_ORIGINS=https://[your-frontend-url]\"${NC}"
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉             ${NC}"
echo -e "   Backend API URL: ${YELLOW}$BACKEND_URL${NC}"
echo -e "${GREEN}====================================================${NC}"
