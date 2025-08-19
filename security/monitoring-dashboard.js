#!/usr/bin/env node

/**
 * Security Monitoring Dashboard for Claude + GitHub + n8n Integration
 * Real-time security monitoring and alerting system
 */

const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const crypto = require('crypto');

class SecurityMonitor {
    constructor() {
        this.logFile = '/var/log/n8n-security.log';
        this.alertThresholds = {
            failedWebhooks: 5,
            invalidSignatures: 3,
            rateLimitHits: 10,
            suspiciousConnections: 5
        };
        this.monitoringInterval = 30000; // 30 seconds
        this.lastCheck = Date.now();
        this.alerts = [];
        
        this.initializeMonitoring();
    }

    initializeMonitoring() {
        console.log('🛡️  Starting Security Monitor...');
        console.log(`📊 Log file: ${this.logFile}`);
        console.log(`⏰ Check interval: ${this.monitoringInterval}ms`);
        
        // Ensure log directory exists
        const logDir = path.dirname(this.logFile);
        if (!fs.existsSync(logDir)) {
            try {
                fs.mkdirSync(logDir, { recursive: true });
            } catch (error) {
                console.error(`❌ Cannot create log directory: ${error.message}`);
                this.logFile = path.join(process.env.HOME, '.n8n', 'security.log');
                console.log(`📝 Using alternative log file: ${this.logFile}`);
            }
        }

        this.startMonitoring();
    }

    startMonitoring() {
        setInterval(() => {
            this.performSecurityChecks();
        }, this.monitoringInterval);

        // Initial check
        this.performSecurityChecks();
    }

    async performSecurityChecks() {
        const timestamp = new Date().toISOString();
        console.log(`\n🔍 [${timestamp}] Performing security checks...`);

        try {
            await Promise.all([
                this.checkNetworkConnections(),
                this.checkN8nLogs(),
                this.checkSystemResources(),
                this.checkWebhookHealth(),
                this.checkFailedAuthentications()
            ]);

            this.generateSecurityReport();
        } catch (error) {
            this.logSecurityEvent('error', `Security check failed: ${error.message}`);
        }
    }

    async checkNetworkConnections() {
        return new Promise((resolve) => {
            exec('netstat -an | grep ":5678"', (error, stdout) => {
                if (error) {
                    resolve();
                    return;
                }

                const connections = stdout.split('\n').filter(line => line.trim());
                const externalConnections = connections.filter(line => 
                    !line.includes('127.0.0.1') && !line.includes('::1')
                );

                if (externalConnections.length > this.alertThresholds.suspiciousConnections) {
                    this.triggerAlert('network', 
                        `High number of external connections to n8n: ${externalConnections.length}`,
                        'medium'
                    );
                }

                this.logSecurityEvent('info', 
                    `Network check: ${connections.length} total, ${externalConnections.length} external`
                );
                resolve();
            });
        });
    }

    async checkN8nLogs() {
        const n8nLogPath = path.join(process.env.HOME, '.n8n', 'logs', 'n8n.log');
        
        if (!fs.existsSync(n8nLogPath)) {
            return;
        }

        try {
            const logContent = fs.readFileSync(n8nLogPath, 'utf8');
            const recentLogs = this.getRecentLogEntries(logContent);

            // Check for errors
            const errors = recentLogs.filter(log => 
                log.includes('ERROR') || log.includes('error')
            );

            // Check for authentication failures
            const authFailures = recentLogs.filter(log =>
                log.includes('401') || log.includes('403') || 
                log.includes('unauthorized') || log.includes('forbidden')
            );

            // Check for webhook failures
            const webhookFailures = recentLogs.filter(log =>
                log.includes('webhook') && (log.includes('failed') || log.includes('error'))
            );

            if (authFailures.length > this.alertThresholds.invalidSignatures) {
                this.triggerAlert('authentication',
                    `Multiple authentication failures: ${authFailures.length}`,
                    'high'
                );
            }

            if (webhookFailures.length > this.alertThresholds.failedWebhooks) {
                this.triggerAlert('webhook',
                    `Multiple webhook failures: ${webhookFailures.length}`,
                    'medium'
                );
            }

            this.logSecurityEvent('info',
                `n8n logs check: ${errors.length} errors, ${authFailures.length} auth failures, ${webhookFailures.length} webhook failures`
            );

        } catch (error) {
            this.logSecurityEvent('error', `Failed to read n8n logs: ${error.message}`);
        }
    }

    async checkSystemResources() {
        return new Promise((resolve) => {
            exec('ps aux | grep n8n | grep -v grep', (error, stdout) => {
                if (error) {
                    this.logSecurityEvent('warning', 'n8n process not found');
                    resolve();
                    return;
                }

                const processes = stdout.split('\n').filter(line => line.trim());
                
                processes.forEach(process => {
                    const parts = process.split(/\s+/);
                    const cpu = parseFloat(parts[2]);
                    const memory = parseFloat(parts[3]);

                    if (cpu > 80) {
                        this.triggerAlert('resources',
                            `High CPU usage for n8n: ${cpu}%`,
                            'medium'
                        );
                    }

                    if (memory > 80) {
                        this.triggerAlert('resources',
                            `High memory usage for n8n: ${memory}%`,
                            'medium'
                        );
                    }
                });

                this.logSecurityEvent('info', `System resources check: ${processes.length} n8n processes`);
                resolve();
            });
        });
    }

