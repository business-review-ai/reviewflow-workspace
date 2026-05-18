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
# 2. SETUP ENVIRONMENT VARIABLE TEMPLATES
# -------------------------------------------------------------------------
if [[ "$ENV" == "local" ]]; then
    if [ ! -f "$PARENT_DIR/backend/.env" ]; then
        echo "📝 Initializing local environment file (backend/.env)..."
        cat <<EOT > "$PARENT_DIR/backend/.env"
PORT=5000
DATABASE_URL="postgresql://postgres:postgres@db:5432/reviewflow?schema=public"
JWT_SECRET="supersecretjwtkey_$(openssl rand -hex 12 2>/dev/null || echo 'localdefaultsecret')"
OPENAI_API_KEY="sk-xZBhP6XSw5QjM8ZrIwhcR2tOZ4cFw0U2ZGKARYTXfO6xTJYWOzEtlFC9HK0LDc2Y"
OPENAI_BASE_URL="https://api.opencode.ai/v1"
OPENAI_MODEL="MiniMax M2.5 Free"
EOT
    fi

elif [[ "$ENV" == "staging" ]]; then
    if [ ! -f "$PARENT_DIR/backend/.env.staging" ]; then
        echo "📝 Initializing staging environment file (backend/.env.staging)..."
        if [ -f "$PARENT_DIR/backend/.env.staging.example" ]; then
            cp "$PARENT_DIR/backend/.env.staging.example" "$PARENT_DIR/backend/.env.staging"
            echo -e "\e[33m⚠️ Staging file copied from template. Please configure actual staging secrets inside backend/.env.staging\e[0m"
        else
            echo "❌ Warning: staging template not found. Please configure backend/.env.staging manually."
        fi
    fi

elif [[ "$ENV" == "production" ]]; then
    if [ ! -f "$PARENT_DIR/backend/.env.prod" ]; then
        echo "📝 Initializing production environment file (backend/.env.prod)..."
        if [ -f "$PARENT_DIR/backend/.env.prod.example" ]; then
            cp "$PARENT_DIR/backend/.env.prod.example" "$PARENT_DIR/backend/.env.prod"
            echo -e "\e[31m⚠️ Production file copied from template. Please configure live credentials inside backend/.env.prod!\e[0m"
        else
            echo "❌ Warning: production template not found. Please configure backend/.env.prod manually."
        fi
    fi
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
