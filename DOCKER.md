# Docker Setup for Laravel Boilerplate

This Laravel application is fully containerized using Docker for consistent development and deployment environments.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- Make (optional, for convenience commands)

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd laravel-boilerplate

# Copy Docker environment file
cp docker.env .env

# Start the application (this will build, install, and setup everything)
make install
```

The application will be available at: **http://localhost:8080**

### 2. Alternative Manual Setup

If you prefer manual setup or don't have Make installed:

```bash
# Copy environment file
cp docker.env .env

# Build containers
docker-compose build

# Start containers
docker-compose up -d

# Install PHP dependencies
docker-compose exec app composer install

# Generate application key
docker-compose exec app php artisan key:generate

# Run migrations and seeders
docker-compose exec app php artisan migrate:fresh --seed

# Install and build frontend assets
docker-compose exec app npm install
docker-compose exec app npm run build
```

## Services

The Docker setup includes the following services:

| Service | Container Name | Ports | Description |
|---------|---------------|-------|-------------|
| **app** | laravel_app | - | PHP-FPM application container |
| **nginx** | laravel_nginx | 8080:80 | Web server |
| **db** | laravel_db | 3306:3306 | MySQL 8.0 database |
| **redis** | laravel_redis | 6379:6379 | Redis cache and sessions |
| **queue** | laravel_queue | - | Laravel queue worker |
| **mailhog** | laravel_mailhog | 1025:1025, 8025:8025 | Email testing |

## Available Make Commands

```bash
# Container Management
make build          # Build Docker containers
make up             # Start all containers
make down           # Stop all containers
make restart        # Restart all containers
make logs           # Show logs from all containers
make status         # Show container status

# Shell Access
make shell          # Access app container shell
make nginx-shell    # Access nginx container shell
make db-shell       # Access database shell
make redis-shell    # Access redis shell

# Laravel Commands
make install        # Complete application setup
make migrate        # Run database migrations
make seed           # Run database seeders
make fresh          # Fresh migration with seeding
make test           # Run PHPUnit tests
make key            # Generate application key

# Cache Management
make cache          # Cache config, routes, and views
make clear          # Clear all caches
make optimize       # Optimize for production

# Frontend Assets
make assets         # Build frontend assets
make assets-dev     # Build for development
make assets-watch   # Watch for changes

# Utility
make permissions    # Fix file permissions
make clean          # Remove containers and volumes
make reset          # Complete reset and rebuild
```

## Manual Docker Commands

If you prefer using Docker Compose directly:

```bash
# Container management
docker-compose up -d                    # Start containers
docker-compose down                     # Stop containers
docker-compose build                    # Build containers
docker-compose logs -f                  # View logs

# Laravel commands
docker-compose exec app php artisan migrate
docker-compose exec app php artisan test
docker-compose exec app php artisan queue:work

# Shell access
docker-compose exec app bash           # App container
docker-compose exec nginx sh           # Nginx container
docker-compose exec db mysql -u laravel -ppassword laravel
```

## Environment Configuration

The Docker setup uses `docker.env` as the environment file template. Key Docker-specific configurations:

```env
# Application
APP_URL=http://localhost:8080

# Database (connects to Docker MySQL container)
DB_HOST=db
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=password

# Cache & Sessions (connects to Docker Redis container)
CACHE_DRIVER=redis
SESSION_DRIVER=redis
REDIS_HOST=redis

# Mail (uses MailHog for testing)
MAIL_HOST=mailhog
MAIL_PORT=1025
```

## Development Workflow

### Daily Development

1. **Start containers:**
   ```bash
   make up
   ```

2. **View logs:**
   ```bash
   make logs
   ```

3. **Run migrations:**
   ```bash
   make migrate
   ```

4. **Run tests:**
   ```bash
   make test
   ```

5. **Access application shell:**
   ```bash
   make shell
   ```

### Frontend Development

```bash
# Install dependencies
docker-compose exec app npm install

# Build assets for development
make assets-dev

# Watch for changes
make assets-watch
```

### Database Operations

```bash
# Run migrations
make migrate

# Refresh database with seeders
make fresh

# Access database directly
make db-shell

# Backup database
make backup-db
```

## Service Access

- **Application:** http://localhost:8080
- **MailHog Web UI:** http://localhost:8025
- **Database:** localhost:3306
- **Redis:** localhost:6379

## File Structure

```
laravel-boilerplate/
├── docker/
│   ├── nginx/
│   │   └── default.conf      # Nginx configuration
│   ├── php/
│   │   └── local.ini         # PHP configuration
│   └── mysql/
│       └── my.cnf            # MySQL configuration
├── docker-compose.yml        # Docker Compose configuration
├── Dockerfile               # PHP application container
├── .dockerignore           # Docker build context exclusions
├── docker.env              # Docker environment template
├── Makefile                # Development convenience commands
└── DOCKER.md               # This documentation
```

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   ```bash
   # Check what's using the ports
   lsof -i :8080
   lsof -i :3306
   
   # Change ports in docker-compose.yml if needed
   ```

2. **Permission issues:**
   ```bash
   make permissions
   ```

3. **Container won't start:**
   ```bash
   # Check logs
   make logs
   
   # Rebuild containers
   make build
   ```

4. **Database connection issues:**
   ```bash
   # Ensure database container is running
   docker-compose ps
   
   # Check database logs
   docker-compose logs db
   ```

### Reset Everything

If you encounter persistent issues:

```bash
# Complete reset
make reset
```

This will remove all containers, rebuild everything, and reinstall the application.

## Production Deployment

For production deployment, you would typically:

1. Create a production Docker Compose file
2. Use environment-specific configurations
3. Set up proper secrets management
4. Configure SSL/TLS
5. Set up monitoring and logging

## Performance Tips

1. **Use bind mounts for development** (already configured)
2. **Use named volumes for data persistence** (already configured)
3. **Enable OPcache in production** (configured in php/local.ini)
4. **Use multi-stage builds for smaller production images**

## Support

For issues related to the Docker setup, check:

1. Docker and Docker Compose versions
2. Available system resources
3. Port availability
4. File permissions
5. Container logs using `make logs`
