#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# NoFoodWaste Podman Orchestration Script
# Designed for seamless local execution using native Podman without Compose.
# -----------------------------------------------------------------------------

set -e

# Styling helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print banner
echo -e "${CYAN}${BOLD}"
echo "========================================================"
echo "    _   _       _____              _ _   _              "
echo "   | \ | | ___ |  ___|__   ___   __| | | | | __ _ ___   "
echo "   |  \| |/ _ \| |_ / _ \ / _ \ / _\` | | | |/ _\` / __|  "
echo "   | |\  | (_) |  _| (_) | (_) | (_| | |_| | (_| \__ \  "
echo "   |_| \_|\___/|_|  \___/ \___/ \__,_|\___/ \__,_|___/  "
echo "                                                        "
echo "            NoFoodWaste Podman Orchestration            "
echo "========================================================"
echo -e "${NC}"

# Check for Podman installation
if ! command -v podman &> /dev/null; then
    echo -e "${RED}Error: podman command not found.${NC}"
    echo -e "Please ensure Podman is installed and in your PATH."
    echo -e "Currently expecting it at /opt/podman/bin/podman or similar."
    exit 1
fi

# Ensure Podman machine is running (macOS specific)
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACHINE_STATUS=$(podman machine list --format "{{.Active}}" 2>/dev/null || echo "unknown")
    if [[ "$MACHINE_STATUS" != *"true"* ]]; then
        echo -e "${YELLOW}Warning: Podman machine may not be running.${NC}"
        echo -e "Attempting to start Podman machine..."
        podman machine start || echo -e "${BLUE}Note: If the machine was already started or not initialized, please ignore any start errors.${NC}"
    fi
fi

# Configuration and Paths
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_ENV="$ROOT_DIR/Apps/Backend/.env"
NETWORK_NAME="nofoodwaste-net"
VOLUME_NAME="nofoodwaste-sqlite"
BACKEND_IMAGE="nofoodwaste-backend"
FRONTEND_IMAGE="nofoodwaste-frontend"
BACKEND_CONTAINER="nofoodwaste-backend"
FRONTEND_CONTAINER="nofoodwaste-frontend"

# Load backend env variables
if [ -f "$BACKEND_ENV" ]; then
    echo -e "${GREEN}✓ Found backend .env file.${NC}"
    # Source variables silently, ignoring comments
    export $(grep -v '^#' "$BACKEND_ENV" | xargs)
else
    echo -e "${YELLOW}⚠ Backend .env file not found at $BACKEND_ENV.${NC}"
    echo -e "Will fallback to standard defaults."
fi

# Set defaults if not provided in environment
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
LLM_MODEL="${LLM_MODEL:-gemini-2.5-flash}"
DEBUG="${DEBUG:-False}"
ENVIRONMENT="${ENVIRONMENT:-production}"
ALLOWED_ORIGINS="${ALLOWED_ORIGINS:-http://localhost:3000}"

# Function to clean up containers
cleanup() {
    echo -e "${BLUE}Stopping and removing existing containers...${NC}"
    podman stop "$FRONTEND_CONTAINER" "$BACKEND_CONTAINER" &>/dev/null || true
    podman rm "$FRONTEND_CONTAINER" "$BACKEND_CONTAINER" &>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete.${NC}"
}

# Function to setup networks and volumes
setup_resources() {
    echo -e "${BLUE}Configuring network and volume resources...${NC}"
    
    # Check if network exists
    if ! podman network inspect "$NETWORK_NAME" &>/dev/null; then
        echo -e "Creating network ${YELLOW}$NETWORK_NAME${NC}..."
        podman network create "$NETWORK_NAME"
    fi
    
    # Check if volume exists
    if ! podman volume inspect "$VOLUME_NAME" &>/dev/null; then
        echo -e "Creating persistent SQLite volume ${YELLOW}$VOLUME_NAME${NC}..."
        podman volume create "$VOLUME_NAME"
    fi
    echo -e "${GREEN}✓ Resources configured successfully.${NC}"
}

