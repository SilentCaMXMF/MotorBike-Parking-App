# 02. SSL Certificate Setup

meta:
  id: nginx-reverse-proxy-setup-02
  feature: nginx-reverse-proxy-setup
  priority: P1
  depends_on: [nginx-reverse-proxy-setup-01]
  tags: [implementation, security, ssl]
  status: completed
  completed_at: 2025-11-26T00:58:00Z

objective:
- Install and configure SSL certificates using Let's Encrypt with automatic renewal for secure HTTPS connections

deliverables:
- Certbot installed and configured
- SSL certificates obtained for the domain
- Automatic renewal system configured
- Certificate validation and testing

steps:
- Install Certbot and Nginx plugin: `sudo apt install -y certbot python3-certbot-nginx`
- Ensure domain DNS A record points to server IP
- Obtain SSL certificate:
  - `sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com`
  - Follow prompts for email and terms of service
- Set up automatic renewal:
  - `sudo crontab -e`
  - Add: `0 12 * * * /usr/bin/certbot renew --quiet`
- Test renewal process: `sudo certbot renew --dry-run`
- Verify certificate files location: `/etc/letsencrypt/live/yourdomain.com/`
- Create certificate monitoring script

tests:
- Unit: Verify Certbot installation and configuration
- Integration: Test certificate issuance and renewal process
- Security: Validate certificate strength and configuration

acceptance_criteria:
- SSL certificates are successfully obtained and installed
- Automatic renewal is configured and tested
- Certificate files are properly located and accessible
- Domain validates correctly with SSL labs test
- Renewal process works without manual intervention

validation:
- Check certificate status: `sudo certbot certificates`
- Test SSL configuration: `openssl s_client -connect yourdomain.com:443`
- Verify renewal: `sudo certbot renew --dry-run`
- Check SSL rating: `https://www.ssllabs.com/ssltest/`
- Monitor certificate expiry: `echo | openssl s_client -servername yourdomain.com -connect yourdomain.com:443 2>/dev/null | openssl x509 -noout -dates`

notes:
- Replace 'yourdomain.com' with actual domain name
- Ensure firewall allows port 80 for certificate validation
- Keep backup of certificate files
- Monitor certificate expiry dates
- Document any domain-specific configurations