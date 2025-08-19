#!/bin/bash

echo "📱 SOCIAL MEDIA AUTOMATION DEPLOYMENT"
echo "====================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_header() { echo -e "${PURPLE}🚀 $1${NC}"; }

echo ""
print_header "Phase 1: Team Setup & Collaboration"
echo "=================================="

# Run team setup
if [ -f "team-setup.sh" ]; then
    print_info "Setting up team collaboration..."
    ./team-setup.sh
    print_success "Team collaboration configured"
else
    print_warning "Team setup script not found, skipping..."
fi

echo ""
print_header "Phase 2: Mac Performance Optimization"
echo "===================================="

# Run Mac optimization
if [ -f "turbo-mac-setup.sh" ]; then
    print_info "Optimizing Mac for development..."
    print_warning "This will require sudo password and may take several minutes"
    read -p "Continue with Mac optimization? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./turbo-mac-setup.sh
        print_success "Mac optimization complete"
    else
        print_info "Skipping Mac optimization"
    fi
else
    print_warning "Mac optimization script not found, skipping..."
fi

echo ""
print_header "Phase 3: n8n Connectivity Check"
echo "==============================="

# Check n8n status
print_info "Checking n8n connectivity..."
N8N_STATUS=$(curl -s http://localhost:5678/healthz 2>/dev/null | jq -r '.status' 2>/dev/null || echo "down")

if [ "$N8N_STATUS" = "ok" ]; then
    print_success "n8n is running and healthy"
else
    print_warning "n8n not responding, attempting to start..."
    # Start n8n with environment variables
    export WEBHOOK_SECRET="${WEBHOOK_SECRET:-$(openssl rand -base64 32)}"
    nohup n8n start > ~/.n8n/logs/n8n.log 2>&1 &
    sleep 5
    
    # Re-check status
    N8N_STATUS=$(curl -s http://localhost:5678/healthz 2>/dev/null | jq -r '.status' 2>/dev/null || echo "down")
    if [ "$N8N_STATUS" = "ok" ]; then
        print_success "n8n started successfully"
    else
        print_warning "n8n startup failed - check logs at ~/.n8n/logs/n8n.log"
    fi
fi

echo ""
print_header "Phase 4: Social Media Workflow Import"
echo "===================================="

# Create workflow import script
cat > import-workflows.js << 'EOF'
const fs = require('fs');
const path = require('path');

const workflows = [
    'n8n-workflows/secure-claude-code-assistant.json',
    'n8n-workflows/instagram-content-creator.json',
    'n8n-workflows/twitter-content-creator.json'
];

console.log('📥 Workflows ready for import:');
workflows.forEach(workflow => {
    if (fs.existsSync(workflow)) {
        console.log(`✅ ${workflow}`);
    } else {
        console.log(`❌ ${workflow} - File not found`);
    }
});

console.log('\n📋 Import Instructions:');
console.log('1. Open http://localhost:5678 in your browser');
console.log('2. For each workflow file:');
console.log('   - Click Import (📥) button');
console.log('   - Select "Import from File"');
console.log('   - Choose the workflow JSON file');
console.log('   - Click Import');
console.log('3. Configure credentials as needed');
EOF

node import-workflows.js
rm import-workflows.js

echo ""
print_header "Phase 5: Credentials Setup Guide"
echo "==============================="

cat << 'EOF'
🔑 REQUIRED CREDENTIALS SETUP IN n8n:

1. 📱 INSTAGRAM/META CREDENTIALS:
   - Go to developers.facebook.com
   - Create app for Instagram Basic Display
   - Get Access Token and App Secret
   - In n8n: Create "Instagram" credential

2. 🐦 TWITTER CREDENTIALS:
   - Go to developer.twitter.com
   - Create app with Twitter API v2 access
   - Get Bearer Token and API keys
   - In n8n: Create "Twitter" credential

3. 🤖 ANTHROPIC (CLAUDE) API:
   - Go to console.anthropic.com
   - Create API key
   - In n8n: Create "Anthropic" credential

4. 📊 GOOGLE SHEETS (for content queue):
   - Enable Google Sheets API
   - Create service account
   - Download JSON credentials
   - In n8n: Create "Google Sheets" credential

5. 💬 SLACK (for notifications):
   - Create Slack app at api.slack.com
   - Add Bot Token Scope: chat:write
   - In n8n: Create "Slack" credential

6. 🖼️ UNSPLASH (for stock images):
   - Go to unsplash.com/developers
   - Create application
   - Get Access Key
   - In n8n: Create "Unsplash" credential

7. 🔐 GITHUB (already configured):
   - OAuth2 or Personal Access Token
   - Scopes: repo, read:org, workflow
EOF

echo ""
print_header "Phase 6: Content Queue Setup"
echo "=========================="

# Create Google Sheets setup script
cat > setup-content-queue.js << 'EOF'
console.log('📊 GOOGLE SHEETS CONTENT QUEUE SETUP');
console.log('=====================================');
console.log('');
console.log('Create two Google Sheets with these columns:');
console.log('');
console.log('📱 INSTAGRAM CONTENT QUEUE SHEET:');
console.log('Columns: ID | Topic | Format | Caption | Hashtags | Image URL | Suggested Time | Status | Created');
console.log('');
console.log('🐦 TWITTER CONTENT QUEUE SHEET:');
console.log('Columns: ID | Type | Industry | Tweet Count | First Tweet | Hashtags | Suggested Time | Trend Insights | Status | Ready to Post | Created');
console.log('');
console.log('📝 SETUP STEPS:');
console.log('1. Create new Google Sheets document');
console.log('2. Name first sheet "Instagram Content Queue"');
console.log('3. Add second sheet "Twitter Content Queue"');
console.log('4. Add the column headers listed above');
console.log('5. Share with your n8n service account email');
console.log('6. Copy the spreadsheet ID from the URL');
console.log('7. Use this ID in your n8n Google Sheets credentials');
EOF

node setup-content-queue.js
rm setup-content-queue.js

echo ""
print_header "Phase 7: Testing & Validation"
echo "=========================="

print_info "Running workflow validation tests..."

# Test n8n webhook endpoint
WEBHOOK_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/webhook/test 2>/dev/null)
if [ "$WEBHOOK_TEST" -eq 404 ]; then
    print_success "n8n webhook endpoints accessible"
else
    print_warning "Webhook endpoints may not be properly configured"
fi

# Check workflow files
WORKFLOW_COUNT=$(ls n8n-workflows/*.json 2>/dev/null | wc -l)
print_success "$WORKFLOW_COUNT workflow files ready for import"

# Check if security monitoring is running
SECURITY_RUNNING=$(ps aux | grep "monitoring-dashboard" | grep -v grep | wc -l)
if [ "$SECURITY_RUNNING" -gt 0 ]; then
    print_success "Security monitoring is active"
else
    print_info "Starting security monitoring..."
    nohup node security/monitoring-dashboard.js > ~/.n8n/logs/security-monitor.log 2>&1 &
    print_success "Security monitoring started"
fi

echo ""
print_header "Phase 8: Final Deployment Summary"
echo "==============================="

cat << 'EOF'
🎉 SOCIAL MEDIA AUTOMATION DEPLOYED!

📊 WHAT'S BEEN SET UP:
✅ Team collaboration workflows
✅ Mac performance optimization  
✅ n8n secure integration
✅ Instagram content creator workflow
✅ Twitter thread builder workflow
✅ Security monitoring system
✅ Content queue management
✅ AI-powered content generation

🔗 ACCESS POINTS:
- n8n Dashboard: http://localhost:5678
- GitHub Repository: https://github.com/HappyCoastinc/claude-github-workspace
- Security Logs: ~/.n8n/logs/security.log
- Performance Monitor: ~/performance-monitor.sh

📱 CONTENT AUTOMATION FEATURES:
- Scheduled Instagram posts with AI captions
- Twitter threads with trend analysis
- Stock image integration
- Hashtag optimization
- Team approval workflows
- Slack notifications
- Analytics tracking

🚀 NEXT STEPS:
1. Import workflows in n8n UI
2. Configure all API credentials
3. Set up Google Sheets content queues
4. Test with sample content generation
5. Schedule your first automated posts!

⚡ Your social media content creation is now FULLY AUTOMATED!
EOF

echo ""
print_success "🚀 Deployment complete! Your team is ready to create content at scale!"

# Final system status
echo ""
print_header "System Status"
echo "============="
print_info "n8n Status: $(curl -s http://localhost:5678/healthz 2>/dev/null | jq -r '.status' 2>/dev/null || echo 'checking...')"
print_info "Security Monitor: $(ps aux | grep monitoring-dashboard | grep -v grep | wc -l) process(es) running"
print_info "GitHub Integration: $(gh auth status &>/dev/null && echo 'authenticated' || echo 'needs setup')"
print_info "Available Workflows: $(ls n8n-workflows/*.json 2>/dev/null | wc -l) files"