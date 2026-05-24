#!/usr/bin/env bash

# Exit immediately if any command fails, treat unset variables as an error
set -euo pipefail

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   NoFoodWaste - Workload Identity Federation (WIF) ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Check gcloud CLI
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}[✘] Error: Google Cloud SDK (gcloud) is not installed.${NC}"
    echo -e "    Please install it first, e.g. via Homebrew: brew install --cask google-cloud-sdk"
    exit 1
fi

# 2. Detect active project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}[!] No active gcloud project set.${NC}"
    read -p "Please enter your GCP Project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
else
    echo -e "${GREEN}[✔] Active GCP Project ID: $PROJECT_ID${NC}"
fi

PROJECT_NUM=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
echo -e "${GREEN}[✔] GCP Project Number: $PROJECT_NUM${NC}"

# Constants
GITHUB_REPO="marclabud/nofoodwaste"
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
DEPLOYER_SA="github-actions-deployer"
RUNTIME_SA="nofoodwaste-backend-sa"
REGION="europe-west6"

echo -e "\n${BLUE}--- Target Configuration ---${NC}"
echo -e "GitHub Repository: ${YELLOW}$GITHUB_REPO${NC}"
echo -e "GCP Project ID:    ${YELLOW}$PROJECT_ID${NC}"
echo -e "Deployer SA:       ${YELLOW}$DEPLOYER_SA@$PROJECT_ID.iam.gserviceaccount.com${NC}"
echo -e "Runtime SA:        ${YELLOW}$RUNTIME_SA@$PROJECT_ID.iam.gserviceaccount.com${NC}"
echo -e "${BLUE}----------------------------${NC}"

read -p "Do you want to proceed with creating the WIF resources on GCP? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Setup cancelled.${NC}"
    exit 0
fi

# Enable security and IAM APIs
echo -e "\n${BLUE}[Step 1/5] Enabling required APIs (iamcredentials.googleapis.com)...${NC}"
gcloud services enable iamcredentials.googleapis.com --quiet
echo -e "${GREEN}[✔] API successfully enabled.${NC}"

# 3. Create Deployer Service Account if not exists
echo -e "\n${BLUE}[Step 2/5] Configuring Deployer Service Account...${NC}"
DEPLOYER_SA_EMAIL="$DEPLOYER_SA@$PROJECT_ID.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe "$DEPLOYER_SA_EMAIL" &>/dev/null; then
    echo -e "${YELLOW}[!] Creating Service Account '$DEPLOYER_SA'...${NC}"
    gcloud iam service-accounts create "$DEPLOYER_SA" --display-name="GitHub Actions Deployer Service Account"
    sleep 5
else
    echo -e "${GREEN}[✔] Service Account '$DEPLOYER_SA' already exists.${NC}"
fi

# Assign deployer permissions
echo -e "${BLUE}Assigning Artifact Registry Writer permissions...${NC}"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$DEPLOYER_SA_EMAIL" \
    --role="roles/artifactregistry.writer" --quiet >/dev/null

echo -e "${BLUE}Assigning Cloud Run Developer permissions...${NC}"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$DEPLOYER_SA_EMAIL" \
    --role="roles/run.developer" --quiet >/dev/null

# Allow deployer SA to act as the runtime service account
RUNTIME_SA_EMAIL="$RUNTIME_SA@$PROJECT_ID.iam.gserviceaccount.com"
if gcloud iam service-accounts describe "$RUNTIME_SA_EMAIL" &>/dev/null; then
    echo -e "${BLUE}Allowing Deployer to assume identity of runtime service account '$RUNTIME_SA'...${NC}"
    gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA_EMAIL" \
        --member="serviceAccount:$DEPLOYER_SA_EMAIL" \
        --role="roles/iam.serviceAccountUser" --quiet >/dev/null
else
    echo -e "${YELLOW}[!] Note: Runtime service account '$RUNTIME_SA' not found. Ensure to run localdeploy-to-gcp.sh first!${NC}"
fi

# 4. Create Workload Identity Pool
echo -e "\n${BLUE}[Step 3/5] Configuring Workload Identity Pool...${NC}"
if ! gcloud iam workload-identity-pools describe "$POOL_NAME" --location="global" &>/dev/null; then
    echo -e "${YELLOW}[!] Creating Workload Identity Pool '$POOL_NAME'...${NC}"
    gcloud iam workload-identity-pools create "$POOL_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --display-name="GitHub Actions Pool"
else
    echo -e "${GREEN}[✔] Workload Identity Pool '$POOL_NAME' already exists.${NC}"
fi

# 5. Create OIDC Provider
echo -e "\n${BLUE}[Step 4/5] Configuring OIDC Provider...${NC}"
if ! gcloud iam workload-identity-pools providers describe "$PROVIDER_NAME" \
    --workload-identity-pool="$POOL_NAME" \
    --location="global" &>/dev/null; then
    echo -e "${YELLOW}[!] Creating OIDC Provider '$PROVIDER_NAME'...${NC}"
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
        --project="$PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="$POOL_NAME" \
        --display-name="GitHub Provider" \
        --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
        --attribute-condition="assertion.repository == 'marclabud/nofoodwaste'" \
        --issuer-uri="https://token.actions.githubusercontent.com"
else
    echo -e "${GREEN}[✔] OIDC Provider '$PROVIDER_NAME' already exists.${NC}"
fi

# 6. Bind GitHub Repo to Service Account
echo -e "\n${BLUE}[Step 5/5] Granting access to GitHub Repository...${NC}"
gcloud iam service-accounts add-iam-policy-binding "$DEPLOYER_SA_EMAIL" \
    --project="$PROJECT_ID" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUM/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$GITHUB_REPO" --quiet >/dev/null

echo -e "${GREEN}[✔] Successfully granted permissions to '$GITHUB_REPO'.${NC}"

# 7. Print GitHub YAML Block
PROVIDER_PATH="projects/$PROJECT_NUM/locations/global/workloadIdentityPools/$POOL_NAME/providers/$PROVIDER_NAME"

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   WORKLOAD IDENTITY FEDERATION SETUP COMPLETE! 🎉   ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "Use the following configuration block in your GitHub Actions YAML:"
echo -e ""
echo -e "${YELLOW}----------------------------------------------------${NC}"
echo -e "permissions:"
echo -e "  contents: read"
echo -e "  id-token: write"
echo -e ""
echo -e "steps:"
echo -e "  - name: Checkout Code"
echo -e "    uses: actions/checkout@v4"
echo -e ""
echo -e "  - name: Authenticate to Google Cloud"
echo -e "    uses: google-github-actions/auth@v2"
echo -e "    with:"
echo -e "      token_format: 'access_token'"
echo -e "      workload_identity_provider: '${PROVIDER_PATH}'"
echo -e "      service_account: '${DEPLOYER_SA_EMAIL}'"
echo -e "${YELLOW}----------------------------------------------------${NC}"
echo -e ""
