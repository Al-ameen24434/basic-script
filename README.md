# Assignment 1 — Linux, Bash & Networking Diagnostic Toolkit

A  Bash-based diagnostic toolkit that reports system information, checks
disk usage against a threshold, and performs basic network connectivity checks.



## Installation / Setup

No dependencies beyond a standard Linux environment with `bash`, `df`, `ping`,
and either `ip` or `ifconfig`. Clone the repo and make the scripts executable:

```bash
git clone <your-repository-url>
cd assignment-1
chmod +x *.sh
```

## Usage

### system-info.sh
```bash
./system-info.sh
```
Prints hostname, current user, date/time, OS, kernel version, uptime, CPU
info, memory info, and current working directory. All values are read live
from the system — nothing is hardcoded.

### disk-check.sh
```bash
./disk-check.sh <threshold> [path]
```
- `threshold`: required integer 1–100.
- `path`: optional, defaults to `/`.
- Exit 0 if usage is below threshold, exit 1 if usage has reached/exceeded
  the threshold, exit 2 for invalid input (missing/non-integer/out-of-range
  threshold, or a path that doesn't exist).

Example:
```bash
./disk-check.sh 80 /home
```

### network-check.sh
```bash
./network-check.sh <hostname-or-ip> [port]
```
- Validates the host, resolves it, shows the resolved address, runs a basic
  ping connectivity check, and lists network interfaces.
- If a port (1–65535) is supplied, also performs a TCP connectivity check
  against that host:port using bash's `/dev/tcp`.
- Exit 0 on success, exit 1 if the host/port isn't reachable, exit 2 for
  invalid input.

Example:
```bash
./network-check.sh github.com 443
```

## Testing

Run each script manually with valid and invalid input, and check `logs/toolkit.log`
for corresponding timestamped entries. You can also run the self-check grader:

```bash
./grade.sh
```

## Logging

Every run of every script appends a timestamped line to `logs/toolkit.log`,
describing what operation ran and its result (OK / WARNING / FAILED).

## Assumptions

- "Basic connectivity check" is implemented via a single `ping -c 1` with a
  2-second timeout; environments that block ICMP will report the host as not
  reachable even if it is otherwise up.
- Port checks use Bash's built-in `/dev/tcp` pseudo-device rather than
  external tools like `nc`, to minimize dependencies.
- Only IPv4-style validation is used for the basic host format check;
  IPv6 addresses are allowed by the character class but not deeply validated.

## Git Workflow

This repository was developed with a `feature/simulated-grade-script` branch (grading logic) merged into `main` and also readme.md branch . See `git log --graph --oneline --all`.
