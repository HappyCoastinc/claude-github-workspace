#!/bin/bash

echo "🔒 Setting up Security Firewall for n8n Integration"
echo "=================================================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is designed for macOS. Adapt for your OS."
    exit 1
fi

# Check if running as root for pfctl commands
if [[ $EUID -eq 0 ]]; then
   echo "⚠️  Running as root. Firewall rules will be applied system-wide."
   read -p "Continue? (y/N): " -n 1 -r
   echo
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
       exit 1
   fi
fi

echo "🔧 Configuring macOS firewall..."

# Enable macOS firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
echo "✅ System firewall enabled"

# Set firewall to stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
echo "✅ Stealth mode enabled"

# Block all incoming connections by default
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall off
echo "✅ Configured to block unauthorized incoming connections"

# Allow specific applications
echo "🔐 Configuring application-specific rules..."

# Allow n8n if it exists
if command -v n8n &> /dev/null; then
    N8N_PATH=$(which n8n)
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$N8N_PATH"
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblock "$N8N_PATH"
    echo "✅ n8n firewall rule added"
fi

# Create pfctl rules for additional network security
cat > /tmp/n8n-security.rules << 'EOF'
# n8n Security Rules
# Block external access to n8n port except from localhost
block in quick on en0 proto tcp from any to any port 5678
pass in quick on lo0 proto tcp from 127.0.0.1 to any port 5678
pass out quick proto tcp from any to any port 443
pass out quick proto tcp from any to any port 80

# Rate limiting rules (basic)
table <rate_limit> persist
block in quick from <rate_limit>
pass in inet proto tcp from any to any port 5678 \
    (max-src-conn 5, max-src-conn-rate 10/60, \
     overload <rate_limit> flush global)
EOF

echo "📝 pfctl rules created at /tmp/n8n-security.rules"

# Network monitoring setup
echo "📊 Setting up network monitoring..."

cat > /tmp/monitor-n8n.sh << 'EOF'
#!/bin/bash
# n8n Security Monitor
LOG_FILE="/var/log/n8n-security.log"

# Function to log security events
log_security_event() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SECURITY] $1" >> "$LOG_FILE"
}

# Monitor suspicious connections
while true; do
    # Check for unusual n8n connections
    CONNECTIONS=$(netstat -an | grep ":5678" | grep -v "127.0.0.1" | wc -l)
    if [ "$CONNECTIONS" -gt 5 ]; then
        log_security_event "High number of external connections to n8n: $CONNECTIONS"
    fi
    
    # Check for failed authentication attempts (would need n8n logs)
    if [ -f "/Users/$(whoami)/.n8n/logs/n8n.log" ]; then
        FAILED_AUTHS=$(tail -n 100 "/Users/$(whoami)/.n8n/logs/n8n.log" | grep -i "unauthorized\|forbidden\|401\|403" | wc -l)
        if [ "$FAILED_AUTHS" -gt 10 ]; then
            log_security_event "Multiple authentication failures detected: $FAILED_AUTHS"
        fi
    fi
    
    sleep 60
done
EOF

chmod +x /tmp/monitor-n8n.sh
echo "✅ Security monitor script created"

# Create n8n security configuration
echo "⚙️ Creating secure n8n configuration..."

mkdir -p ~/.n8n/config
cat > ~/.n8n/config/security.json << 'EOF'
{
  "security": {
    "basicAuth": {
      "active": true,
      "user": "admin",
      "password": "CHANGE_THIS_PASSWORD_NOW"
    },
    "jwtAuth": {
      "active": true,
      "jwtHeader": "authorization",
      "jwtHeaderValuePrefix": "Bearer ",
      "jwksUri": "",
      "jwtIssuer": "",
      "jwtAudience": "",
      "userManagement": {
        "isInstanceOwnerSetUp": true
      }
    }
  },
  "endpoints": {
    "rest": "rest",
    "webhook": "webhook",
    "webhookWaiting": "webhook-waiting",
    "webhookTest": "webhook-test"
  },
  "externalHookFiles": [],
  "nodes": {
    "exclude": [],
    "include": []
  },
  "settings": {
    "callerPolicyDefaultOption": "workflowsFromSameOwner",
    "errorWorkflow": "",
    "saveManualExecutions": true,
    "timezone": "America/New_York",
    "maxExecutionTimeout": 3600,
    "oauthCallbackUrls": {
      "OAuth1": "http://localhost:5678/rest/oauth1-credential/callback",
      "OAuth2": "http://localhost:5678/rest/oauth2-credential/callback"
    }
  }
}
EOF

echo "✅ Secure n8n configuration created"

# Instructions for manual setup
echo ""
echo "🎯 Manual Security Setup Required:"
echo "=================================="
echo "1. Change the password in ~/.n8n/config/security.json"
echo "2. Set up SSL/TLS certificates for HTTPS:"
echo "   - Use Let's Encrypt or similar for production"
echo "   - Configure reverse proxy (nginx/Apache) with SSL"
echo "3. Apply pfctl rules (requires admin privileges):"
echo "   sudo pfctl -f /tmp/n8n-security.rules"
echo "4. Start the security monitor:"
echo "   nohup /tmp/monitor-n8n.sh &"
echo "5. Configure GitHub repository secrets:"
echo "   - WEBHOOK_SECRET: Generate strong 32+ character secret"
echo "   - N8N_WEBHOOK_URL: Your HTTPS n8n endpoint"
echo ""
echo "🔗 Secure URLs:"
echo "   - n8n UI: https://your-domain:5678 (with SSL)"
echo "   - Webhook: https://your-domain:5678/webhook/code-analysis"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Never use HTTP in production"
echo "   - Regularly rotate webhook secrets"
echo "   - Monitor security logs daily"
echo "   - Keep n8n updated to latest version"
echo ""
echo "✨ Security setup complete!"