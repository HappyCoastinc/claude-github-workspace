#!/bin/bash

echo "🚀 Setting up Claude + GitHub + n8n Integration"
echo "=============================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if GitHub CLI is authenticated
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI not authenticated. Please run: gh auth login"
    exit 1
fi

# Check if n8n is installed
if ! command -v n8n &>/dev/null; then
    echo "❌ n8n not found. Installing..."
    npm install -g n8n
fi

echo "✅ Prerequisites checked"

# Create GitHub repository if it doesn't exist
echo "🐙 Setting up GitHub repository..."
if ! gh repo view HappyCoastinc/claude-github-workspace &>/dev/null; then
    gh repo create claude-github-workspace --public --source=. --push
    echo "✅ GitHub repository created"
else
    echo "✅ GitHub repository already exists"
fi

# Add remote if not present
if ! git remote get-url origin &>/dev/null; then
    git remote add origin https://github.com/HappyCoastinc/claude-github-workspace.git
fi

# Commit and push current changes
echo "📤 Pushing integration files to GitHub..."
git add .
git commit -m "feat: Add Claude + n8n + GitHub integration setup

🤖 Generated with Claude Code
https://claude.ai/code

Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin main

echo "🔧 Setting up n8n workflows..."

# Create n8n data directory if it doesn't exist
mkdir -p ~/.n8n

# Instructions for n8n setup
echo ""
echo "🎯 Next Steps:"
echo "=============="
echo "1. Start n8n: npm run n8n:start"
echo "2. Open http://localhost:5678 in your browser"
echo "3. Import the workflow from: ./n8n-workflows/claude-code-assistant.json"
echo "4. Configure credentials:"
echo "   - GitHub OAuth2 app"
echo "   - Anthropic API key"
echo "5. Set GitHub repository secrets:"
echo "   - N8N_WEBHOOK_URL: Your n8n webhook endpoint"
echo ""
echo "🔗 Webhook URLs will be:"
echo "   - Code Analysis: http://your-n8n-instance:5678/webhook/code-analysis"
echo "   - Docs Update: http://your-n8n-instance:5678/webhook/docs-update"
echo "   - Issue Triage: http://your-n8n-instance:5678/webhook/issue-triage"
echo ""
echo "✨ Integration setup complete! Your systems are now connected."