#!/usr/bin/env bash
# Offline checks for scripts/shotgrid.mjs: syntax and argument parsing (--dry-run, no browser). Skips without Node.
set -u
script="$(cd "$(dirname "$0")" && pwd)/shotgrid.mjs"
if ! command -v node >/dev/null 2>&1; then
  echo "SKIP test-shotgrid: node not installed"
  exit 0
fi
fail=0
node --check "$script" || fail=1
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cd "$work" || exit 1

out="$(node "$script" https://x --wait body --dry-run 2>&1)"; code=$?
[ "$code" -eq 0 ] || { echo "FAIL: --wait after url exit $code"; fail=1; }
case "$out" in *'"outDir":"screens"'*'"wait":"body"'*) ;; *) echo "FAIL: default outDir/wait not parsed: $out"; fail=1 ;; esac
[ -e ./--wait ] && { echo "FAIL: directory --wait was created"; fail=1; }

out="$(node "$script" https://x out --wait sel --dry-run 2>&1)"; code=$?
[ "$code" -eq 0 ] || { echo "FAIL: explicit outDir exit $code"; fail=1; }
case "$out" in *'"outDir":"out"'*'"wait":"sel"'*) ;; *) echo "FAIL: outDir/wait not parsed: $out"; fail=1 ;; esac

expect2() {
  local label="$1"; shift
  local text code
  text="$(node "$script" "$@" 2>&1)"; code=$?
  [ "$code" -eq 2 ] || { echo "FAIL: $label should exit 2, got $code"; fail=1; }
  case "$text" in *Usage:*) ;; *) echo "FAIL: $label usage text missing"; fail=1 ;; esac
}
expect2 "--wait without value" https://x --wait --dry-run
expect2 "unknown flag" https://x --bogus --dry-run
expect2 "extra positional" https://x out extra --dry-run
expect2 "http url" http://example.org --dry-run
[ -e ./--bogus ] && { echo "FAIL: flag created a directory"; fail=1; }

[ "$fail" -eq 0 ] && echo "PASS test-shotgrid"
exit "$fail"
