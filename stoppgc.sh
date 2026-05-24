#!/usr/bin/env bash

# Exit immediately if any command fails, treat unset variables as an error, and catch pipeline failures
set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
# Translate: NoFoodWaste - App Deaktivieren (Stop)
echo -e "${BLUE}   NoFoodWaste - App Deaktivieren (GCP & Firebase)  ${NC}"
echo -e "${BLUE}====================================================${NC}"

# Detect active project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID="my-first-project-9510f"
fi

REGION="europe-west6"
BACKEND_SERVICE="nofoodwaste-backend"

echo -e "Projekt-ID:  ${YELLOW}$PROJECT_ID${NC}"
echo -e "Backend:     ${YELLOW}$BACKEND_SERVICE${NC}"
echo -e "Region:      ${YELLOW}$REGION${NC}"
echo -e "----------------------------------------------------"

# 1. Backend offline nehmen (Cloud Run Zugriff sperren)
echo -e "\n${BLUE}[1/2] Sperre Backend-Zugriff auf Cloud Run...${NC}"
if gcloud run services remove-iam-policy-binding "$BACKEND_SERVICE" \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --region="$REGION" \
    --quiet; then
    echo -e "${GREEN}[✔] Backend erfolgreich gesperrt (403 Forbidden).${NC}"
else
    echo -e "${RED}[✘] Fehler beim Sperren des Backends.${NC}"
fi

# 2. Frontend offline nehmen (Firebase Hosting deaktivieren)
echo -e "\n${BLUE}[2/2] Deaktiviere Firebase Hosting...${NC}"
if npx firebase-tools hosting:disable --project "$PROJECT_ID" --force; then
    echo -e "${GREEN}[✔] Frontend erfolgreich offline genommen.${NC}"
else
    echo -e "${RED}[✘] Fehler beim Deaktivieren von Firebase Hosting.${NC}"
fi

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   Die Anwendung ist nun OFFLINE! 🛑                ${NC}"
echo -e "${GREEN}====================================================${NC}"
