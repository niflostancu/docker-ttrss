# Docker image Makefile

VERSION=$(shell cat VERSION)
PUSH?=
ALL?=$(PUSH)
LOAD?=$(if $(ALL),,1)

IMAGE_NAME = ttrss
IMAGE_TAGS = $(VERSION)
IMAGE_PREFIX = niflostancu/
FULL_IMAGE_NAME=$(IMAGE_PREFIX)$(IMAGE_NAME)

# Note: armv7 doesn't build yet
PLATFORMS=linux/amd64,linux/arm64
BUILDX_ARGS?=
BUILDX_ARGS+=$(if $(ALL),--platform $(PLATFORMS))

-include local.mk

_full_tag_args = $(foreach tag,latest $(IMAGE_TAGS),-t "$(FULL_IMAGE_NAME):$(tag)")

build:
	docker buildx build $(BUILDX_ARGS) $(_full_tag_args) -f Dockerfile \
		$(if $(PUSH),--push,$(if $(LOAD),--load)) .

build_force: BUILDX_ARGS+= --pull --no-cache
build_force: build

push: PUSH=1
push: build

run_bash:
	docker run -it --env S6_BEHAVIOUR_IF_STAGE2_FAILS=0 "$(FULL_IMAGE_NAME)" bash

run:
	docker-compose up

.PHONY: build build_force push test

