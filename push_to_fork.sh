#!/bin/bash

# Helper script to push changes to your GitHub fork
# Usage: ./push_to_fork.sh YOUR_GITHUB_USERNAME

if [ -z "$1" ]; then
    echo "❌ Error: Please provide your GitHub username"
    echo ""
    echo "Usage: ./push_to_fork.sh YOUR_GITHUB_USERNAME"
    echo ""
    echo "Example: ./push_to_fork.sh hanifm"
    exit 1
fi

GITHUB_USERNAME="$1"
FORK_URL="https://github.com/${GITHUB_USERNAME}/ai-chatbot-vllm.git"

echo "🚀 Pushing to your GitHub fork..."
echo "   Fork URL: $FORK_URL"
echo ""

# Check if fork remote already exists
if git remote get-url fork &>/dev/null; then
    echo "📝 Updating existing 'fork' remote..."
    git remote set-url fork "$FORK_URL"
else
    echo "➕ Adding 'fork' remote..."
    git remote add fork "$FORK_URL"
fi

# Push to fork
echo "📤 Pushing to fork..."
if git push fork main; then
    echo ""
    echo "✅ Successfully pushed to your fork!"
    echo "   View at: $FORK_URL"
else
    echo ""
    echo "❌ Push failed. Make sure:"
    echo "   1. You've forked the repo at: https://github.com/lalanikarim/ai-chatbot-vllm"
    echo "   2. Your GitHub username is correct: $GITHUB_USERNAME"
    echo "   3. You have push access to your fork"
    exit 1
fi

