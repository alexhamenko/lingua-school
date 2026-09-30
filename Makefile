# Executables (local)
DOCKER_COMP = docker compose

# Run commands as the host user, so files created in the container (recipes, makers) are owned by you
HOST_USER = $(shell id -u):$(shell id -g)

# Docker containers
PHP_CONT = $(DOCKER_COMP) exec -u $(HOST_USER) php

# Executables
PHP      = $(PHP_CONT) php
COMPOSER = $(PHP_CONT) composer
CONSOLE  = $(PHP) bin/console

# Misc
.DEFAULT_GOAL = help
.PHONY        : help build up down logs sh composer console cc

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
help: ## Show this help
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

build: ## Build fresh Docker images
	@$(DOCKER_COMP) build --pull --no-cache

up: ## Start the containers and wait until they are healthy
	@$(DOCKER_COMP) up --wait

down: ## Stop the containers
	@$(DOCKER_COMP) down --remove-orphans

logs: ## Show live logs
	@$(DOCKER_COMP) logs --tail=0 --follow

sh: ## Open a bash shell in the php container (as the host user)
	@$(PHP_CONT) bash

## —— Composer 🧙 ——————————————————————————————————————————————————————————————
composer: ## Run composer, example: make composer c='require symfony/lock'
	@$(eval c ?=)
	@$(COMPOSER) $(c)

## —— Symfony 🎵 ———————————————————————————————————————————————————————————————
console: ## Run bin/console, example: make console c='debug:router'
	@$(eval c ?=)
	@$(CONSOLE) $(c)

cc: c=cache:clear ## Clear the cache
cc: console
