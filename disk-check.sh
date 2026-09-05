#!/usr/bin/env bash
#
# disk-check.sh
# Checks disk usage percentage against a threshold.
#
# Usage: ./disk-check.sh <threshold> [path]
#   threshold : integer 1-100 (required)
#   path      : filesystem path to check (default: /)
#
# Exit codes:
#   0 -> usage is below threshold
#   1 -> usage has reached or exceeded threshold
#   2 -> invalid input

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/toolkit.log"
mkdir -p "${LOG_DIR}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | disk-check.sh | $1" >> "${LOG_FILE}"
}

usage() {
    echo "Usage: $0 <threshold 1-100> [path]" >&2
}

THRESHOLD="${1:-}"
CHECK_PATH="${2:-/}"

# Validate threshold: must be present and an integer 1-100
if [ -z "${THRESHOLD}" ]; then
    echo "Error: threshold argument is required." >&2
    usage
    log "FAILED - missing threshold argument"
    exit 2
fi

if ! [[ "${THRESHOLD}" =~ ^[0-9]+$ ]]; then
    echo "Error: threshold must be an integer." >&2
    usage
    log "FAILED - non-integer threshold '${THRESHOLD}'"
    exit 2
fi

if [ "${THRESHOLD}" -lt 1 ] || [ "${THRESHOLD}" -gt 100 ]; then
    echo "Error: threshold must be between 1 and 100." >&2
    usage
    log "FAILED - threshold out of range '${THRESHOLD}'"
    exit 2
fi

# Validate path exists
if [ ! -e "${CHECK_PATH}" ]; then
    echo "Error: path '${CHECK_PATH}' does not exist." >&2
    log "FAILED - invalid path '${CHECK_PATH}'"
    exit 2
fi

# Get disk usage percentage (strip the trailing %)
USAGE=$(df -P "${CHECK_PATH}" | awk 'NR==2 {print $5}' | tr -d '%')

if [ -z "${USAGE}" ]; then
    echo "Error: could not determine disk usage for '${CHECK_PATH}'." >&2
    log "FAILED - could not read df output for '${CHECK_PATH}'"
    exit 2
fi

echo "Path              : ${CHECK_PATH}"
echo "Disk usage        : ${USAGE}%"
echo "Threshold         : ${THRESHOLD}%"

if [ "${USAGE}" -ge "${THRESHOLD}" ]; then
    echo "Status            : WARNING - usage has reached or exceeded threshold"
    log "WARNING - ${CHECK_PATH} usage ${USAGE}% >= threshold ${THRESHOLD}%"
    exit 1
else
    echo "Status            : OK - usage below threshold"
    log "OK - ${CHECK_PATH} usage ${USAGE}% < threshold ${THRESHOLD}%"
    exit 0
fi
