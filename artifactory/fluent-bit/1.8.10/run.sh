#!/bin/bash
set -euo nounset

# Build
podman build -t fb-1.8.10 .

# Run (remove stale)
podman rm -fv fb-origin || true
podman run --name=fb-origin -tid fb-1.8.10 bash

# Copy out
podman cp fb-origin:/dropbox/fluent-bit.tar.gz .

# Clean up
podman rm -fv fb-origin

# Artifactory instructions
echo -e "\nUpload to Artifactory:"
echo -e "  curl -X PUT -u \"email.address@gov.bc.ca:password\" -T fluent-bit.tar.gz \"https://bwa.nrs.gov.bc.ca/int/artifactory/ext-binaries-local/fluent/fluent-bit/1.8.7/fluent-bit.tar.gz\"\n"
