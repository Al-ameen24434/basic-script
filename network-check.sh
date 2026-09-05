#!/usr/bin/env bash
#
# network-check.sh
# Performs basic network diagnostics against a host, and optionally a port.
#
# Usage: ./network-check.sh <hostname-or-ip> [port]
#
# Exit codes:
#   0 -> host reachable (and port open, if supplied)
#   1 -> host resolved but not reachable / port closed
#   2 -> invalid input

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/toolkit.log"
mkdir -p "${LOG_DIR}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | network-check.sh | $1" >> "${LOG_FILE}"
}

usage() {
    echo "Usage: $0 <hostname-or-ip> [port]" >&2
}

HOST="${1:-}"
PORT="${2:-}"

if [ -z "${HOST}" ]; then
    echo "Error: host argument is required." >&2
    usage
    log "FAILED - missing host argument"
    exit 2
fi

# Basic sanity check on host string (letters, digits, dots, dashes, colons for IPv6)
if ! [[ "${HOST}" =~ ^[A-Za-z0-9.:-]+$ ]]; then
    echo "Error: '${HOST}' is not a valid hostname or IP." >&2
    log "FAILED - invalid host format '${HOST}'"
    exit 2
fi

# Validate port if supplied
if [ -n "${PORT}" ]; then
    if ! [[ "${PORT}" =~ ^[0-9]+$ ]] || [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
        echo "Error: port must be an integer between 1 and 65535." >&2
        usage
        log "FAILED - invalid port '${PORT}'"
        exit 2
    fi
fi

echo "=================================================="
echo " NETWORK CHECK: ${HOST}"
echo "=================================================="

# Resolve host
RESOLVED=""
if command -v getent >/dev/null 2>&1; then
    RESOLVED=$(getent hosts "${HOST}" 2>/dev/null | awk '{print $1}' | head -n1)
elif command -v host >/dev/null 2>&1; then
    RESOLVED=$(host "${HOST}" 2>/dev/null | awk '/has address/ {print $4; exit}')
fi

if [ -z "${RESOLVED}" ]; then
    # Fall back: maybe HOST is already an IP
    if [[ "${HOST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        RESOLVED="${HOST}"
    fi
fi

if [ -z "${RESOLVED}" ]; then
    echo "Resolution        : FAILED - could not resolve '${HOST}'"
    log "FAILED - could not resolve '${HOST}'"
    RESOLVE_OK=1
else
    echo "Resolution        : ${HOST} -> ${RESOLVED}"
    log "OK - resolved '${HOST}' -> ${RESOLVED}"
    RESOLVE_OK=0
fi

# Basic connectivity check (ping, 1 packet, short timeout)
echo "--------------------------------------------------"
if command -v ping >/dev/null 2>&1; then
    if ping -c 1 -W 2 "${HOST}" >/dev/null 2>&1; then
        echo "Connectivity      : REACHABLE (ping)"
        log "OK - ping to '${HOST}' succeeded"
        PING_OK=0
    else
        echo "Connectivity      : NOT REACHABLE (ping failed or blocked)"
        log "WARNING - ping to '${HOST}' failed"
        PING_OK=1
    fi
else
    echo "Connectivity      : ping not available on this system"
    PING_OK=1
fi

# Network interface information
echo "--------------------------------------------------"
echo " NETWORK INTERFACES"
echo "--------------------------------------------------"
if command -v ip >/dev/null 2>&1; then
    ip -brief addr show 2>/dev/null || ip addr show
elif command -v ifconfig >/dev/null 2>&1; then
    ifconfig
else
    echo "No interface tool (ip/ifconfig) available."
fi

# Optional TCP port check
PORT_OK=0
if [ -n "${PORT}" ]; then
    echo "--------------------------------------------------"
    echo " PORT CHECK: ${HOST}:${PORT}"
    echo "--------------------------------------------------"
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/${HOST}/${PORT}" 2>/dev/null; then
        echo "Port ${PORT}            : OPEN"
        log "OK - port ${PORT} open on '${HOST}'"
        PORT_OK=0
    else
        echo "Port ${PORT}            : CLOSED or FILTERED"
        log "WARNING - port ${PORT} closed/filtered on '${HOST}'"
        PORT_OK=1
    fi
fi

echo "=================================================="

if [ "${RESOLVE_OK}" -ne 0 ]; then
    exit 1
fi
if [ -n "${PORT}" ] && [ "${PORT_OK}" -ne 0 ]; then
    exit 1
fi
if [ -z "${PORT}" ] && [ "${PING_OK}" -ne 0 ]; then
    # Resolution worked but host isn't pingable - still report as a soft failure
    exit 1
fi

exit 0

