#!/usr/bin/env bash
# Offline checks for scripts/shotgrid.mjs: syntax and argument validation. Skips without Node.
set -u
cd "$(dirname "$0")" || exit 1
if ! command -v node >/dev/null 2>&1; then
  echo "SKIP test-shotgrid: node not installed"
  exit 0
fi
fail=0
node --check shotgrid.mjs || fail=1
out="$(node shotgrid.mjs http://example.org 2>&1)"
code=$?
[ "$code" -eq 2 ] || { echo "FAIL: non-https URL should exit 2, got $code"; fail=1; }
case "$out" in *Usage:*) ;; *) echo "FAIL: usage text missing"; fail=1 ;; esac
[ "$fail" -eq 0 ] && echo "PASS test-shotgrid"
exit "$fail"
