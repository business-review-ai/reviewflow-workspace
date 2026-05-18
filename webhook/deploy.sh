#!/bin/bash
# =========================================================================
# REVIEWFLOW AI - AUTOMATED DEPLOYMENT WEBHOOK TRIGGER SCRIPT
# Usage: ./deploy.sh [repository_name] [environment]
# =========================================================================

set -e

REPO=$1
ENV=${2:-production} # staging | production
WORKSPACE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." && pwd )"

echo "📂 Project Workspace Directory: $WORKSPACE_DIR"
echo "🛠️ Target Repository: $REPO"
echo "⚙️ Deployment Environment: $ENV"

# 1. Pull latest code from SSH
if [[ "$REPO" == "onboard" ]]; then
    cd "$WORKSPACE_DIR/onboard"
else
    cd "$WORKSPACE_DIR/onboard/$REPO"
fi
echo "🔄 Checking out and pulling master branch..."
git checkout master
git pull origin master

# 2. Rebuild only the changed container in Docker Compose
echo "🐳 Rebuilding target microservice container in '$ENV' environment..."
cd "$WORKSPACE_DIR/onboard/$ENV"

# Re-launch docker-compose build strictly for the updated repository service
if [[ "$REPO" == "backend" ]]; then
    # Prisma migrations run automatically on backend launch inside Docker container!
    docker-compose up -d --build backend
elif [[ "$REPO" == "frontend" ]]; then
    docker-compose up -d --build frontend
elif [[ "$REPO" == "admin" ]]; then
    docker-compose up -d --build admin
elif [[ "$REPO" == "landing" ]]; then
    docker-compose up -d --build landing
elif [[ "$REPO" == "onboard" ]]; then
    echo "📦 Onboarding configurations updated. Re-launching stack..."
    docker-compose up -d --build
else
    echo "⚠️ Unknown service matching repo '$REPO'. Rebuilding entire compose stack..."
    docker-compose up -d --build
fi

echo "🎉 Deployment for service '$REPO' completed successfully!"
