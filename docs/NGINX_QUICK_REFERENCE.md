# Nginx Reverse Proxy - Quick Reference Guide
## Motorbike Parking App - Martha Server (192.168.1.67)

---

## 🚀 Quick Start Commands

### System Status Check
```bash
# Run comprehensive validation
./quick-nginx-validation.sh

# Check all services
systemctl status nginx nodejs prometheus node-exporter

# Real-time monitoring
/usr/local/bin/simple-monitor.sh
```

### Service Management
```bash
# Restart Nginx safely
sudo nginx -t && sudo systemctl restart nginx

# Reload configuration without downtime
sudo nginx -t && sudo systemctl reload nginx

# Full service restart
sudo systemctl restart nodejs nginx prometheus node-exporter
```

---

## 🔍 Validation Tests

### Essential URL Tests
```bash
# HTTP to HTTPS redirect (should return 301)
curl -I http://motorbike.local

# HTTPS access (should return 200)
curl -I https://motorbike.local --insecure

# Health endpoint (should return 200)
curl -I https://motorbike.local/nginx-health --insecure

# Backend direct access
curl -I http://localhost:3000/health
```

### SSL Certificate Check
```bash
# Certificate expiry
openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -enddate

# Certificate details
openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -text | grep -E "(Subject:|Issuer:|Not Before:|Not After:)"

# SSL connection test
openssl s_client -connect motorbike.local:443 -servername motorbike.local < /dev/null
```

### Security Headers Verification
```bash
# Check all security headers
curl -I https://motorbike.local --insecure | grep -E "(Strict|X-Frame|X-Content|Content-Security|Referrer)"

# Test rate limiting
for i in {1..20}; do curl -s https://motorbike.local/api/test --insecure | head -1; done
```

---

## 📊 Monitoring Access

### Dashboards and Metrics
```bash
# Prometheus Web Interface
http://localhost:9090

# Node Exporter Metrics
http://localhost:9100/metrics

# Real-time System Monitor
/usr/local/bin/simple-monitor.sh

# Log Analysis
/usr/local/bin/log-analyzer.sh
```

### Key Metrics to Monitor
- **nginx_http_requests_total** - Total request count
- **nginx_request_duration_seconds** - Response time distribution
- **node_cpu_seconds_total** - CPU usage
- **node_memory_MemAvailable_bytes** - Available memory
- **nginx_up** - Nginx service status

---

## 📝 Log File Locations

### Access Logs
```bash
# Main access log
tail -f /var/log/nginx/access.log

# Detailed format log
tail -f /var/log/nginx/detailed.log

# Security log
tail -f /var/log/nginx/security.log

# Performance log
tail -f /var/log/nginx/performance.log
```

### Error Logs
```bash
# Nginx errors
tail -f /var/log/nginx/error.log

# Backend application errors
journalctl -u nodejs -f

# System logs
journalctl -f
```

### Log Analysis Commands
```bash
# Top 10 IP addresses
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -10

# Response time analysis
grep "rt=" /var/log/nginx/performance.log | awk '{print $NF}' | sort -n | tail -10

# Error status codes
awk '$9 >= 400 {print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -nr

# SSL certificate monitoring
grep "SSL" /var/log/nginx/error.log | tail -20
```

---

## 🔧 Configuration Files

### Main Configuration Files
```bash
# Nginx main configuration
/etc/nginx/nginx.conf

# Site-specific configuration
/etc/nginx/sites-available/motorbike-parking

# SSL certificates
/etc/ssl/certs/motorbike.crt
/etc/ssl/private/motorbike.key

# Log rotation
/etc/logrotate.d/nginx
```

### Configuration Validation
```bash
# Test Nginx configuration syntax
sudo nginx -t

# Check included configuration files
sudo nginx -T | grep -E "(include|server_name|listen)"

# Verify upstream configuration
sudo grep -A 10 "upstream" /etc/nginx/sites-available/motorbike-parking
```

---

## 🚨 Troubleshooting Quick Fixes

### Common Issues

