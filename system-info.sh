#!/usr/bin/env bash
#
# system-info.sh
# Displays runtime system information: hostname, user, date/time, OS,
# kernel version, uptime, CPU info, memory info, and current working directory.
#
# Usage: ./system-info.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/toolkit.log"

mkdir -p "${LOG_DIR}"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | system-info.sh | $1" >> "${LOG_FILE}"
}

log "system-info.sh started"

echo "=================================================="
echo " SYSTEM INFORMATION"
echo "=================================================="

echo "Hostname          : $(hostname)"
echo "Current User      : $(whoami)"
echo "Date/Time         : $(date '+%Y-%m-%d %H:%M:%S %Z')"

if [ -f /etc/os-release ]; then
    OS_NAME=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    OS_NAME="$(uname -s)"
fi
echo "Operating System  : ${OS_NAME}"

echo "Kernel Version    : $(uname -r)"
echo "Uptime            : $(uptime -p 2>/dev/null || uptime)"

echo "--------------------------------------------------"
echo " CPU INFORMATION"
echo "--------------------------------------------------"
if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E 'Model name|CPU\(s\)|Thread|Core|Socket' || true
elif [ -f /proc/cpuinfo ]; then
    echo "Model name        : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')"
    echo "CPU(s)            : $(grep -c ^processor /proc/cpuinfo)"
else
    echo "CPU information not available on this system."
fi

echo "--------------------------------------------------"
echo " MEMORY INFORMATION"
echo "--------------------------------------------------"
if command -v free >/dev/null 2>&1; then
    free -h
else
    echo "Memory information not available (free command missing)."
fi

echo "--------------------------------------------------"
echo "Current Directory : $(pwd)"
echo "=================================================="

log "system-info.sh completed successfully"

exit 0
