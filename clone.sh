#!/bin/bash
# =========================================================================
# REVIEWFLOW AI - CLONE ALL REPOSITORIES
# Usage: ./clone.sh [local | other]
# =========================================================================

set -e

ENV=${1:-local}
REPOS=("frontend" "admin" "backend" "landing")

echo "🚀 Cloning all ReviewFlow AI repositories into the current directory..."
echo "⚙️ Protocol: $([ "$ENV" == "local" ] && echo "HTTPS" || echo "SSH")"

for REPO in "${REPOS[@]}"; do
    if [ -d "$REPO" ]; then
        echo "✅ Repository '$REPO' is already present."
    else
        if [[ "$ENV" == "local" ]]; then
            CLONE_URL="https://github.com/business-review-ai/$REPO.git"
        else
            CLONE_URL="git@github.com:business-review-ai/$REPO.git"
        fi
        echo "📦 Cloning '$REPO'..."
        git clone "$CLONE_URL"
    fi
done

echo "🎉 All repositories successfully processed!"
