#!/usr/bin/env bash
# Build patched icloudpd image and export ICLOUDPD_IMAGE for the current shell.
#
# Run with source so the export persists (a plain ./build.sh runs in a subshell):
#   source ./build.sh
#   . ./build.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker build -f "${SCRIPT_DIR}/Dockerfile.icloudpd-pr1327" \
  --build-arg ICLOUDPD_GIT_REF=refs/pull/1335/head \
  -t icloudpd:pr1335 \
  "${SCRIPT_DIR}"

export ICLOUDPD_IMAGE=icloudpd:pr1335

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "ICLOUDPD_IMAGE was only set in this subshell. Run:  source ${0##*/}  (from ${SCRIPT_DIR})" >&2
fi
