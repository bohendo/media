# Specify make-specific variables (VPATH = prerequisite search path)
VPATH=.flags
SHELL=/bin/bash

dir=$(shell cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )
project=$(shell cat $(dir)/package.json | jq .name | tr -d '"')
find_options=-type f -not -path "*/node_modules/*" -not -name "*.swp" -not -path "*/.*" -not -name "*.log"

# Pool of images to pull cached layers from during docker build steps
cache_from=$(shell if [[ -n "${CI}" ]]; then echo "--cache-from=$(project)_builder:latest,$(project)_server:$(commit),$(project)_server:latest,$(project)_webserver:$(commit),$(project)_webserver:latest,$(project)_proxy:$(commit),$(project)_proxy:latest"; else echo ""; fi)

cwd=$(shell pwd)
commit=$(shell git rev-parse HEAD | head -c 8)
semver=v$(shell cat package.json | grep '"version":' | awk -F '"' '{print $$4}')

# Setup docker run time
# If on Linux, give the container our uid & gid so we know what to reset permissions to
# On Mac, the docker-VM takes care of this for us so pass root's id (ie noop)
my_id=$(shell id -u):$(shell id -g)
id=$(shell if [[ "`uname`" == "Darwin" ]]; then echo 0:0; else echo $(my_id); fi)
interactive=$(shell if [[ -t 0 && -t 2 ]]; then echo "--interactive"; else echo ""; fi)
docker_run=docker run --name=$(project)_builder $(interactive) --tty --rm --volume=$(cwd):/root $(project)_builder $(id)

startTime=.flags/.startTime
totalTime=.flags/.totalTime
log_start=@echo "=============";echo "[Makefile] => Start building $@"; date "+%s" > $(startTime)
log_finish=@echo $$((`date "+%s"` - `cat $(startTime)`)) > $(totalTime); rm $(startTime); echo "[Makefile] => Finished building $@ in `cat $(totalTime)` seconds";echo "=============";echo

# Env setup
$(shell mkdir -p .flags)

########################################
# Command & Control Shortcuts

default: dev
all: dev prod
dev: server proxy
prod: dev webserver

start: dev
	bash ops/start.sh

restart: stop
	bash ops/start.sh

stop:
	bash ops/stop.sh

clean: stop
	docker container prune -f
	rm -rf .flags
	rm -rf modules/**/build
	rm -rf modules/**/dist

reset: stop
	docker container prune -f
	rm -rf .docker-compose.yml
	rm -rf .bash_history .config

purge: clean reset

push: push-commit
push-commit:
	bash ops/push-images.sh $(commit)
push-semver:
	bash ops/pull-images.sh $(commit)
	bash ops/tag-images.sh $(semver)
	bash ops/push-images.sh $(semver)

pull: pull-latest
pull-latest:
	bash ops/pull-images.sh latest
pull-commit:
	bash ops/pull-images.sh $(commit)
pull-semver:
	bash ops/pull-images.sh $(semver)

dls:
	@docker service ls && echo '=====' && docker container ls -a

########################################
# Common Prerequisites

builder: $(shell find ops/builder $(find_options))
	$(log_start)
	docker build --file ops/builder/Dockerfile $(cache_from) --tag $(project)_builder ops/builder
	docker tag $(project)_builder $(project)_builder:$(commit)
	$(log_finish) && mv -f $(totalTime) .flags/$@

node-modules: builder $(shell find modules/*/package.json $(find_options))
	$(log_start)
	$(docker_run) "lerna bootstrap --hoist"
	$(log_finish) && mv -f $(totalTime) .flags/$@

########################################
# Compile/Transpile src

client-bundle: node-modules $(shell find modules/client $(find_options))
	$(log_start)
	$(docker_run) "cd modules/client && npm run build"
	$(log_finish) && mv -f $(totalTime) .flags/$@

server-bundle: node-modules $(shell find modules/server $(find_options))
	$(log_start)
	$(docker_run) "cd modules/server && npm run build && touch src/entry.ts"
	$(log_finish) && mv -f $(totalTime) .flags/$@

########################################
# Build docker images

proxy: $(shell find ops/proxy $(find_options))
	$(log_start)
	docker build --file ops/proxy/Dockerfile $(cache_from) --tag $(project)_proxy:latest ops/proxy
	docker tag $(project)_proxy:latest $(project)_proxy:$(commit)
	$(log_finish) && mv -f $(totalTime) .flags/$@

webserver: client-bundle $(shell find modules/client/ops $(find_options))
	$(log_start)
	docker build --file modules/client/ops/Dockerfile $(cache_from) --tag $(project)_webserver:latest modules/client
	docker tag $(project)_webserver:latest $(project)_webserver:$(commit)
	$(log_finish) && mv -f $(totalTime) .flags/$@

server: server-bundle $(shell find modules/server/ops $(find_options))
	$(log_start)
	docker build --file modules/server/ops/Dockerfile $(cache_from) --tag $(project)_server:latest modules/server
	docker tag $(project)_server:latest $(project)_server:$(commit)
	$(log_finish) && mv -f $(totalTime) .flags/$@
