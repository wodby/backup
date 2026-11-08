# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/alpine
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_3 := sha256:48e9bd7448c6ae439a2a116f6debee6824a1e120b26080b7d3fe7a9ab716894a
BASE_IMAGE_DIGEST_3-r15 := sha256:348b898bcb7d37cb1d51c3dcdb246011f4eb717fa0d88bf73ab53ec5955c4d69

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
