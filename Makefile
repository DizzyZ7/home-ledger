.DEFAULT_GOAL := help

.PHONY: help up down logs api-install api-run api-test api-lint mobile-install mobile-analyze mobile-test seed

help: ## Print available commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

up: ## Start PostgreSQL and API with Docker Compose
	cp -n .env.example .env 2>/dev/null || true
	docker compose up --build

down: ## Stop local Docker services
	docker compose down

logs: ## Follow API logs
	docker compose logs -f api

api-install: ## Install API development dependencies
	cd services/api && python -m pip install -e '.[dev]'

api-run: ## Run API locally without Docker
	cd services/api && uvicorn app.main:app --reload

api-test: ## Run API tests
	cd services/api && pytest -q

api-lint: ## Run API static checks
	cd services/api && ruff check . && ruff format --check .

mobile-install: ## Fetch Flutter packages
	cd apps/mobile && flutter pub get

mobile-analyze: ## Analyze Flutter source
	cd apps/mobile && flutter analyze

mobile-test: ## Run Flutter tests
	cd apps/mobile && flutter test

seed: ## Seed Docker database with safe demo data
	docker compose exec api python -m app.scripts.seed
