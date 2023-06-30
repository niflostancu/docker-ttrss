# Docker image Makefile

VERSION=$(shell cat VERSION)

PUSH=
IMAGE_NAME = ttrss
IMAGE_TAGS = $(VERSION)
IMAGE_PREFIX = niflostancu/
FULL_IMAGE_NAME=$(IMAGE_PREFIX)$(IMAGE_NAME)
BUILD_ARGS=--platform linux/amd64,linux/arm64
PUSH?=

-include local.mk

_full_tag_args = $(foreach tag,latest $(IMAGE_TAGS),-t "$(FULL_IMAGE_NAME):$(tag)")

build:
	docker buildx build $(BUILD_ARGS) $(_full_tag_args) -f Dockerfile \
		$(if $(PUSH),--push,) .

build_force: BUILD_ARGS+= --pull --no-cache
build_force: build

push: PUSH=1
push: build

run:
	docker-compose up

.PHONY: build build_force push test

