.PHONY: help build up down restart logs shell nginx-shell db-shell redis-shell queue-shell migrate seed test fresh install key cache clear permissions status

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Docker commands
build: ## Build Docker containers
	docker compose build --no-cache

up: ## Start all containers in detached mode
	docker compose up -d

down: ## Stop and remove all containers
	docker compose down

restart: ## Restart all containers
	docker compose restart

logs: ## Show logs from all containers
	docker compose logs -f

logs-app: ## Show logs from app container
	docker compose logs -f app

logs-nginx: ## Show logs from nginx container
	docker compose logs -f nginx

logs-db: ## Show logs from database container
	docker compose logs -f db

# Shell access
shell: ## Access app container shell
	docker compose exec app bash

nginx-shell: ## Access nginx container shell
	docker compose exec nginx sh

db-shell: ## Access database container shell
	docker compose exec db mysql -u laravel -ppassword laravel

redis-shell: ## Access redis container shell
	docker compose exec redis redis-cli

queue-shell: ## Access queue container shell
	docker compose exec queue bash

# Laravel commands
install: ## Install and setup Laravel application
	@echo "Setting up Laravel application..."
	cp docker.env .env
	docker compose up -d --wait
	docker compose exec app composer install
	docker compose exec app php artisan key:generate
	docker compose exec app php artisan storage:link
	docker compose exec app php artisan migrate:fresh --seed
	docker compose exec app npm install
	docker compose exec app npm run build
	@echo "Application is ready at http://localhost:8080"

migrate: ## Run database migrations
	docker compose exec app php artisan migrate

migrate-fresh: ## Drop all tables and re-run migrations
	docker compose exec app php artisan migrate:fresh

seed: ## Run database seeders
	docker compose exec app php artisan db:seed

fresh: ## Fresh migration with seeding
	docker compose exec app php artisan migrate:fresh --seed

test: ## Run PHPUnit tests
	docker compose exec app php artisan test

test-coverage: ## Run tests with coverage
	docker compose exec app php artisan test --coverage

# Cache and optimization commands
cache: ## Cache config, routes, and views
	docker compose exec app php artisan config:cache
	docker compose exec app php artisan route:cache
	docker compose exec app php artisan view:cache

clear: ## Clear all caches
	docker compose exec app php artisan cache:clear
	docker compose exec app php artisan config:clear
	docker compose exec app php artisan route:clear
	docker compose exec app php artisan view:clear

optimize: ## Optimize application for production
	docker compose exec app php artisan optimize

# Key generation
key: ## Generate application key
	docker compose exec app php artisan key:generate

# Permission commands
permissions: ## Fix storage and cache permissions
	docker compose exec app chmod -R 755 storage bootstrap/cache
	docker compose exec app chown -R www-data:www-data storage bootstrap/cache

# Asset commands
assets: ## Build frontend assets
	docker compose exec app npm run build

assets-dev: ## Build frontend assets for development
	docker compose exec app npm run dev

assets-watch: ## Watch frontend assets for changes
	docker compose exec app npm run dev -- --watch

# Utility commands
status: ## Show container status
	docker compose ps

clean: ## Remove all containers, networks, and volumes
	docker compose down -v --rmi all --remove-orphans

reset: ## Complete reset - clean and rebuild everything
	make clean
	make build
	make install

# Production commands
prod-build: ## Build for production
	docker compose -f docker-compose.yml -f docker-compose.prod.yml build

prod-up: ## Start in production mode
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Database backup and restore
backup-db: ## Backup database
	docker compose exec db mysqldump -u laravel -ppassword laravel > backup_$(shell date +%Y%m%d_%H%M%S).sql

restore-db: ## Restore database (usage: make restore-db FILE=backup.sql)
	docker compose exec -T db mysql -u laravel -ppassword laravel < $(FILE)

# Health checks
health: ## Check health of all services
	docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Development helpers
lint: ## Run code linting
	docker compose exec app ./vendor/bin/pint

ide-helper: ## Generate IDE helper files
	docker compose exec app php artisan ide-helper:generate
	docker compose exec app php artisan ide-helper:models
	docker compose exec app php artisan ide-helper:meta
