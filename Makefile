# lets try the new docker build system
# https://docs.docker.com/develop/develop-images/build_enhancements/
# https://www.docker.com/blog/faster-builds-in-compose-thanks-to-buildkit-support/
export DOCKER_BUILDKIT := 1
export DOCKER_SCAN_SUGGEST := false
export COMPOSE_DOCKER_CLI_BUILD := 1
export BUILDKIT_PROGRESS=plain

# include .env if present
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# get current timestamp
export DATE := $(shell date '+%Y-%m-%d-%H.%M.%S')
export PUID := $(shell id -u)
export PGID := $(shell id -g)

# if username not set we are in a drone environment
export USERNAME := $(or $(USERNAME), drone)

#export EMAIL := $(or $(GIT_COMMITTER_EMAIL), $(shell git config user.email))
export EMAIL := $(or $(GIT_COMMITTER_EMAIL), $(shell git config user.email))


ifdef DRONE_REPO_BRANCH
	local_branch := $(DRONE_REPO_BRANCH)
else
	local_branch = $(shell git rev-parse --abbrev-ref HEAD | tr -d '\n')
endif

ifeq (master,$(local_branch))
	ENV_CONTEXT := production
else
	ENV_CONTEXT := $(local_branch)
endif

# determine the name of the first service in the docker-compose.yml
export ATTACH_HOST := $(or $(shell awk 'f{print;f=0} /service/{f=1}' docker-compose.yml | sed -r 's/\s+|\://g'), webapp)

# If the first argument is "deploy"...
ifeq (deploy,$(firstword $(MAKECMDGOALS)))
	ENV_CONTEXT := production
	PASSED_COMMAND := $(word 2,$(MAKECMDGOALS))
	DEPLOY_STAGE := $(or $(PASSED_COMMAND),$(ENV_CONTEXT))
# If the first argument is "test"...
else ifeq (test,$(firstword $(MAKECMDGOALS)))
	# default DEPLOY_STAGE & ENV_CONTEXT to test
	ENV_CONTEXT := $(or $(word 2,$(MAKECMDGOALS)),test)
	DEPLOY_STAGE := $(or $(word 2,$(MAKECMDGOALS)),test)
else
	# default DEPLOY_STAGE to development
	ENV_CONTEXT := $(or $(word 2,$(MAKECMDGOALS)),development)
	DEPLOY_STAGE := $(or $(word 2,$(MAKECMDGOALS)),development)
endif
export DEPLOY_STAGE
export ENV_CONTEXT

# set the docker-compose FLAGS based on the DEPLOY_STAGE value
FLAGS = -f ./docker-compose.yml

ifeq (development,$(DEPLOY_STAGE))
	FLAGS += -f ./docker-compose.override.yml
else ifneq (,$(wildcard ./docker-compose.$(DEPLOY_STAGE).yml))
  FLAGS += -f ./docker-compose.$(DEPLOY_STAGE).yml
endif

ifeq (1, $(shell docker ps -a | grep traefik | wc -l ) )
	FLAGS += -f ./docker-compose.traefik.yml
else
	FLAGS += -f ./docker-compose.influx.yml
endif

# get the app name from the current directory
export APP_NAME := $(notdir $(shell pwd))
export APP_DOMAIN := $(or $(shell hostname -d), ilude.com)

# use the rest as arguments as empty targets
EMPTY_TARGETS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(EMPTY_TARGETS):;@:)

up: build
	@-rm -f tmp/pids/*.pid # - ignore errors
	docker-compose $(FLAGS) up --force-recreate --abort-on-container-exit --remove-orphans

env: 
	env | sort

echo:
	@echo =========================================
	@echo = APP_NAME: $(APP_NAME)
	@echo = APP_DOMAIN: $(APP_DOMAIN)
	@echo = USERNAME: $(USERNAME)
	@echo = EMAIL: $(EMAIL)
	@echo = ENV_CONTEXT:  $(ENV_CONTEXT)
	@echo = DEPLOY_STAGE: $(DEPLOY_STAGE)
	@echo = FLAGS: $(FLAGS)
	@echo =========================================

start: build
	docker-compose $(FLAGS) up -d

down:
	docker-compose $(FLAGS) down

restart: down 

test: build
	docker-compose $(FLAGS) run --rm $(ATTACH_HOST) bundle exec rspec

bash: build
	docker-compose $(FLAGS) run --rm $(ATTACH_HOST) bash -l

build: .env base/Gemfile.lock
	docker-compose $(FLAGS) build 

.env:
	echo "RAILS_EMAIL_OVERRIDE=${EMAIL}" > .env

base/Gemfile.lock:
	touch base/Gemfile.lock

logs:
	docker-compose  $(FLAGS) logs -f
