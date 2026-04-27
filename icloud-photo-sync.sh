#!/usr/bin/env bash
# Usage: ./icloud-photo-sync.sh <instance_name> [ AUTH | SYNC ]
#
# Ubuntu: use bash (default when chmod +x and ./icloud-photo-sync.sh). Running with
# `sh icloud-photo-sync.sh` uses dash and will fail; use `bash icloud-photo-sync.sh ...` instead.

if [ -z "${BASH_VERSION:-}" ]; then
  echo "icloud-photo-sync.sh requires bash, not sh/dash." >&2
  exit 1
fi

usage() {
  echo "Usage: $0 <instance_name> [ AUTH | SYNC ]" >&2
  exit 1
}

[[ $# -eq 2 ]] || usage

INSTANCE_NAME="$1"
MODE=$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')

case "${MODE}" in
  AUTH|SYNC) ;;
  *)
    echo "Invalid mode: $2 (expected AUTH or SYNC)" >&2
    usage
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/${INSTANCE_NAME}.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing env file: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "${ENV_FILE}"
set +a

INTERVAL="${INTERVAL:-36000}"
UNTIL_FOUND="${UNTIL_FOUND:-500}"
TZ="${TZ:-America/Los_Angeles}"

# Optional: default is ./cookies relative to the current working directory (PWD).
COOKIE_FOLDER="${COOKIE_FOLDER:-${PWD}/cookies}"
DATA_FOLDER="${DATA_FOLDER:-${PWD}/data}"

# Required in ${INSTANCE_NAME}.env — no defaults (unset or empty exits here).
: "${ICLOUD_USERNAME:?Set ICLOUD_USERNAME in ${INSTANCE_NAME}.env}"
: "${ICLOUD_PASSWORD:?Set ICLOUD_PASSWORD in ${INSTANCE_NAME}.env}"

case "${MODE}" in
  AUTH)
    if ! mkdir -p "${COOKIE_FOLDER}"; then
      echo "Could not create COOKIE_FOLDER: ${COOKIE_FOLDER}" >&2
      exit 1
    fi
    AUTH_NAME="${INSTANCE_NAME}-auth-only-icloudpd"
    CONTAINER_NAME="${AUTH_NAME}"
    docker_run_flags=( -it --rm )
    icloudpd_extra=( --auth-only )
    ;;
  SYNC)
    if [[ ! -d "${COOKIE_FOLDER}" ]]; then
      echo "SYNC: COOKIE_FOLDER must exist as a directory (run AUTH first): ${COOKIE_FOLDER}" >&2
      exit 1
    fi
    SYNC_NAME="${INSTANCE_NAME}-sync-icloudpd"
    CONTAINER_NAME="${SYNC_NAME}"
    docker_run_flags=( -it -d --rm )
    icloudpd_extra=( --until-found "${UNTIL_FOUND}" --watch-with-interval "${INTERVAL}" )
    ;;
esac

docker kill "${CONTAINER_NAME}" 2>/dev/null || true
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

docker run "${docker_run_flags[@]}" \
  --name "${CONTAINER_NAME}" \
  -v "${DATA_FOLDER}/${INSTANCE_NAME}:/data" \
  -v "${COOKIE_FOLDER}:/app/cookie" \
  -e "TZ=${TZ}" \
  icloudpd/icloudpd:latest \
  icloudpd \
  --directory /data \
  --username "${ICLOUD_USERNAME}" \
  --password "${ICLOUD_PASSWORD}" \
  --cookie-directory /app/cookie \
  "${icloudpd_extra[@]}"
