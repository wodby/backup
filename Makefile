-include env_make

# Keep legacy build arguments compatible; RELEASE_VERSION selects the product tag.
BASE_IMAGE_REVISION ?= $(BASE_IMAGE_STABILITY_TAG)
IMAGE_REVISION ?= $(STABILITY_TAG)
RELEASE_VERSION ?= $(IMAGE_REVISION)

REPO = wodby/backup
NAME = wodby-backup

ALPINE_VER ?= 3

# Floating builds follow Alpine's major line; product builds use its published revision.
BASE_IMAGE_TAG := $(ALPINE_VER)
ifneq ($(RELEASE_VERSION),)
    ifeq ($(BASE_IMAGE_REVISION),)
        $(error Product releases require BASE_IMAGE_REVISION)
    endif
    BASE_IMAGE_TAG := $(ALPINE_VER)-$(BASE_IMAGE_REVISION)
endif


ifneq ($(RELEASE_VERSION),)
    override TAG := $(RELEASE_VERSION)
else
    TAG = latest
endif

PLATFORM ?= linux/amd64

.PHONY: build buildx-build buildx-build-amd64 buildx-push test push shell run start stop logs clean release

# Resolve the same pinned base image for every local and CI build target.
include base-images.mk

default: build

build:
	docker build --build-arg BASE_IMAGE="$(BASE_IMAGE)" -t $(REPO):$(TAG) ./

# --load doesn't work with multiple platforms https://github.com/docker/buildx/issues/59
# we need to save cache to run tests first.
buildx-build-amd64:
	docker buildx build --build-arg BASE_IMAGE="$(BASE_IMAGE)" --platform linux/amd64 -t $(REPO):$(TAG) \
		--load \
		./

buildx-build:
	docker buildx build --build-arg BASE_IMAGE="$(BASE_IMAGE)" --platform $(PLATFORM)  -t $(REPO):$(TAG) \
		./

buildx-push:
	docker buildx build --build-arg BASE_IMAGE="$(BASE_IMAGE)" --platform $(PLATFORM)  --push -t $(REPO):$(TAG) \
		./

test:
	./test-unit.sh
	IMAGE=$(REPO):$(TAG) ./tests/s3_restricted_permissions.sh
	IMAGE=$(REPO):$(TAG) ./test.sh

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -i -t $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	-docker rm -f $(NAME)

release: build push
