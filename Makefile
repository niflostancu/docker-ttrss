# Docker image Makefile

IMAGE_NAME = ttrss
IMAGE_TAGS ?= v0.3
IMAGE_PREFIX ?= niflostancu/
FULL_IMAGE_NAME=$(IMAGE_PREFIX)$(IMAGE_NAME)

-include local.mk

build:
	docker build $(BUILD_ARGS) -t $(FULL_IMAGE_NAME) -f Dockerfile .
	$(foreach TAG,$(IMAGE_TAGS),docker tag $(FULL_IMAGE_NAME) $(FULL_IMAGE_NAME):$(TAG);)

build_force: BUILD_ARGS+= --pull --no-cache
build_force: build

push:
	docker push $(FULL_IMAGE_NAME):latest
	$(foreach TAG,$(IMAGE_TAGS),docker push $(FULL_IMAGE_NAME):$(TAG);)

run:
	docker-compose up

.PHONY: build build_force push test

