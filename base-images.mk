# Base image inputs shared by local builds and CI. Updated by wodby/images.
# Each digest identifies the complete multi-platform image index.
BASE_IMAGE_REPOSITORY := wodby/alpine
BASE_IMAGE_VERSION_SUFFIX :=

BASE_IMAGE_DIGEST_3 := sha256:41d48326ffb6c5634f42818bd428b42a4ab7c7c0ae0b170bbf80422e6f7902c2
BASE_IMAGE_DIGEST_3-r6 := sha256:3f9bc05ab1d185a8d7f54e0ea05fc477c408fe0b9642f149ab2aedfa240d47fd

# Fail before building when a version or variant has no reviewed pin.
BASE_IMAGE = $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG)@$(or $(BASE_IMAGE_DIGEST_$(BASE_IMAGE_TAG)),$(error No base image digest for $(BASE_IMAGE_REPOSITORY):$(BASE_IMAGE_TAG); update base-images.mk))