    async checkWebhookHealth() {
        // This would typically make a health check request to your webhook endpoints
        // For now, we'll simulate by checking if the service is responding
        
        return new Promise((resolve) => {
            exec('curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/healthz || echo "000"', 
                (error, stdout) => {
                    const statusCode = stdout.trim();
                    
                    if (statusCode === '000' || statusCode.startsWith('5')) {
                        this.triggerAlert('webhook',
                            `Webhook endpoint unhealthy: HTTP ${statusCode}`,
                            'high'
                        );
                    }

                    this.logSecurityEvent('info', `Webhook health check: HTTP ${statusCode}`);
                    resolve();
                }
            );
        });
    }

    async checkFailedAuthentications() {
        // Check system authentication logs for suspicious activity
        return new Promise((resolve) => {
            exec('log show --last 1h --predicate \'category == "security"\' 2>/dev/null | head -20', 
                (error, stdout) => {
                    if (error) {
                        resolve();
                        return;
                    }

                    const securityEvents = stdout.split('\n').filter(line => 
                        line.includes('authentication') || line.includes('login')
                    );

                    if (securityEvents.length > 20) {
                        this.triggerAlert('system',
                            `High number of authentication events: ${securityEvents.length}`,
                            'medium'
                        );
                    }

                    this.logSecurityEvent('info', 
                        `System auth check: ${securityEvents.length} recent events`
                    );
                    resolve();
                }
            );
        });
    }

    getRecentLogEntries(logContent, minutesBack = 5) {
        const lines = logContent.split('\n');
        const cutoffTime = Date.now() - (minutesBack * 60 * 1000);
        
        return lines.filter(line => {
            // Try to extract timestamp from log line
            const timestampMatch = line.match(/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/);
            if (timestampMatch) {
                const logTime = new Date(timestampMatch[1]).getTime();
                return logTime > cutoffTime;
            }
            return false;
        });
    }

    triggerAlert(category, message, severity = 'medium') {
        const alert = {
            id: crypto.randomUUID(),
            timestamp: new Date().toISOString(),
            category,
            message,
            severity,
            resolved: false
        };

        this.alerts.push(alert);
        this.logSecurityEvent('alert', `${severity.toUpperCase()}: ${message}`);

        // In production, you might send to Slack, email, or other alerting systems
        console.log(`🚨 SECURITY ALERT [${severity.toUpperCase()}]: ${message}`);

        // Auto-resolve low-severity alerts after 1 hour
        if (severity === 'low') {
            setTimeout(() => {
                alert.resolved = true;
            }, 3600000);
        }
    }

    logSecurityEvent(level, message) {
        const timestamp = new Date().toISOString();
        const logEntry = `${timestamp} [${level.toUpperCase()}] ${message}\n`;
        
        try {
            fs.appendFileSync(this.logFile, logEntry);
        } catch (error) {
            console.error(`Failed to write to log file: ${error.message}`);
        }

        // Also log to console for immediate visibility
        const icon = {
            error: '❌',
            warning: '⚠️',
            info: 'ℹ️',
            alert: '🚨'
        };

        console.log(`${icon[level] || '📝'} [${level.toUpperCase()}] ${message}`);
    }

    generateSecurityReport() {
        const activeAlerts = this.alerts.filter(alert => !alert.resolved);
        const recentAlerts = this.alerts.filter(alert => 
            Date.now() - new Date(alert.timestamp).getTime() < 3600000 // Last hour
        );

        console.log('\n📊 SECURITY STATUS REPORT');
        console.log('========================');
        console.log(`🔴 Active Alerts: ${activeAlerts.length}`);
        console.log(`📈 Recent Alerts (1h): ${recentAlerts.length}`);
        console.log(`📝 Total Alerts: ${this.alerts.length}`);

        if (activeAlerts.length > 0) {
            console.log('\n🚨 ACTIVE ALERTS:');
            activeAlerts.forEach(alert => {
                console.log(`  ${alert.severity.toUpperCase()}: ${alert.message}`);
            });
        } else {
            console.log('\n✅ No active security alerts');
        }

        // Write report to file
        const reportPath = path.join(path.dirname(this.logFile), 'security-report.json');
        const report = {
            timestamp: new Date().toISOString(),
            activeAlerts: activeAlerts.length,
            recentAlerts: recentAlerts.length,
            totalAlerts: this.alerts.length,
            alerts: this.alerts.slice(-50) // Keep last 50 alerts
        };

        try {
            fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
        } catch (error) {
            this.logSecurityEvent('error', `Failed to write security report: ${error.message}`);
        }
    }
}

// Start monitoring if this script is run directly
if (require.main === module) {
    const monitor = new SecurityMonitor();
    
    process.on('SIGINT', () => {
        console.log('\n🛑 Security monitor shutting down...');
        process.exit(0);
    });
    
    console.log('🛡️  Security Monitor started. Press Ctrl+C to stop.');
}