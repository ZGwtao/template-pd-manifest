IMAGE_NAME ?= template-pd-manifest-env
IMAGE_TAG ?= local
IMAGE := $(IMAGE_NAME):$(IMAGE_TAG)

CONTAINER_NAME ?= template-pd-manifest-dev
WORKDIR ?= /workspace/carrels


.PHONY: repo-init
repo-init:
	@git submodule update --init --recursive


.PHONY: build-from-source
build-from-source: repo-init
	docker build \
		--progress=plain \
		-t $(IMAGE) \
		.


.PHONY: docker-run-clean
docker-run-clean:
	docker run --rm -it \
		--workdir $(WORKDIR) \
		$(IMAGE) \
		/bin/bash


.PHONY: docker-run-persistent
docker-run-persistent:
	@if docker container inspect $(CONTAINER_NAME) >/dev/null 2>&1; then \
		docker start --attach --interactive $(CONTAINER_NAME); \
	else \
		docker run -it \
			--name $(CONTAINER_NAME) \
			--workdir $(WORKDIR) \
			$(IMAGE) \
			/bin/bash; \
	fi


.PHONY: docker-run
docker-run: docker-run-clean


.PHONY: docker-reset-persistent
docker-reset-persistent:
	@if docker container inspect $(CONTAINER_NAME) >/dev/null 2>&1; then \
		docker rm --force $(CONTAINER_NAME); \
	else \
		echo "Container $(CONTAINER_NAME) does not exist"; \
	fi


.PHONY: docker-check
docker-check:
	docker run --rm \
		$(IMAGE) \
		/bin/bash -c '\
			set -eu; \
			echo "MICROKIT_SDK=$$MICROKIT_SDK"; \
			echo "LIONSOS=$$LIONSOS"; \
			python --version; \
			python -c "import sdfgen"; \
			test -d "$$MICROKIT_SDK"; \
			test -d "$$LIONSOS"; \
			echo "environment check passed" \
		'