#### Nginx Won't Start
```bash
# Check configuration syntax
sudo nginx -t

# Check for port conflicts
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Check error log
sudo tail -20 /var/log/nginx/error.log

# Fix permissions
sudo chown -R www-data:www-data /var/log/nginx
```

#### SSL Certificate Problems
```bash
# Verify certificate exists
ls -la /etc/ssl/certs/motorbike.crt
ls -la /etc/ssl/private/motorbike.key

# Check certificate permissions
sudo chmod 644 /etc/ssl/certs/motorbike.crt
sudo chmod 600 /etc/ssl/private/motorbike.key

# Test SSL configuration
sudo openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -text
```

#### Backend Connection Issues
```bash
# Check if backend is running
systemctl status nodejs

# Test direct backend connection
curl -I http://localhost:3000/health

# Check firewall rules
sudo ufw status
sudo iptables -L -n | grep 3000
```

#### High Response Times
```bash
# Check current connections
sudo nginx -s status

# Monitor system resources
top -p $(pgrep nginx)
free -h
df -h

# Analyze slow requests
sudo grep "rt=[5-9]\." /var/log/nginx/performance.log | tail -10
```

---

## 🔄 Maintenance Commands

### Daily Tasks
```bash
# Quick health check
./quick-nginx-validation.sh

# Log rotation check
sudo logrotate -f /etc/logrotate.d/nginx

# Disk space check
df -h /var/log

# Service status check
systemctl is-active nginx nodejs prometheus node-exporter
```

### Weekly Tasks
```bash
# Configuration backup
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup-$(date +%Y%m%d)
sudo cp /etc/nginx/sites-available/motorbike-parking /etc/nginx/sites-available/motorbike-parking.backup-$(date +%Y%m%d)

# Performance test
ab -n 1000 -c 50 https://motorbike.local/

# Security audit
sudo fail2ban-client status
```

### Monthly Tasks
```bash
# Full system update check
sudo apt update && sudo apt list --upgradable

# SSL certificate expiry check
echo "SSL Certificate expires in: $(($(date -d "$(openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -enddate | cut -d= -f2)" +%s) - $(date +%s))) / 86400 days"

# Log cleanup
find /var/log/nginx -name "*.log.*" -mtime +30 -delete

# Performance benchmarking
ab -n 10000 -c 100 https://motorbike.local/
```

---

## 📞 Emergency Contacts and Procedures

### Service Recovery Sequence
1. **Check service status**: `systemctl status nginx nodejs`
2. **Restart services**: `sudo systemctl restart nodejs nginx`
3. **Validate configuration**: `sudo nginx -t`
4. **Run health check**: `./quick-nginx-validation.sh`
5. **Check logs**: `sudo tail -50 /var/log/nginx/error.log`

### Configuration Rollback
```bash
# Restore last known good configuration
sudo cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
sudo cp /etc/nginx/sites-available/motorbike-parking.backup /etc/nginx/sites-available/motorbike-parking

# Test and reload
sudo nginx -t && sudo systemctl reload nginx
```

### Critical Alert Thresholds
- **CPU Usage**: >90% for 5 minutes
- **Memory Usage**: >95% for 2 minutes
- **Disk Space**: <10% free on /var/log
- **Response Time**: >5 seconds for 1 minute
- **Error Rate**: >10% of requests

---

## 📋 Quick Validation Checklist

### Daily Health Check ✅
- [ ] All services running
- [ ] HTTPS accessible
- [ ] SSL certificate valid
- [ ] No critical errors in logs
- [ ] Response times <2 seconds

### Weekly Review ✅
- [ ] Configuration backups created
- [ ] Log rotation working
- [ ] Security headers present
- [ ] Rate limiting functional
- [ ] Monitoring metrics collecting

### Monthly Audit ✅
- [ ] SSL certificate expiry check
- [ ] Performance benchmarks
- [ ] Security scan results
- [ ] Backup verification
- [ ] Documentation update

---

**Quick Reference Version**: 1.0  
**Last Updated**: November 28, 2025  
**Related Documentation**: [NGINX_REVERSE_PROXY_IMPLEMENTATION.md](NGINX_REVERSE_PROXY_IMPLEMENTATION.md)