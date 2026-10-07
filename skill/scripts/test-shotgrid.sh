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
expect2 "single-dash flag" https://x -o --dry-run
expect2 "--wait dash value" https://x --wait -d --dry-run
node "$script" -h 2>&1 | grep -q Usage: || { echo "FAIL: -h prints no usage"; fail=1; }
expect2 "extra positional" https://x out extra --dry-run
expect2 "http url" http://example.org --dry-run
expect2 "http lookalike host" http://localhost.evil.test --dry-run
node "$script" http://localhost:3000/app --dry-run >/dev/null 2>&1 || { echo "FAIL: http://localhost rejected"; fail=1; }

mkdir -p node_modules/playwright-core
printf 'module.exports={chromium:{launch:async()=>{console.log("CWD-STUB");process.exit(0)}}};' > node_modules/playwright-core/index.js
printf '{"name":"playwright-core","main":"index.js"}' > node_modules/playwright-core/package.json
out="$(PW_CORE='' node "$script" https://x 2>&1)"
case "$out" in *CWD-STUB*) ;; *) echo "FAIL: playwright-core in cwd not resolved: $out"; fail=1 ;; esac

[ "$fail" -eq 0 ] && echo "PASS test-shotgrid"
exit "$fail"
