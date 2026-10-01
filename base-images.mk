# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/alpine
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_3 := sha256:b666411609e815208c7512155f38e80272d5c4b3d4ad1cff10d9e33fb4f3d6bd
BASE_IMAGE_DIGEST_3-r1 := sha256:7ccc1cc4eb781f9da81d4508ad76fc920a359da05e9398ed34e48ccfcc0dd96a

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
