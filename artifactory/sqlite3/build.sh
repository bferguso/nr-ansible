#!/bin/bash
set -euo nounset

SQLITE_VERSION=$1

# Build
podman build --build-arg SQLITE_VERSION=${SQLITE_VERSION} -t sqlite-${SQLITE_VERSION} .

# Run (remove stale)
podman rm -fv sqlite-origin || true
podman run --name=sqlite-origin -tid sqlite-${SQLITE_VERSION} bash

# Copy out
podman cp sqlite-origin:/dropbox/sqlite.tar.gz .

# Clean up
podman rm -fv sqlite-origin

# Artifactory instructions
echo -e "\nUpload to Artifactory:"
curl -X PUT -u "${ARTIFACTORY_USER}:${ARTIFACTORY_PASS}" -T sqlite.tar.gz "https://bwa.nrs.gov.bc.ca/int/artifactory/ext-binaries-local/sqlite/${SQLITE_VERSION}/sqlite.tar.gz"
