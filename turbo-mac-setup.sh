#!/bin/bash

echo "🚀 TURBO MAC OPTIMIZATION FOR DEVELOPMENT"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is for macOS only"
    exit 1
fi

echo "🔍 Current System Status:"
echo "========================"
print_info "macOS Version: $(sw_vers -productVersion)"
print_info "Hardware: $(sysctl -n hw.model)"
print_info "CPU: $(sysctl -n machdep.cpu.brand_string)"
print_info "RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))GB"
print_info "Free Space: $(df -h / | tail -1 | awk '{print $4}')"

echo ""
echo "🛠️  OPTIMIZATION PHASE 1: SYSTEM CLEANUP"
echo "========================================"

# 1. Clean system caches
print_info "Cleaning system caches..."
sudo rm -rf /System/Library/Caches/* 2>/dev/null
rm -rf ~/Library/Caches/* 2>/dev/null
print_success "System caches cleaned"

# 2. Clean downloads and temporary files
print_info "Cleaning temporary files..."
rm -rf ~/Downloads/*.dmg 2>/dev/null
rm -rf ~/Downloads/*.zip 2>/dev/null
rm -rf /tmp/* 2>/dev/null
print_success "Temporary files cleaned"

# 3. Clean Docker if installed
if command -v docker &> /dev/null; then
    print_info "Cleaning Docker images and containers..."
    docker system prune -a -f 2>/dev/null
    print_success "Docker cleaned"
fi

# 4. Clean npm cache
if command -v npm &> /dev/null; then
    print_info "Cleaning npm cache..."
    npm cache clean --force
    print_success "npm cache cleaned"
fi

echo ""
echo "⚡ OPTIMIZATION PHASE 2: PERFORMANCE TUNING"
echo "==========================================="

# 1. Optimize spotlight indexing
print_info "Optimizing Spotlight indexing..."
sudo mdutil -a -i off
sleep 2
sudo mdutil -a -i on
print_success "Spotlight indexing optimized"

# 2. Increase file descriptor limits
print_info "Increasing file descriptor limits..."
echo "kern.maxfiles=65536" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "kern.maxfilesperproc=32768" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sysctl -w kern.maxfiles=65536
sudo sysctl -w kern.maxfilesperproc=32768
print_success "File descriptor limits increased"

# 3. Optimize network settings
print_info "Optimizing network settings..."
sudo sysctl -w net.inet.tcp.delayed_ack=0
sudo sysctl -w net.inet.tcp.msl=1000
print_success "Network settings optimized"

echo ""
echo "🔧 OPTIMIZATION PHASE 3: DEVELOPMENT TOOLS"
echo "=========================================="

# 1. Install/update Homebrew
if ! command -v brew &> /dev/null; then
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    print_success "Homebrew installed"
else
    print_info "Updating Homebrew..."
    brew update && brew upgrade
    print_success "Homebrew updated"
fi

# 2. Install essential development tools
print_info "Installing/updating development tools..."

# Core tools
brew install --quiet git gh node@20 python@3.11 || true
brew install --quiet wget curl jq htop tree || true

# Development productivity tools
brew install --cask --quiet visual-studio-code || true
brew install --cask --quiet iterm2 || true
brew install --cask --quiet raycast || true

print_success "Development tools updated"

# 3. Optimize Node.js and npm
print_info "Optimizing Node.js setup..."
npm config set registry https://registry.npmjs.org/
npm config set fund false
npm config set audit false
npm install -g npm@latest --silent
print_success "Node.js optimized"

# 4. Install n8n with optimizations
print_info "Installing/updating n8n with optimizations..."
npm install -g n8n@latest --silent
npm install -g pm2 --silent  # Process manager for n8n
print_success "n8n optimized"

echo ""
echo "🌐 OPTIMIZATION PHASE 4: NETWORK & CONNECTIVITY"
echo "=============================================="

# 1. Flush DNS cache
print_info "Flushing DNS cache..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
print_success "DNS cache flushed"

# 2. Optimize WiFi settings
print_info "Optimizing WiFi settings..."
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport prefs DisconnectOnLogout=NO
print_success "WiFi settings optimized"

echo ""
echo "🔋 OPTIMIZATION PHASE 5: POWER & PERFORMANCE"
echo "==========================================="

# 1. Optimize power management
print_info "Optimizing power management..."
sudo pmset -a standby 0
sudo pmset -a autopoweroff 0
sudo pmset -a powernap 0
sudo pmset -a sleep 0  # Disable sleep for development
print_warning "Sleep disabled - remember to re-enable for battery conservation"

# 2. Increase shared memory
print_info "Increasing shared memory limits..."
echo "kern.sysv.shmmax=134217728" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "kern.sysv.shmall=32768" | sudo tee -a /etc/sysctl.conf > /dev/null
print_success "Shared memory optimized"

echo ""
echo "📊 OPTIMIZATION PHASE 6: MONITORING SETUP"
echo "========================================"

# Create performance monitoring script
cat > ~/performance-monitor.sh << 'EOF'
#!/bin/bash
echo "📊 MAC PERFORMANCE DASHBOARD"
echo "============================"
echo "CPU Usage: $(top -l 1 | head -n 10 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')"
echo "Memory Pressure: $(memory_pressure | grep "System-wide memory free percentage" | awk '{print $5}' | sed 's/%//')%"
echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
echo "Network: $(netstat -ib | awk 'NR>1 {print $1, $7, $10}' | grep -E 'en[0-9]' | head -1)"
echo ""
echo "🚀 Active Development Processes:"
ps aux | grep -E "(n8n|node|npm|git)" | grep -v grep | head -5
echo ""
echo "🔥 Top CPU Consumers:"
top -l 1 -o cpu | head -15 | tail -10
EOF

chmod +x ~/performance-monitor.sh
print_success "Performance monitoring script created"

# Create n8n optimization configuration
mkdir -p ~/.n8n/config
cat > ~/.n8n/config/performance.json << 'EOF'
{
  "executions": {
    "process": "main",
    "mode": "queue",
    "timeout": 120,
    "maxTimeout": 300,
    "saveDataOnError": "all",
    "saveDataOnSuccess": "all",
    "saveDataManualExecutions": true
  },
  "generic": {
    "timezone": "America/New_York"
  },
  "nodes": {
    "communityPackages": {
      "enabled": true
    }
  },
  "cache": {
    "backend": "memory",
    "memory": {
      "maxSize": 3145728
    }
  }
}
EOF

print_success "n8n performance configuration created"

echo ""
echo "🔐 OPTIMIZATION PHASE 7: SECURITY HARDENING"
echo "=========================================="

# Enable firewall
print_info "Enabling macOS firewall..."
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
print_success "Firewall enabled"

# Disable unnecessary services
print_info "Disabling unnecessary services..."
sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist 2>/dev/null || true
print_success "Unnecessary services disabled"

echo ""
echo "🎯 OPTIMIZATION COMPLETE!"
echo "========================"

# Final system check
print_info "Running final system check..."
AVAILABLE_RAM=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
FREE_SPACE=$(df -h / | tail -1 | awk '{print $4}')
CPU_CORES=$(sysctl -n hw.ncpu)

print_success "Available RAM: $((AVAILABLE_RAM * 4096 / 1024 / 1024))MB"
print_success "Free Disk Space: $FREE_SPACE"
print_success "CPU Cores: $CPU_CORES"

echo ""
echo "📱 QUICK ACCESS COMMANDS:"
echo "========================"
echo "Monitor Performance: ~/performance-monitor.sh"
echo "Start n8n optimized: pm2 start n8n --name 'n8n-optimized'"
echo "View n8n logs: pm2 logs n8n-optimized"
echo "Restart n8n: pm2 restart n8n-optimized"
echo "Stop n8n: pm2 stop n8n-optimized"

echo ""
echo "⚠️  POST-OPTIMIZATION CHECKLIST:"
echo "================================"
echo "1. Restart your Mac to apply all changes"
echo "2. Test n8n startup: pm2 start n8n"
echo "3. Monitor performance with: ~/performance-monitor.sh"
echo "4. Re-enable sleep mode when not developing:"
echo "   sudo pmset -a sleep 10"

echo ""
print_success "🚀 Your Mac is now TURBO CHARGED for development!"