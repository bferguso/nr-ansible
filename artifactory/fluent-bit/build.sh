#!/bin/bash
set -euo nounset

FLUENT_BIT_VERSION=$1

# Build
podman build --build-arg FLUENT_BIT_VERSION=${FLUENT_BIT_VERSION} -t fb-${FLUENT_BIT_VERSION} .

# Run (remove stale)
podman rm -fv fb-origin || true
podman run --name=fb-origin -tid fb-${FLUENT_BIT_VERSION} bash

# Copy out
podman cp fb-origin:/dropbox/fluent-bit.tar.gz .

# Clean up
podman rm -fv fb-origin

# Artifactory instructions
echo -e "\nUpload to Artifactory:"
curl -X PUT -u "${ARTIFACTORY_USER}:${ARTIFACTORY_PASS}" -T fluent-bit.tar.gz "https://bwa.nrs.gov.bc.ca/int/artifactory/ext-binaries-local/fluent/fluent-bit/${FLUENT_BIT_VERSION}/fluent-bit.tar.gz"
