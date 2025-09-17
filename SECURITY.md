# Security Considerations for Docker Setup

This document outlines the security measures implemented in the Docker configuration and provides guidance for secure deployment.

## 🔒 Security Features Implemented

### Container Security

#### 1. **Non-Root User Execution**
- PHP-FPM containers run as `www-data` user (non-root)
- Prevents privilege escalation attacks
- Follows Docker security best practices

#### 2. **Minimal Base Images**
- Uses official PHP and Alpine Linux images
- Reduces attack surface by minimizing installed packages
- Regular security updates from official maintainers

#### 3. **No Privileged Containers**
- All containers run without `--privileged` flag
- Limited container capabilities
- Restricted access to host system

### Network Security

#### 1. **Isolated Networks**
- Custom Docker network (`laravel_network`)
- Services communicate only within defined network
- No unnecessary external port exposure

#### 2. **Port Exposure Control**
- Only necessary ports exposed to host:
  - `8080:80` (Nginx - Web traffic)
  - `3306:3306` (MySQL - Database access)
  - `6379:6379` (Redis - Cache access)
  - `8025:8025` (MailHog - Development only)

#### 3. **Service Communication**
- Internal service communication via service names
- No hardcoded IP addresses
- Encrypted connections where applicable

### Application Security

#### 1. **Environment Variables**
- Sensitive data stored in environment files
- `.env` files excluded from version control
- Separate environment configurations for different stages

#### 2. **File Permissions**
- Proper file ownership (`www-data:www-data`)
- Restricted permissions on sensitive directories
- Storage and cache directories properly secured

#### 3. **PHP Security Configuration**
```ini
# docker/php/local.ini
expose_php = Off                    # Hide PHP version
allow_url_include = Off            # Prevent remote file inclusion
open_basedir = /var/www           # Restrict file access
```

### Database Security

#### 1. **User Privileges**
- Dedicated database user with limited privileges
- Not using root user for application connections
- Database name, user, and password configurable

#### 2. **Connection Security**
- Internal network communication only
- Configurable authentication methods
- Connection timeouts implemented

### Build Security

#### 1. **Multi-Stage Builds**
- Optimized Docker images with minimal attack surface
- Build tools not included in final image
- Secrets not leaked in image layers

#### 2. **Dependency Management**
- Production-only dependencies in final image
- Regular dependency updates
- Lock files for reproducible builds

## ⚠️ Security Considerations for Production

### 1. **Environment Variables**
```bash
# Required changes for production:
APP_ENV=production
APP_DEBUG=false
APP_KEY=<generate-strong-32-character-key>

# Database credentials (use strong passwords)
DB_PASSWORD=<strong-secure-password>
MYSQL_ROOT_PASSWORD=<strong-root-password>

# Remove development services
# - Remove MailHog service
# - Consider removing direct database port exposure
```

### 2. **SSL/TLS Configuration**
```nginx
# For production, implement HTTPS:
server {
    listen 443 ssl http2;
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # Strong SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
}
```

### 3. **Firewall Configuration**
```bash
# Recommended firewall rules:
# Allow only necessary ports
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw allow 22/tcp      # SSH (restrict source IPs)

# Block direct database access from outside
ufw deny 3306/tcp
ufw deny 6379/tcp
```

### 4. **Image Security Scanning**
```bash
# Scan images for vulnerabilities:
docker scout cves laravel-boilerplate-app:latest
docker scout recommendations laravel-boilerplate-app:latest

# Use official base images and keep them updated
docker pull php:8.2-fpm
docker pull nginx:alpine
docker pull mysql:8.0
docker pull redis:alpine
```

### 5. **Container Runtime Security**
```yaml
# Production docker-compose.yml additions:
services:
  app:
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
    volumes:
      - ./storage:/var/www/storage:rw
      - ./bootstrap/cache:/var/www/bootstrap/cache:rw
```

## 🛡️ Security Checklist for Production

### Pre-Deployment
- [ ] Change all default passwords
- [ ] Generate strong APP_KEY
- [ ] Set APP_DEBUG=false
- [ ] Set APP_ENV=production
- [ ] Remove development services (MailHog)
- [ ] Configure SSL/TLS certificates
- [ ] Set up proper firewall rules
- [ ] Scan images for vulnerabilities

### Runtime Security
- [ ] Monitor container logs for suspicious activity
- [ ] Regular security updates for base images
- [ ] Backup encryption for database volumes
- [ ] Network monitoring and intrusion detection
- [ ] Regular security audits

### Access Control
- [ ] Implement proper user authentication
- [ ] Use SSH keys instead of passwords
- [ ] Limit SSH access by IP
- [ ] Regular access review and cleanup
- [ ] Multi-factor authentication for admin access

## 🔍 Security Monitoring

### Log Monitoring
```bash
# Monitor application logs:
docker compose logs app | grep -i "error\|warning\|failed"

# Monitor nginx access logs:
docker compose logs nginx | grep -E "4[0-9]{2}|5[0-9]{2}"

# Monitor database logs:
docker compose logs db | grep -i "error\|denied\|failed"
```

### Health Checks
The setup includes health checks for all services to detect issues early:
- Application health via PHP-FPM status
- Database connectivity checks
- Redis connectivity checks
- Nginx response checks

## 📚 Security Resources

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Laravel Security Documentation](https://laravel.com/docs/security)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

## 🚨 Incident Response

In case of security incidents:
1. **Immediate**: Stop affected containers (`docker compose stop`)
2. **Isolate**: Disconnect from networks if necessary
3. **Investigate**: Review logs and check for compromise indicators
4. **Remediate**: Apply fixes and rebuild containers if needed
5. **Monitor**: Enhanced monitoring post-incident

## ⚡ Performance Security

### Resource Limits
```yaml
# Add to docker-compose.yml for production:
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

### Rate Limiting
```nginx
# Add to nginx configuration:
http {
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;
    
    server {
        location /login {
            limit_req zone=login burst=5 nodelay;
        }
    }
}
```

---

**Note**: This security configuration is designed for development environments. Production deployments require additional security hardening based on specific requirements and threat models.
