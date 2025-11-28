# 01. Server Preparation

meta:
  id: nginx-reverse-proxy-setup-01
  feature: nginx-reverse-proxy-setup
  priority: P1
  depends_on: []
  tags: [implementation, infrastructure, security]
  status: completed
  completed_at: 2025-11-26T00:55:00Z

objective:
- Prepare the server environment for Nginx installation and configuration with proper system updates, firewall setup, and user permissions

deliverables:
- Updated server system with latest security patches
- Properly configured firewall rules
- Dedicated nginx user with appropriate permissions
- Required system dependencies installed

steps:
- Update system packages: `sudo apt update && sudo apt upgrade -y`
- Install required dependencies: `sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates`
- Configure UFW firewall rules:
  - Allow SSH: `sudo ufw allow ssh`
  - Allow HTTP: `sudo ufw allow 80/tcp`
  - Allow HTTPS: `sudo ufw allow 443/tcp`
  - Enable firewall: `sudo ufw enable`
- Create nginx system user: `sudo useradd --system --home /var/cache/nginx --shell /sbin/nologin nginx`
- Create required directories:
  - `sudo mkdir -p /var/log/nginx`
  - `sudo mkdir -p /var/cache/nginx`
  - `sudo mkdir -p /etc/nginx/sites-available`
  - `sudo mkdir -p /etc/nginx/sites-enabled`
- Set proper permissions:
  - `sudo chown -R nginx:nginx /var/cache/nginx`
  - `sudo chown -R nginx:nginx /var/log/nginx`
- Create nginx log rotation configuration

tests:
- Unit: Verify system package versions and user creation
- Integration: Test firewall rules and directory permissions
- System: Validate that all required directories exist with correct ownership

acceptance_criteria:
- System is fully updated with latest security patches
- Firewall is configured and active with proper ports open
- nginx user exists with correct permissions
- All required directories are created with proper ownership
- System is ready for Nginx installation

validation:
- Check system updates: `sudo apt list --upgradable`
- Verify firewall status: `sudo ufw status verbose`
- Check nginx user: `id nginx`
- Verify directories: `ls -la /var/cache/nginx /var/log/nginx /etc/nginx/sites-*`
- Test basic connectivity: `curl -I http://localhost`

notes:
- This task must be completed before any Nginx installation
- Ensure SSH access is maintained throughout the process
- Document any system-specific configurations for future reference
- Backup existing configurations before making changes