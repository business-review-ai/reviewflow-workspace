#!/bin/bash

# =========================================================================
# REVIEWFLOW AI - MASTER CLONE & BUILD SHELL SCRIPT
# Supports: local | staging | production
# Usage: ./clone-and-build.sh [environment]
# =========================================================================

set -e

# Default environment is local
ENV=${1:-local}

# Validate input environment
if [[ "$ENV" != "local" && "$ENV" != "staging" && "$ENV" != "production" ]]; then
    echo -e "\e[31m❌ Error: Invalid environment specified: '$ENV'\e[0m"
    echo "Usage: ./clone-and-build.sh [local | staging | production]"
    exit 1
fi

echo -e "\e[36m🚀 Starting ReviewFlow AI deployment pipeline for environment: '$ENV'...\e[0m"

# Get current script folder and parent workspace folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "📂 Project Parent Workspace: $PARENT_DIR"

# -------------------------------------------------------------------------
# 1. CLONE SIDE-BY-SIDE REPOSITORIES
# -------------------------------------------------------------------------
REPOS=("frontend" "admin" "backend" "landing")

for REPO in "${REPOS[@]}"; do
    TARGET_DIR="$PARENT_DIR/$REPO"
    if [ -d "$TARGET_DIR" ]; then
        echo -e "\e[32m✅ Repository '$REPO' is already present.\e[0m"
    else
        if [[ "$ENV" == "local" ]]; then
            CLONE_URL="https://github.com/business-review-ai/$REPO.git"
            echo -e "\e[33m📦 Cloning repository '$REPO' via HTTPS (local environment)...\e[0m"
        else
            CLONE_URL="git@github.com:business-review-ai/$REPO.git"
            echo -e "\e[33m🔑 Cloning repository '$REPO' via SSH (non-local environment)...\e[0m"
        fi
        git clone "$CLONE_URL" "$TARGET_DIR"
    fi
done

# -------------------------------------------------------------------------
# 2. VALIDATE ENVIRONMENT VARIABLE CONFIGURATION
# -------------------------------------------------------------------------
ENV_DIR="$SCRIPT_DIR/$ENV"
ENV_FILE="$ENV_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "\e[31m❌ Error: Environment file missing at '$ENV_FILE'\e[0m"
    echo "Please create a secure '.env' file in '$ENV_DIR' before launching."
    exit 1
else
    echo -e "\e[32m✅ Environment configuration file found at '$ENV_FILE'.\e[0m"
fi

# -------------------------------------------------------------------------
# 3. BUILD AND RUN ENVIRONMENT DOCKER COMPOSE
# -------------------------------------------------------------------------
ENV_DIR="$SCRIPT_DIR/$ENV"

if [ -d "$ENV_DIR" ]; then
    echo -e "\e[36m🐳 Launching docker-compose in '$ENV' subfolder...\e[0m"
    cd "$ENV_DIR"
    
    # Run the build
    docker-compose down -v || true
    docker-compose up -d --build
    
    echo -e "\e[32m🎉 Success! ReviewFlow AI is up and running in '$ENV' mode.\e[0m"
    
    if [[ "$ENV" == "local" ]]; then
        echo "🌐 Frontend URL: http://localhost:3000"
        echo "🛡️ Admin URL:    http://localhost:3001/admin"
    elif [[ "$ENV" == "staging" ]]; then
        echo "🌐 Staging URLs depend on your nginx routing (e.g., http://localhost:4000 & http://localhost:4001/admin)"
    elif [[ "$ENV" == "production" ]]; then
        echo "🌐 Production URLs are configured at https://reviewflow.geetrix.com & https://reviewflow.geetrix.com/admin"
    fi
else
    echo -e "\e[31m❌ Error: Environment directory '$ENV_DIR' does not exist.\e[0m"
    exit 1
fi
