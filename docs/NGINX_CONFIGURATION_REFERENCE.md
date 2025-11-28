# Nginx Configuration Reference
## Motorbike Parking App - Complete Configuration Documentation

---

## 📋 Table of Contents

1. [Main Nginx Configuration](#main-nginx-configuration)
2. [Site-Specific Configuration](#site-specific-configuration)
3. [SSL/TLS Configuration](#ssltls-configuration)
4. [Security Configuration](#security-configuration)
5. [Performance Configuration](#performance-configuration)
6. [Logging Configuration](#logging-configuration)
7. [Monitoring Configuration](#monitoring-configuration)
8. [Rate Limiting Configuration](#rate-limiting-configuration)
9. [Upstream Configuration](#upstream-configuration)
10. [Error Page Configuration](#error-page-configuration)

---

## Main Nginx Configuration

### File: `/etc/nginx/nginx.conf`

```nginx
# Nginx Main Configuration
# Motorbike Parking App - Martha Server (192.168.1.67)

# User and group for worker processes
user www-data;

# Process management
worker_processes auto;  # Automatically detect number of CPU cores
pid /run/nginx.pid;

# Include dynamic modules
include /etc/nginx/modules-enabled/*.conf;

# Events block - connection handling
events {
    worker_connections 1024;           # Maximum connections per worker
    multi_accept on;                   # Accept multiple connections at once
    use epoll;                         # Efficient connection method for Linux
}

# HTTP block - web server configuration
http {
    # Basic settings
    sendfile on;                       # Efficient file transfers
    tcp_nopush on;                     # Optimize TCP packet sending
    tcp_nodelay on;                    # Disable Nagle's algorithm
    keepalive_timeout 65;              # Keep connections alive for 65 seconds
    types_hash_max_size 2048;          # Maximum size for MIME type hash
    server_tokens off;                 # Hide Nginx version in headers

    # MIME type configuration
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # SSL/TLS configuration
    ssl_protocols TLSv1.2 TLSv1.3;     # Only allow secure TLS versions
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;     # Let client choose cipher
    ssl_session_cache shared:SSL:10m;  # SSL session cache
    ssl_session_timeout 10m;           # SSL session timeout
    ssl_stapling on;                   # OCSP stapling
    ssl_stapling_verify on;            # Verify OCSP responses

    # Logging configuration
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    log_format detailed '$remote_addr - $remote_user [$time_local] '
                       '"$request" $status $body_bytes_sent '
                       '"$http_referer" "$http_user_agent" '
                       'rt=$request_time uct="$upstream_connect_time" '
                       'uht="$upstream_header_time" urt="$upstream_response_time" '
                       'cs=$upstream_cache_status';

    log_format security '$remote_addr [$time_local] "$request" $status '
                       'rt=$request_time ua="$http_user_agent" '
                       'referer="$http_referer" forwarded="$http_x_forwarded_for"';

    log_format performance '$time_local $remote_addr "$request" $status '
                          'rt=$request_time uct=$upstream_connect_time '
                          'size=$body_bytes_sent method=$request_method '
                          'scheme=$scheme host=$host';

    # Default log files
    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Gzip compression configuration
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;              # Only compress files larger than 1KB
    gzip_comp_level 6;                 # Compression level (1-9)
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/xml+rss
        application/json
        application/xml
        image/svg+xml;

    # Rate limiting zones
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=1r/s;
    limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;
    limit_req_zone $binary_remote_addr zone=static:10m rate=30r/s;

    # Connection limiting
    limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

    # Buffer sizes
    client_body_buffer_size 128k;
    client_max_body_size 10m;
    client_header_buffer_size 1k;
    large_client_header_buffers 4 4k;
    output_buffers 1 32k;
    postpone_output 1460;

    # Timeouts
    client_body_timeout 12;
    client_header_timeout 12;
    send_timeout 10;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

---

## Site-Specific Configuration

### File: `/etc/nginx/sites-available/motorbike-parking`

```nginx
# Motorbike Parking App - Site Configuration
# Domain: motorbike.local
# Server: 192.168.1.67 (Martha)

# HTTP server block - redirect to HTTPS
server {
    listen 80;
    server_name motorbike.local www.motorbike.local;
    
    # Redirect all HTTP traffic to HTTPS
    return 301 https://$server_name$request_uri;
    
    # Logging for redirects
    access_log /var/log/nginx/redirect.log main;
}

# HTTPS server block - main application
server {
    listen 443 ssl http2;
    server_name motorbike.local www.motorbike.local;
    
    # SSL/TLS configuration
    ssl_certificate /etc/ssl/certs/motorbike.crt;
    ssl_certificate_key /etc/ssl/private/motorbike.key;
    ssl_dhparam /etc/ssl/dhparam.pem;
    
    # SSL optimization
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_buffer_size 8k;
    
    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/certs/motorbike.crt;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    # Remove server tokens
    server_tokens off;
    
    # Root directory for static files
    root /var/www/motorbike-parking;
    index index.html index.htm;
    
    # Connection limiting
    limit_conn conn_limit_per_ip 20;
    
    # Rate limiting
    limit_req zone=general burst=20 nodelay;
    
    # Main application proxy
    location / {
        # Proxy settings
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $server_name;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Error handling
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        
        # Logging
        access_log /var/log/nginx/app_access.log detailed;
        error_log /var/log/nginx/app_error.log;
    }
    
    # API endpoints with stricter rate limiting
    location /api/ {
        limit_req zone=api burst=50 nodelay;
        
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # API-specific timeouts
        proxy_connect_timeout 15s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Security logging
        access_log /var/log/nginx/api_access.log security;
        error_log /var/log/nginx/api_error.log;
    }
    
    # Authentication endpoints with very strict rate limiting
    location /api/auth/ {
        limit_req zone=auth burst=5 nodelay;
        
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Auth-specific timeouts
        proxy_connect_timeout 10s;
        proxy_send_timeout 15s;
        proxy_read_timeout 15s;
        
        # Enhanced security logging
        access_log /var/log/nginx/auth_access.log security;
        error_log /var/log/nginx/auth_error.log;
    }
    
    # Static files with caching
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        limit_req zone=static burst=100 nodelay;
        
        expires 30d;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
        
        # Try static files first, then proxy
        try_files $uri @backend;
        
        # Performance logging
        access_log /var/log/nginx/static_access.log performance;
    }
    
    # Backend fallback for static files
    location @backend {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health check endpoint
    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Nginx status endpoint (for monitoring)
    location /nginx-status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 192.168.1.0/24;
        deny all;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ ~$ {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /404.html {
        root /var/www/motorbike-parking;
        internal;
    }
    
    location = /50x.html {
        root /var/www/motorbike-parking;
        internal;
    }
    
    # Main logging
    access_log /var/log/nginx/access.log detailed;
    error_log /var/log/nginx/error.log warn;
}
```

---

## SSL/TLS Configuration

### SSL Certificate Generation Script

```bash
#!/bin/bash
# SSL Certificate Generation for motorbike.local

DOMAIN="motorbike.local"
COUNTRY="PT"
STATE="Lisbon"
LOCALITY="Lisbon"
ORGANIZATION="Motorbike Parking App"
ORGANIZATIONAL_UNIT="IT Department"
EMAIL="admin@motorbike.local"

# Create private key
openssl genrsa -out /etc/ssl/private/motorbike.key 2048

# Create certificate signing request
openssl req -new -key /etc/ssl/private/motorbike.key -out /etc/ssl/motorbike.csr -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$DOMAIN/emailAddress=$EMAIL"

# Create self-signed certificate
openssl x509 -req -days 365 -in /etc/ssl/motorbike.csr -signkey /etc/ssl/private/motorbike.key -out /etc/ssl/certs/motorbike.crt

# Generate DH parameters
openssl dhparam -out /etc/ssl/dhparam.pem 2048

# Set proper permissions
chmod 600 /etc/ssl/private/motorbike.key
chmod 644 /etc/ssl/certs/motorbike.crt
chmod 644 /etc/ssl/dhparam.pem

# Clean up CSR
rm /etc/ssl/motorbike.csr

echo "SSL certificate generated successfully!"
echo "Certificate valid until: $(openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -enddate)"
```

### SSL Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `ssl_protocols` | TLSv1.2 TLSv1.3 | Allowed TLS versions |
| `ssl_ciphers` | ECDHE-RSA-AES256-GCM-SHA384 | Strong cipher suites |
| `ssl_session_cache` | shared:SSL:10m | SSL session cache |
| `ssl_session_timeout` | 10m | SSL session timeout |
| `ssl_stapling` | on | OCSP stapling |
| `ssl_buffer_size` | 8k | SSL buffer size |

---

## Security Configuration

### Security Headers Configuration

```nginx
# HTTP Strict Transport Security (HSTS)
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Clickjacking protection
add_header X-Frame-Options DENY always;

# MIME-type sniffing protection
add_header X-Content-Type-Options nosniff always;

# XSS protection
add_header X-XSS-Protection "1; mode=block" always;

# Referrer policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Content Security Policy
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self'; frame-ancestors 'none';" always;

# Permissions policy
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

# Remove server tokens
server_tokens off;
```

### Access Control Configuration

```nginx
# Block malicious user agents
if ($http_user_agent ~* (bot|crawl|spider|scraper)) {
    return 403;
}

# Block suspicious request patterns
if ($request ~* "(\.\./|union|select|insert|update|delete|drop|exec|script)") {
    return 403;
}

# IP-based access control
allow 192.168.1.0/24;
allow 127.0.0.1;
deny all;

# Restrict access to sensitive locations
location ~ /\.ht {
    deny all;
}

location ~ ~$ {
    deny all;
}
```

---

## Performance Configuration

### Gzip Compression Settings

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_comp_level 6;
gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/javascript
    application/xml+rss
    application/json
    application/xml
    image/svg+xml
    application/atom+xml
    text/x-js
    application/x-javascript
    application/x-font-ttf
    application/x-font-opentype
    application/vnd.ms-fontobject
    image/x-icon;

# Disable compression for already compressed files
gzip_disable "msie6";
```

### Connection and Buffer Settings

```nginx
# Worker connections
events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

# Client connection settings
client_body_buffer_size 128k;
client_max_body_size 10m;
client_header_buffer_size 1k;
large_client_header_buffers 4 4k;

# Timeouts
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 65;
send_timeout 10;

# Proxy settings
proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
proxy_busy_buffers_size 8k;
proxy_connect_timeout 30s;
proxy_send_timeout 30s;
proxy_read_timeout 30s;
```

---

## Logging Configuration

### Custom Log Formats

```nginx
# Main log format
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';

# Detailed log format with timing
log_format detailed '$remote_addr - $remote_user [$time_local] '
                   '"$request" $status $body_bytes_sent '
                   '"$http_referer" "$http_user_agent" '
                   'rt=$request_time uct="$upstream_connect_time" '
                   'uht="$upstream_header_time" urt="$upstream_response_time" '
                   'cs=$upstream_cache_status';

# Security log format
log_format security '$remote_addr [$time_local] "$request" $status '
                   'rt=$request_time ua="$http_user_agent" '
                   'referer="$http_referer" forwarded="$http_x_forwarded_for"';

# Performance log format
log_format performance '$time_local $remote_addr "$request" $status '
                      'rt=$request_time uct=$upstream_connect_time '
                      'size=$body_bytes_sent method=$request_method '
                      'scheme=$scheme host=$host';
```

### Log Rotation Configuration

**File**: `/etc/logrotate.d/nginx`

```
/var/log/nginx/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}

/var/log/nginx/security.log {
    daily
    missingok
    rotate 90
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}

/var/log/nginx/performance.log {
    hourly
    missingok
    rotate 168
    compress
    delaycompress
    notifempty
    create 644 www-data adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 `cat /var/run/nginx.pid`
        fi
    endscript
}
```

---

## Monitoring Configuration

### Prometheus Metrics Configuration

```nginx
# Nginx status for Prometheus
location /nginx-status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    allow 192.168.1.0/24;
    deny all;
}

# Custom metrics endpoint
location /metrics {
    access_log off;
    return 200 'nginx_http_requests_total{method="$request_method",status="$status"} 1\n';
    add_header Content-Type text/plain;
}
```

### Node Exporter Configuration

```yaml
# Prometheus configuration for node exporter
scrape_configs:
  - job_name: 'nginx'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
    
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
    metrics_path: '/metrics'
```

---

## Rate Limiting Configuration

### Rate Limiting Zones

```nginx
# API endpoints - 10 requests per second
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

# Authentication endpoints - 1 request per second
limit_req_zone $binary_remote_addr zone=auth:10m rate=1r/s;

# General traffic - 5 requests per second
limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;

# Static files - 30 requests per second
limit_req_zone $binary_remote_addr zone=static:10m rate=30r/s;

# Connection limiting
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
```

### Rate Limiting Implementation

```nginx
# Apply rate limiting to locations
location /api/ {
    limit_req zone=api burst=50 nodelay;
    # ... other configuration
}

location /api/auth/ {
    limit_req zone=auth burst=5 nodelay;
    # ... other configuration
}

location / {
    limit_req zone=general burst=20 nodelay;
    limit_conn conn_limit_per_ip 20;
    # ... other configuration
}

location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
    limit_req zone=static burst=100 nodelay;
    # ... other configuration
}
```

---

## Upstream Configuration

### Backend Server Configuration

```nginx
# Define upstream backend servers
upstream motorbike_backend {
    server 127.0.0.1:3000 weight=1 max_fails=3 fail_timeout=30s;
    # Add additional backend servers here for load balancing
    # server 127.0.0.1:3001 weight=1 max_fails=3 fail_timeout=30s;
    
    # Load balancing method (default: round-robin)
    # least_conn;  # Least connections
    # ip_hash;     # Client IP persistence
    
    # Health check configuration
    keepalive 32;
}

# Use upstream in location blocks
location / {
    proxy_pass http://motorbike_backend;
    # ... other proxy settings
}
```

### Health Check Configuration

```nginx
# Health check endpoint
location /health {
    access_log off;
    proxy_pass http://motorbike_backend/health;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
}

# Backend health monitoring
location /backend-health {
    access_log off;
    proxy_pass http://motorbike_backend/health;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

---

## Error Page Configuration

### Custom Error Pages

```nginx
# Define error pages
error_page 404 /404.html;
error_page 500 502 503 504 /50x.html;
error_page 429 /429.html;

# Error page locations
location = /404.html {
    root /var/www/motorbike-parking/error;
    internal;
    expires 1h;
}

location = /50x.html {
    root /var/www/motorbike-parking/error;
    internal;
    expires 1h;
}

location = /429.html {
    root /var/www/motorbike-parking/error;
    internal;
    expires 1h;
}
```

### Error Page Templates

**File**: `/var/www/motorbike-parking/error/404.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Page Not Found - Motorbike Parking App</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        .error-code { font-size: 72px; color: #e74c3c; margin: 0; }
        .error-message { font-size: 24px; color: #333; margin: 20px 0; }
        .home-link { color: #3498db; text-decoration: none; font-size: 18px; }
    </style>
</head>
<body>
    <h1 class="error-code">404</h1>
    <p class="error-message">Page Not Found</p>
    <p>The page you're looking for doesn't exist.</p>
    <a href="/" class="home-link">Return to Home</a>
</body>
</html>
```

---

## Configuration Validation Commands

### Syntax and Configuration Testing

```bash
# Test Nginx configuration syntax
sudo nginx -t

# Test specific configuration file
sudo nginx -t -c /etc/nginx/nginx.conf

# Show effective configuration
sudo nginx -T

# Check configuration includes
sudo nginx -T | grep -E "(include|server_name|listen)"

# Verify upstream configuration
sudo nginx -T | grep -A 10 "upstream"
```

### SSL Certificate Testing

```bash
# Test SSL certificate
openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -text

# Check certificate expiry
openssl x509 -in /etc/ssl/certs/motorbike.crt -noout -enddate

# Verify SSL configuration
sudo nginx -t | grep SSL

# Test SSL connection
openssl s_client -connect motorbike.local:443 -servername motorbike.local
```

---

**Configuration Reference Version**: 1.0  
**Last Updated**: November 28, 2025  
**Related Documentation**: [NGINX_REVERSE_PROXY_IMPLEMENTATION.md](NGINX_REVERSE_PROXY_IMPLEMENTATION.md), [NGINX_QUICK_REFERENCE.md](NGINX_QUICK_REFERENCE.md)