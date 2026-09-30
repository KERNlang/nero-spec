#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
MATRIX="$HERE/e2e-matrix.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
T="$(mktemp -d "$TMP_BASE/spec-review-security.XXXXXX")" || exit 2
case "$T" in "$TMP_BASE"/spec-review-security.*) [ -d "$T" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$T"' EXIT
CASE="${1:-all}"
PASS=0
FAIL=0
OUT=""
RC=0

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" symbolic-ref HEAD refs/heads/main
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
  git -C "$1" config commit.gpgsign false
}

commit_at() {
  git -C "$1" add -A
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$1" commit -qm "$3"
}

expect_rc() {
  if [ "$RC" = "$1" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 exit $RC: $OUT"; fi
}

expect_output() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 output: $OUT"; fi
}

expect_absent() {
  if [ ! -e "$1" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 created $1"; fi
}

colon_filename() {
  local r="$T/colon/root" api="$T/colon/api" web="$T/colon/web" f file marker bin="$T/colon/bin"
  marker="$T/colon/arithmetic-sentinel"
  new_repo "$r"; new_repo "$api"; new_repo "$web"
  mkdir -p "$bin"
  cat > "$bin/touch" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$SPEC_TOUCH_LOG"
EOF
  chmod +x "$bin/touch"
  printf "app.post('/api/orders', () => ({order_id: 1}))\n" > "$api/routes.js"
  commit_at "$api" '2026-01-01T12:00:00+00:00' api
  file='prefix:FIELD_WINDOW[$(touch${IFS}arithmetic-sentinel)]:suffix.js'
  printf "fetch('/api/orders')\n" > "$web/$file"
  commit_at "$web" '2026-01-01T12:00:00+00:00' web
  mkdir -p "$r/.claude/specs/colon"
  f="$r/.claude/specs/colon/spec.md"
  cat > "$f" <<'EOF'
# Colon filename
**Status:** READY TO BUILD
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| `POST /api/orders` | `order_id` | api | web |
## Refine
Critic: reviewer
EOF
  OUT="$(PATH="$bin:$PATH" SPEC_TOUCH_LOG="$marker" "$CHECK" --strict --repos "api=$api,web=$web" --spec "$f" "$r" 2>&1)"; RC=$?
  expect_absent "$marker" 'colon filename cannot execute arithmetic syntax'
  expect_rc 1 'colon filename retains contract-field finding'
  expect_output 'CONTRACT-FIELDS' 'contract-field check still runs'
  rm -f "$marker"
  OUT="$(PATH="$bin:$PATH" SPEC_TOUCH_LOG="$marker" "$CHECK" --field-window 'x[$(touch${IFS}arithmetic-sentinel)]' --repos "api=$api,web=$web" --spec "$f" "$r" 2>&1)"; RC=$?
  expect_rc 2 'invalid field window rejected'
  expect_absent "$marker" 'field-window argument cannot execute arithmetic syntax'
}

newline_spec() {
  local r="$T/newline/repo" f
  new_repo "$r"
  f="$r/.claude/specs/bad"$'\n'"name/spec.md"
  mkdir -p "$(dirname "$f")"
  printf '# Newline\n**Status:** DONE\n- [ ] AC-1 Device check: visible\n' > "$f"
  OUT="$("$CHECK" --strict "$r" 2>&1)"; RC=$?
  expect_rc 2 'checker rejects unsupported newline spec path'
  expect_output 'unsupported spec path' 'checker names unsupported path'
  OUT="$("$MATRIX" "$r" 2>&1)"; RC=$?
  expect_rc 2 'matrix rejects unsupported newline spec path'
  expect_output 'unsupported spec path' 'matrix names unsupported path'
}

sentinel_filename() {
  local r="$T/sentinel/root" other="$T/sentinel/other" f sha
  new_repo "$r"; new_repo "$other"
  printf base > "$r/README.md"
  commit_at "$r" '2026-01-01T12:00:00+00:00' base
  sha="$(git -C "$r" rev-parse --short HEAD)"
  printf base > "$other/README.md"
  commit_at "$other" '2025-12-31T12:00:00+00:00' base
  printf marker > "$other/SPEC_COMMIT:0"
  printf changed > "$other/SomeTarget.js"
  commit_at "$other" '2026-01-02T12:00:00+00:00' changed
  mkdir -p "$r/.claude/specs/sentinel"
  f="$r/.claude/specs/sentinel/spec.md"
  cat > "$f" <<EOF
# Sentinel
**Status:** SPEC
**Verified at:** $sha
**Covers:** other:S*
EOF
  OUT="$("$CHECK" --strict --repos "other=$other" --spec "$f" "$r" 2>&1)"; RC=$?
  expect_output 'XREPO' 'filename cannot hide cross-repo drift'
  expect_output 'SomeTarget.js' 'covered target remains attributed'
  expect_rc 1 'cross-repo drift remains strict finding'
}

binary_grep() {
  local r="$T/binary/repo" f
  new_repo "$r"
  printf "app.post('/api/orders')\000payload\n" > "$r/a.bin"
  printf "app.post('/api/orders', handler)\n" > "$r/z.js"
  git -C "$r" add -f a.bin
  commit_at "$r" '2026-01-01T12:00:00+00:00' routes
  mkdir -p "$r/.claude/specs/binary"
  f="$r/.claude/specs/binary/spec.md"
  cat > "$f" <<'EOF'
# Binary
**Status:** READY TO BUILD
## Contract
| Endpoint |
|---|
| `POST /api/orders` |
## Refine
Critic: Alice
EOF
  OUT="$("$CHECK" --strict --spec "$f" "$r" 2>&1)"; RC=$?
  expect_rc 0 'binary match does not break later text route'
  if printf '%s\n' "$OUT" | grep -qF 'CONTRACT-MISSING'; then FAIL=$((FAIL + 1)); echo "FAIL text route hidden by binary: $OUT"; else PASS=$((PASS + 1)); fi
  if printf '%s\n' "$OUT" | grep -qF 'unsupported source path'; then FAIL=$((FAIL + 1)); echo "FAIL binary polluted framing: $OUT"; else PASS=$((PASS + 1)); fi
}

numeric_flags() {
  local r="$T/numeric/repo" f bin="$T/numeric/bin" marker="$T/numeric/sentinel" name flag
  new_repo "$r"
  mkdir -p "$r/src" "$bin"
  cat > "$bin/touch" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$SPEC_TOUCH_LOG"
EOF
  chmod +x "$bin/touch"
  for name in a b c; do printf base > "$r/src/$name.js"; done
  commit_at "$r" '2026-01-01T12:00:00+00:00' base
  f="$r/.claude/specs/numeric/spec.md"
  mkdir -p "$(dirname "$f")"
  cat > "$f" <<'EOF'
# Numeric
**Status:** READY TO BUILD
**Date:** 2026-01-01
**Covers:** src/a.js, src/b.js, src/c.js
## Refine
Critic: Alice
EOF
  for name in a b c; do printf changed > "$r/src/$name.js"; done
  commit_at "$r" '2026-01-02T12:00:00+00:00' changed
  for flag in --shipped-pct --repeat-fix --repeat-days --ref-cap; do
    rm -f "$marker"
    OUT="$(PATH="$bin:$PATH" SPEC_TOUCH_LOG="$marker" "$CHECK" "$flag" 'FIELD_WINDOW[$(touch${IFS}sentinel)]' --spec "$f" "$r" 2>&1)"; RC=$?
    expect_rc 2 "$flag rejects arithmetic input"
    expect_absent "$marker" "$flag cannot execute arithmetic input"
  done
}

temp_failure() {
  local fixture case_name cmd rc log="$T/temp-attempts" guard="$T/stop-before-redirection" shim="$T/fail-bin"
  mkdir -p "$shim"
  printf '#!/bin/sh\nexit 73\n' > "$shim/mktemp"
  for cmd in rm mkdir; do
    cat > "$shim/$cmd" <<'EOF'
#!/bin/sh
printf '%s %s\n' "${0##*/}" "$*" >> "$SPEC_FAIL_LOG"
kill -KILL "$PPID"
EOF
    chmod +x "$shim/$cmd"
  done
  chmod +x "$shim/mktemp"
  : > "$log"
  SPEC_FAIL_LOG="$log" PATH="$shim:$PATH" bash -c 'rm -rf ignored; printf unsafe > "$1"' _ "$guard" > "$T/guard-out" 2>&1
  rc=$?
  if [ "$rc" -ne 137 ] || [ -e "$guard" ]; then
    FAIL=$((FAIL + 1)); echo 'FAIL interception did not stop before shell redirection'; return
  fi
  PASS=$((PASS + 1))
  for fixture in installer checker path; do
    : > "$log"
    case "$fixture" in
      installer) cmd="$HERE/test-spec-hardening-installer.sh"; case_name=failed-move ;;
      checker) cmd="$HERE/test-spec-hardening-checker.sh"; case_name=missing-source ;;
      path) cmd="$HERE/test-spec-path-safety.sh"; case_name=option-checker ;;
    esac
    SPEC_FAIL_LOG="$log" PATH="$shim:$PATH" bash "$cmd" "$case_name" > "$T/$fixture-out" 2>&1
    rc=$?
    OUT="$(cat "$T/$fixture-out")"
    RC=$rc
    expect_rc 2 "$fixture aborts on mktemp failure"
    if [ ! -s "$log" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $fixture attempted $(cat "$log")"; fi
  done
}

case "$CASE" in
  all) colon_filename; newline_spec; sentinel_filename; binary_grep; numeric_flags; temp_failure ;;
  colon) colon_filename ;;
  newline) newline_spec ;;
  sentinel) sentinel_filename ;;
  binary) binary_grep ;;
  numeric) numeric_flags ;;
  temp-failure) temp_failure ;;
  *) echo "unknown case: $CASE" >&2; exit 2 ;;
esac
echo "test-spec-review-security $CASE: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
