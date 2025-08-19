#!/bin/bash

echo "👥 TEAM COLLABORATION SETUP"
echo "============================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# 1. Set up GitHub repository for team collaboration
print_info "Setting up GitHub repository for team access..."

# Add team collaborators (add actual team member usernames)
TEAM_MEMBERS=("teammate1" "teammate2" "designer1" "developer1")

print_info "Repository settings configuration..."
gh repo edit --enable-issues --enable-projects --enable-wiki
gh repo edit --allow-merge-commit --allow-squash-merge --allow-rebase-merge

# Set up branch protection
print_info "Setting up branch protection rules..."
gh api repos/HappyCoastinc/claude-github-workspace/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["trigger-n8n-workflows"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true}' \
  --field restrictions=null

# 2. Create team development guidelines
cat > TEAM_GUIDELINES.md << 'EOF'
# 👥 Team Development Guidelines

## 🚀 Getting Started

### Prerequisites
- macOS with latest updates
- GitHub CLI: `brew install gh`
- Node.js 18+: `brew install node@18`
- n8n: `npm install -g n8n`

### Initial Setup
```bash
# 1. Clone repository
git clone https://github.com/HappyCoastinc/claude-github-workspace.git
cd claude-github-workspace

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env
# Edit .env with your API keys

# 4. Run secure deployment
./deploy-secure.sh
```

## 🔧 Development Workflow

### Branch Strategy
- `main` - Production ready code
- `develop` - Integration branch
- `feature/*` - New features
- `hotfix/*` - Critical fixes

### Pull Request Process
1. Create feature branch: `git checkout -b feature/amazing-feature`
2. Make changes and commit: `git commit -m "feat: add amazing feature"`
3. Push branch: `git push -u origin feature/amazing-feature`
4. Create PR: `gh pr create --title "Amazing Feature" --body "Description"`
5. Wait for Claude AI review
6. Address feedback and merge

### Code Standards
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- All PRs require AI + human review
- Security scans must pass
- Tests required for new features

## 🤖 AI Integration

### Claude Code Assistant
- Automatically reviews all PRs
- Identifies security vulnerabilities
- Suggests improvements
- Posts detailed analysis comments

### Workflow Triggers
- **PR Created/Updated** → Code analysis
- **Push to main** → Documentation updates
- **Issue Created** → Auto-triage and labeling

## 🛡️ Security

### Required Environment Variables
```bash
WEBHOOK_SECRET=your-secure-secret
N8N_WEBHOOK_URL=https://your-n8n-instance.com
GITHUB_TOKEN=ghp_your_token
ANTHROPIC_API_KEY=sk-your_key
```

### Security Monitoring
- Real-time dashboard: `node security/monitoring-dashboard.js`
- Security logs: `~/.n8n/logs/security.log`
- Weekly security reviews required

## 📱 Content Creator Workflows

### Instagram Integration
- Automated post scheduling
- Image processing and optimization
- Hashtag generation
- Performance analytics

### Twitter Integration
- Thread creation and posting
- Engagement tracking
- Trend analysis
- Auto-replies

## 🆘 Troubleshooting

### Common Issues
1. **n8n won't start**: Check port 5678 availability
2. **Webhook failures**: Verify WEBHOOK_SECRET matches
3. **API rate limits**: Monitor usage in dashboard

### Getting Help
- Check security logs first
- Review GitHub Actions output
- Post in team Slack #dev-support
- Create GitHub issue for bugs
EOF

# 3. Set up GitHub issue templates
mkdir -p .github/ISSUE_TEMPLATE

cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description
A clear and concise description of what the bug is.

## 🔄 Steps to Reproduce
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

## ✅ Expected Behavior
A clear and concise description of what you expected to happen.

## 📱 Environment
- OS: [e.g. macOS 13.4]
- Browser: [e.g. Chrome 115]
- n8n Version: [e.g. 1.106.3]
- Node Version: [e.g. 18.16.0]

## 📸 Screenshots
If applicable, add screenshots to help explain your problem.

## 🔍 Additional Context
Add any other context about the problem here.
EOF

cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: Feature Request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## 🚀 Feature Description
A clear and concise description of what you want to happen.

## 🤔 Problem Statement
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

## 💡 Proposed Solution
A clear and concise description of what you want to happen.

## 🔄 Alternatives Considered
A clear and concise description of any alternative solutions or features you've considered.

## 📋 Acceptance Criteria
- [ ] Criteria 1
- [ ] Criteria 2
- [ ] Criteria 3

## 🔍 Additional Context
Add any other context or screenshots about the feature request here.
EOF

# 4. Create team-specific scripts
cat > team-scripts/quick-setup.sh << 'EOF'
#!/bin/bash
echo "🚀 Quick Team Member Setup"
echo "=========================="

# Check prerequisites
print_status() { echo "✅ $1"; }
print_error() { echo "❌ $1"; }

# Check GitHub CLI
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI not installed. Run: brew install gh"
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js not installed. Run: brew install node@18"
    exit 1
fi

# Check n8n
if ! command -v n8n &> /dev/null; then
    echo "Installing n8n..."
    npm install -g n8n
fi

print_status "All prerequisites installed!"

# Authenticate with GitHub
if ! gh auth status &>/dev/null; then
    echo "🔐 GitHub authentication required"
    gh auth login
fi

print_status "GitHub authenticated!"

# Set up environment
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo "⚠️  Please edit .env file with your API keys"
    open -a TextEdit .env
else
    print_status ".env file already exists"
fi

echo "🎉 Setup complete! Run './deploy-secure.sh' to start."
EOF

mkdir -p team-scripts
chmod +x team-scripts/quick-setup.sh

# 5. Set up repository insights
print_info "Configuring repository insights..."

# Enable security features
gh api repos/HappyCoastinc/claude-github-workspace \
  --method PATCH \
  --field has_issues=true \
  --field has_projects=true \
  --field has_wiki=true \
  --field security_and_analysis='{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}'

print_success "Team collaboration setup complete!"

echo ""
echo "📋 NEXT STEPS FOR TEAM MEMBERS:"
echo "================================"
echo "1. Clone repository: git clone https://github.com/HappyCoastinc/claude-github-workspace.git"
echo "2. Run setup script: ./team-scripts/quick-setup.sh"
echo "3. Configure .env file with API keys"
echo "4. Deploy: ./deploy-secure.sh"
echo "5. Read TEAM_GUIDELINES.md for full workflow"
echo ""
echo "🔗 Repository: https://github.com/HappyCoastinc/claude-github-workspace"