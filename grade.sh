#!/usr/bin/env bash
#
# grade.sh (Assignment 1)
# NOTE: This is a re-creation based on the checks described in the assignment
# brief (required files, Bash syntax, executable permissions, system-info
# output, disk argument validation, network validation, logging, basic Git
# history). Your instructor's real grade.sh may differ in detail - use this
# to self-check before submitting.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=================================================="
echo " Assignment 1 - Grading Checks"
echo "=================================================="

echo
echo "-- Required files --"
for f in README.md system-info.sh disk-check.sh network-check.sh; do
    if [ -f "$f" ]; then pass "found $f"; else fail "missing $f"; fi
done
if [ -d logs ]; then pass "logs/ directory exists"; else fail "logs/ directory missing"; fi

echo
echo "-- Bash syntax --"
for f in system-info.sh disk-check.sh network-check.sh; do
    if [ -f "$f" ]; then
        if bash -n "$f" 2>/dev/null; then
            pass "$f has valid syntax"
        else
            fail "$f has a syntax error"
        fi
    fi
done

echo
echo "-- Executable permissions --"
for f in system-info.sh disk-check.sh network-check.sh; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        pass "$f is executable"
    else
        fail "$f is not executable"
    fi
done

echo
echo "-- system-info.sh output --"
if [ -x system-info.sh ]; then
    OUT=$(./system-info.sh 2>/dev/null)
    for keyword in "Hostname" "User" "Kernel" "Uptime" "CPU" "Memory" "Directory"; do
        if echo "$OUT" | grep -qi "$keyword"; then
            pass "output mentions '$keyword'"
        else
            fail "output missing '$keyword'"
        fi
    done
fi

echo
echo "-- disk-check.sh argument validation --"
if [ -x disk-check.sh ]; then
    ./disk-check.sh >/dev/null 2>&1; [ $? -eq 2 ] && pass "no args -> exit 2" || fail "no args should exit 2"
    ./disk-check.sh abc >/dev/null 2>&1; [ $? -eq 2 ] && pass "non-integer -> exit 2" || fail "non-integer should exit 2"
    ./disk-check.sh 0 >/dev/null 2>&1; [ $? -eq 2 ] && pass "out-of-range (0) -> exit 2" || fail "out-of-range should exit 2"
    ./disk-check.sh 101 >/dev/null 2>&1; [ $? -eq 2 ] && pass "out-of-range (101) -> exit 2" || fail "out-of-range should exit 2"
    ./disk-check.sh 100 / >/dev/null 2>&1; [ $? -eq 0 ] && pass "threshold 100 on / -> exit 0" || fail "threshold 100 should normally pass"
    ./disk-check.sh 1 / >/dev/null 2>&1; [ $? -eq 1 ] && pass "threshold 1 on / -> exit 1 (over)" || fail "threshold 1 should normally trigger warning"
fi

echo
echo "-- network-check.sh validation --"
if [ -x network-check.sh ]; then
    ./network-check.sh >/dev/null 2>&1; [ $? -eq 2 ] && pass "no args -> exit 2" || fail "no args should exit 2"
    ./network-check.sh "bad host!!" >/dev/null 2>&1; [ $? -eq 2 ] && pass "invalid host -> exit 2" || fail "invalid host should exit 2"
    ./network-check.sh localhost 99999 >/dev/null 2>&1; [ $? -eq 2 ] && pass "invalid port -> exit 2" || fail "invalid port should exit 2"
    ./network-check.sh localhost >/dev/null 2>&1; [ $? -eq 0 ] && pass "localhost resolves/reachable" || fail "localhost should resolve"
fi

echo
echo "-- Logging --"
if [ -f logs/toolkit.log ] && [ -s logs/toolkit.log ]; then
    pass "logs/toolkit.log exists and has entries"
else
    fail "logs/toolkit.log missing or empty (run the scripts at least once)"
fi

echo
echo "-- Git history --"
if [ -d .git ]; then
    COMMITS=$(git log --oneline 2>/dev/null | wc -l)
    if [ "$COMMITS" -ge 5 ]; then pass "found $COMMITS commits (>=5)"; else fail "only $COMMITS commits (need >=5)"; fi
    BRANCHES=$(git branch -a 2>/dev/null | grep -vE 'main|master|HEAD' | wc -l)
    if [ "$BRANCHES" -ge 1 ]; then pass "found a non-main branch"; else fail "no feature branch found"; fi
else
    fail "not a git repository"
fi

echo
echo "=================================================="
echo " RESULT: ${PASS} passed, ${FAIL} failed"
echo "=================================================="

if [ "${FAIL}" -eq 0 ]; then
    exit 0
else
    exit 1
fi