# Function to build images
build_images() {
    echo -e "${CYAN}${BOLD}Building Backend Image...${NC}"
    podman build -t "$BACKEND_IMAGE" -f "$ROOT_DIR/Apps/Backend/Dockerfile" "$ROOT_DIR/Apps/Backend"
    
    echo -e "\n${CYAN}${BOLD}Building Frontend Image...${NC}"
    podman build -t "$FRONTEND_IMAGE" -f "$ROOT_DIR/Apps/Frontend/Dockerfile" "$ROOT_DIR/Apps/Frontend"
    
    echo -e "\n${GREEN}✓ Both images built successfully!${NC}"
}

# Function to start containers
start_containers() {
    cleanup
    setup_resources
    
    echo -e "\n${CYAN}${BOLD}Starting Backend Container...${NC}"
    if [ -z "$GEMINI_API_KEY" ]; then
        echo -e "${YELLOW}⚠ WARNING: GEMINI_API_KEY is unset.${NC}"
        echo -e "Please ensure to update your API key in: ${BOLD}Apps/Backend/.env${NC}"
    fi
    
    podman run -d \
        --name "$BACKEND_CONTAINER" \
        --network "$NETWORK_NAME" \
        --network-alias backend \
        -p 8000:8000 \
        -v "$VOLUME_NAME:/app/data" \
        --env-file "$BACKEND_ENV" \
        "$BACKEND_IMAGE"
        
    echo -e "${GREEN}✓ Backend started at http://localhost:8000${NC}"
    
    echo -e "\n${CYAN}${BOLD}Starting Frontend Container...${NC}"
    podman run -d \
        --name "$FRONTEND_CONTAINER" \
        --network "$NETWORK_NAME" \
        -p 3000:80 \
        "$FRONTEND_IMAGE"
        
    echo -e "${GREEN}✓ Frontend started at http://localhost:3000${NC}"
    
    echo -e "\n${GREEN}${BOLD}========================================================${NC}"
    echo -e "${GREEN}${BOLD} 🎉 SUCCESS: NoFoodWaste is now running!${NC}"
    echo -e " 👉 Frontend UI:   ${CYAN}${BOLD}http://localhost:3000${NC}"
    echo -e " 👉 Backend API:  ${CYAN}${BOLD}http://localhost:8000${NC}"
    echo -e " 👉 API Docs:      ${CYAN}${BOLD}http://localhost:8000/docs${NC}"
    echo -e "${GREEN}${BOLD}========================================================${NC}"
    echo -e "Use ${BOLD}./run-podman.sh logs${NC} to view running logs."
    echo -e "Use ${BOLD}./run-podman.sh down${NC} to stop the application."
}

# Function to show logs
show_logs() {
    echo -e "${CYAN}=== Backend Logs ===${NC}"
    podman logs --tail 20 "$BACKEND_CONTAINER" || true
    echo -e "\n${CYAN}=== Frontend Logs ===${NC}"
    podman logs --tail 20 "$FRONTEND_CONTAINER" || true
    
    echo -e "\n${YELLOW}Streaming logs from both containers (Ctrl+C to stop)...${NC}"
    podman logs -f "$BACKEND_CONTAINER" "$FRONTEND_CONTAINER" 2>/dev/null || \
    (echo -e "${BLUE}Streaming ended or one container was not running.${NC}")
}

# Function to check status
check_status() {
    echo -e "${CYAN}${BOLD}Application Container Status:${NC}"
    podman ps -a --filter name="nofoodwaste-*" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Main command router
COMMAND="${1:-up}"

case "$COMMAND" in
    build)
        build_images
        ;;
    up)
        # If images don't exist, build them first
        if ! podman image inspect "$BACKEND_IMAGE" &>/dev/null || ! podman image inspect "$FRONTEND_IMAGE" &>/dev/null; then
            echo -e "${YELLOW}Container images not found. Initiating full build first...${NC}"
            build_images
        fi
        start_containers
        ;;
    down)
        cleanup
        ;;
    logs)
        show_logs
        ;;
    status)
        check_status
        ;;
    restart)
        cleanup
        start_containers
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo "Usage: $0 {up|down|build|restart|status|logs}"
        exit 1
        ;;
esac
