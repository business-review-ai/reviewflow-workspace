#!/bin/bash
# =========================================================================
# REVIEWFLOW AI - MASTER PULL & DEPLOY PIPELINE
# Usage: ./deploy.sh [staging | production]
# =========================================================================

set -e

ENV=${1:-staging}

# Validate environment argument
if [[ "$ENV" != "staging" && "$ENV" != "production" ]]; then
    echo -e "\e[31m❌ Error: Invalid environment specified: '$ENV'\e[0m"
    echo "Usage: ./deploy.sh [staging | production]"
    exit 1
fi

echo -e "\e[36m🔄 Initiating pull and deploy pipeline for environment: '$ENV'...\e[0m"

# Get the absolute folder where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE_DIR="$(pwd)"

echo "📂 Script Folder:    $SCRIPT_DIR"
echo "📂 Current Folder:   $WORKSPACE_DIR"

# 1. Update all repositories
REPOS=("." "frontend" "admin" "backend" "landing")

for REPO in "${REPOS[@]}"; do
    TARGET_DIR="$WORKSPACE_DIR/$REPO"
    if [ -d "$TARGET_DIR" ]; then
        echo -e "\e[33m📥 Pulling latest changes for '$REPO'...\e[0m"
        cd "$TARGET_DIR"
        # Fetch and pull latest branch securely
        git fetch --all --prune
        # Determine the current active branch and pull it
        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        git pull origin "$CURRENT_BRANCH"
        cd "$WORKSPACE_DIR"
    else
        echo -e "\e[31m⚠️ Warning: Repository '$REPO' not found side-by-side. Skipping pull.\e[0m"
    fi
done

# 2. Go to the environment folder and run docker compose
ENV_DIR="$WORKSPACE_DIR/$ENV"

# If environment folder is not in current working folder, copy the template from the script directory
if [ ! -d "$ENV_DIR" ]; then
    echo -e "\e[33m📂 Initializing '$ENV' configuration folder in the current directory...\e[0m"
    mkdir -p "$ENV_DIR"
    cp -r "$SCRIPT_DIR/$ENV/." "$ENV_DIR/"
fi

ENV_FILE="$ENV_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "\e[31m❌ Error: Environment file missing at '$ENV_FILE'\e[0m"
    echo "Please create a secure '.env' file in '$ENV_DIR' before deploying."
    exit 1
fi

echo -e "\e[36m🐳 Launching docker-compose in '$ENV'...\e[0m"
cd "$ENV_DIR"

# Deploy via Docker Compose
docker compose down -v || true
docker compose up -d --build

echo -e "\e[32m🎉 Success! ReviewFlow AI has been updated and is running in '$ENV' mode.\e[0m"
