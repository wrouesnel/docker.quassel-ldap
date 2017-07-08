
SRC := $(shell find . \( -path './.git' -o -path './.docker.log' -o -path './.dockerid' -o -path './.cidfile' \) -prune -o -print)

DOCKER_HOST ?= unix:///var/run/docker.sock
DOCKER_BUILD_ARGS ?= --build-arg http_proxy=$(http_proxy) --build-arg https_proxy=$(https_proxy)

CIDFILE = .cidfile

.PHONY: run run-it exec-into clean get-ip

all: .dockerid

.dockerid: $(SRC)
	docker build $(DOCKER_BUILD_ARGS) $(EXTRA_BUILD_ARGS) . | tee .docker.log
	docker inspect -f '{{ .Id }}' `tail -n1 .docker.log | cut -d' ' -f3` > $@ || ( rm -f .dockerid ; exit 1 )

run-it: .dockerid
	rm -f $(CIDFILE)
	docker run -e \
		-e DEV_ALLOW_EPHEMERAL_DATA=yes \
		-e DEV_QUASSEL_DEBUG=yes \
		-e POSTGRES_HOSTNAME=$(POSTGRES_HOSTNAME) \
		-e POSTGRES_USER=$(POSTGRES_USER) \
		-e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
		-e POSTGRES_DATABASE=$(POSTGRES_DATABASE) \
		-e POSTGRES_PORT=5432 \
		-e LDAP_HOSTNAME=$(LDAP_HOSTNAME) \
		-e LDAP_PORT=363 \
		-e LDAP_BIND_DN=$(LDAP_BIND_DN) \
		-e LDAP_BIND_PASSWORD=$(LDAP_BIND_PASSWORD) \
		-e LDAP_BASE_DN=$(LDAP_BASE_DN) \
		-e LDAP_FILTER=(objectClass=posixAccount) \
		-e LDAP_UID_ATTR=uid \
		--tmpfs /run:suid,exec --tmpfs /tmp:suid,exec \
		--read-only \
		-it --rm --cidfile=$(CIDFILE) $(EXTRA_RUN_ARGS) `cat .dockerid`

run: .dockerid
	rm -f $(CIDFILE)
	docker run --rm --cidfile=$(CIDFILE) `cat .dockerid`

# Exec's into the most recently run container.
exec-into:
	docker exec -it $(shell cat $(CIDFILE)) /bin/bash

get-ip:
	@docker inspect -f '{{ .NetworkSettings.IPAddress }}' $(shell cat $(CIDFILE))

clean:
	rm -f $(CIDFILE) .dockerid
