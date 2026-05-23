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
# Translate: NoFoodWaste - App Aktivieren (Start)
echo -e "${BLUE}   NoFoodWaste - App Aktivieren (GCP & Firebase)    ${NC}"
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

# 1. Backend wieder freigeben
echo -e "\n${BLUE}[1/2] Gebe Backend-Zugriff auf Cloud Run frei...${NC}"
if gcloud run services add-iam-policy-binding "$BACKEND_SERVICE" \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --region="$REGION" \
    --quiet >/dev/null; then
    echo -e "${GREEN}[✔] Backend erfolgreich für alle freigegeben.${NC}"
else
    echo -e "${RED}[✘] Fehler beim Freigeben des Backends.${NC}"
    exit 1
fi

# Get backend URL
BACKEND_URL=$(gcloud run services describe "$BACKEND_SERVICE" --region="$REGION" --format='value(status.url)')
echo -e "Backend-URL: ${YELLOW}$BACKEND_URL${NC}"

# 2. Frontend wieder aktivieren (Firebase Hosting neu deployen)
echo -e "\n${BLUE}[2/2] Aktiviere Firebase Hosting wieder...${NC}"

if [ ! -d "./Apps/Frontend" ]; then
    echo -e "${RED}[✘] Fehler: Apps/Frontend-Verzeichnis wurde nicht gefunden.${NC}"
    exit 1
fi

cd Apps/Frontend

# Check if build directory exists
if [ ! -d ".output/public" ]; then
    echo -e "${YELLOW}[!] Generierte Frontend-Dateien (.output/public) fehlen.${NC}"
    echo -e "${BLUE}Starte Build-Prozess...${NC}"
    export NUXT_PUBLIC_API_BASE="$BACKEND_URL"
    pnpm install --no-frozen-lockfile
    pnpm run generate
fi

echo -e "${BLUE}Deploye Frontend auf Firebase Hosting...${NC}"
if npx firebase-tools deploy --only hosting --project "$PROJECT_ID"; then
    echo -e "${GREEN}[✔] Frontend erfolgreich wieder online geschaltet.${NC}"
else
    echo -e "${RED}[✘] Fehler beim Aktivieren von Firebase Hosting.${NC}"
    cd ../..
    exit 1
fi

cd ../..

echo -e "\n${GREEN}====================================================${NC}"
echo -e "${GREEN}   Die Anwendung ist wieder ONLINE! 🚀              ${NC}"
echo -e "   Frontend URL:  ${YELLOW}https://$PROJECT_ID.web.app${NC}"
echo -e "   Backend API:   ${YELLOW}$BACKEND_URL${NC}"
echo -e "${GREEN}====================================================${NC}"
