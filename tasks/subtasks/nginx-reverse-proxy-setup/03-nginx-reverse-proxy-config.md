# 03. Nginx Reverse Proxy Configuration

meta:
  id: nginx-reverse-proxy-setup-03
  feature: nginx-reverse-proxy-setup
  priority: P1
  depends_on: [nginx-reverse-proxy-setup-02]
  tags: [implementation, nginx, proxy]
  status: completed
  completed_at: 2025-11-26T00:59:00Z

objective:
- Install Nginx and configure it as a reverse proxy to route traffic to the backend application with SSL termination

deliverables:
- Nginx installed and running
- Main Nginx configuration optimized
- Site-specific reverse proxy configuration
- SSL integration with Let's Encrypt certificates
- Basic load balancing and health checks

steps:
- Install Nginx: `sudo apt install -y nginx`
- Backup default configuration: `sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup`
- Create optimized main configuration:
  - Set worker processes to auto
  - Configure worker connections
  - Enable gzip compression
  - Set appropriate timeouts
- Create site configuration file:
  - `sudo nano /etc/nginx/sites-available/motorbike-parking`
  - Configure upstream backend servers
  - Set up SSL termination
  - Configure proxy headers
  - Add health check endpoints
- Enable site: `sudo ln -s /etc/nginx/sites-available/motorbike-parking /etc/nginx/sites-enabled/`
- Remove default site: `sudo rm /etc/nginx/sites-enabled/default`
- Test configuration: `sudo nginx -t`
- Restart Nginx: `sudo systemctl restart nginx`
- Enable Nginx on boot: `sudo systemctl enable nginx`

tests:
- Unit: Validate Nginx configuration syntax
- Integration: Test proxy routing to backend
- SSL: Verify HTTPS redirection and certificate handling
- Performance: Test basic load distribution

acceptance_criteria:
- Nginx is installed and running successfully
- Configuration passes syntax validation
- HTTP traffic redirects to HTTPS
- Reverse proxy correctly routes to backend application
- SSL certificates are properly integrated
- Service starts automatically on boot

validation:
- Check Nginx status: `sudo systemctl status nginx`
- Test configuration: `sudo nginx -t`
- Verify proxy functionality: `curl -I https://yourdomain.com`
- Check SSL: `curl -I https://yourdomain.com --insecure`
- Monitor logs: `sudo tail -f /var/log/nginx/access.log`
- Test backend connectivity: `curl http://localhost:3000/health`

notes:
- Adjust upstream server addresses based on actual backend configuration
- Monitor Nginx error logs during initial setup
- Consider rate limiting for API endpoints
- Document any custom configuration parameters
- Keep backup of all configuration files