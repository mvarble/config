#!/usr/bin/env bash
# mount-sshfs-if-needed.sh

set -euo pipefail

SSHFS_BIN="$(command -v sshfs || true)"
MOUNTPOINT_BIN="$(command -v mountpoint || true)"
LOGGER_BIN="$(command -v logger || true)"

log() {
  local msg="$*"
  if [[ -n "${LOGGER_BIN}" ]]; then
    "${LOGGER_BIN}" -t sshfs-mounter -- "${msg}"
  fi
  # Always print to stderr so cron redirection catches it
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${msg}" >&2
}

if [[ -z "$SSHFS_BIN" ]] || [[ -z "$MOUNTPOINT_BIN" ]]; then
  log "FATAL: sshfs or mountpoint binary not found in PATH."
  exit 1
fi

# config variables
MOUNTPOINT="${MOUNTPOINT:?set MOUNTPOINT}"
REMOTE="${REMOTE:?set REMOTE}"
IDENTITY_FILE="${IDENTITY_FILE:-}"
SSH_PORT="${SSH_PORT:-22}"

# Ensure mountpoint exists
if [[ ! -d "${MOUNTPOINT}" ]]; then
  log "Mountpoint does not exist: ${MOUNTPOINT}"
  exit 1
fi

# If already mounted, nothing to do
if "${MOUNTPOINT_BIN}" -q "${MOUNTPOINT}"; then
  exit 0
fi

opts=(
  -o reconnect
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=3
  -o StrictHostKeyChecking=accept-new
  -p "${SSH_PORT}"
)

if [[ -n "${IDENTITY_FILE}" ]]; then
  opts+=( -o "IdentityFile=${IDENTITY_FILE}" )
fi

log "Not mounted; attempting sshfs mount: ${REMOTE} -> ${MOUNTPOINT}"

if "${SSHFS_BIN}" "${opts[@]}" "${REMOTE}" "${MOUNTPOINT}"; then
  log "Mount successful: ${MOUNTPOINT}"
  exit 0
else
  log "Mount FAILED: ${MOUNTPOINT}"
  exit 1
fi
