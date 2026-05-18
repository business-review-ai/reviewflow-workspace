#!/bin/bash

# =========================================================================
# REVIEWFLOW AI - MULTI-REPOSITORY GIT UPDATER
# Usage: ./git-pull-all.sh [branch_name] (e.g. develop, staging, main)
# =========================================================================

set -e

# Default branch to pull is develop
BRANCH=${1:-develop}

echo -e "\e[36m🔄 Fetching and pulling branch '$BRANCH' across all microservice repositories...\e[0m"

# Get current script folder and parent workspace folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

REPOS=("reviewflow-workspace" "frontend" "admin" "backend" "landing")

for REPO in "${REPOS[@]}"; do
    if [[ "$REPO" == "reviewflow-workspace" ]]; then
        TARGET_DIR="$SCRIPT_DIR"
    else
        TARGET_DIR="$SCRIPT_DIR/$REPO"
    fi
    
    if [ -d "$TARGET_DIR" ]; then
        echo -e "\e[33m📂 Navigating to '$REPO'...\e[0m"
        cd "$TARGET_DIR"
        
        # Fetch latest refs from remote
        git fetch --all --prune
        
        # Verify if branch exists locally or on remote
        if git show-ref --verify --quiet "refs/heads/$BRANCH" || git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
            # Checkout to the branch (creates local tracking branch if it only exists on remote)
            git checkout "$BRANCH"
            
            # Pull latest changes
            git pull origin "$BRANCH"
            echo -e "\e[32m✅ Success: '$REPO' is up to date with branch '$BRANCH'.\e[0m"
        else
            echo -e "\e[31m⚠️ Warning: Branch '$BRANCH' does not exist in '$REPO'. Skipping pull.\e[0m"
        fi
    else
        echo -e "\e[31m❌ Error: Directory '$REPO' not found side-by-side. Skipping.\e[0m"
    fi
done

echo -e "\e[32m🎉 Git synchronization complete!\e[0m"
