#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
MATRIX="$HERE/e2e-matrix.sh"
HOOK="$HERE/pre-commit-spec-check.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
T="$(mktemp -d "$TMP_BASE/spec-path-safety.XXXXXX")" || exit 2
case "$T" in "$TMP_BASE"/spec-path-safety.*) [ -d "$T" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$T"' EXIT
CASE="${1:-all}"
PASS=0
FAIL=0
OUT=""
RC=0

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
  git -C "$1" config commit.gpgsign false
}

run_checker() { OUT="$("$CHECK" --strict "$1" 2>&1)"; RC=$?; }
run_matrix() { OUT="$("$MATRIX" "$1" 2>&1)"; RC=$?; }

expect_rc() {
  if [ "$RC" = "$1" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 exit $RC: $OUT"; fi
}

expect_output() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 output: $OUT"; fi
}

expect_file() {
  if [ -f "$1" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL missing $2"; fi
}

option_path() {
  local r="$T/option-$1"
  new_repo "$r"
  mkdir -p "$r/-delete"
  printf original > "$r/-delete/keep"
  git -C "$r" add -A
  git -C "$r" commit -qm base
  printf 'preset: personal\nspecs.path: -delete/{slug}/spec.md\n' > "$r/.spec"
  if [ "$1" = checker ]; then run_checker "$r"; else run_matrix "$r"; fi
  expect_rc 2 "$1 rejects leading find primary"
  expect_output 'invalid specs.path' "$1 names invalid config"
  expect_file "$r/-delete/keep" "$1 preserves tracked file"
}

root_escape() {
  local r="$T/escape-$1/repo" outside="$T/escape-$1/outside"
  new_repo "$r"
  mkdir -p "$outside/item"
  printf '# Outside\n**Status:** SPEC\n- [ ] AC-1 Device check: outside data\n' > "$outside/item/spec.md"
  printf 'preset: personal\nspecs.path: ../outside/{slug}/spec.md\n' > "$r/.spec"
  if [ "$1" = checker ]; then run_checker "$r"; else run_matrix "$r"; fi
  expect_rc 2 "$1 rejects traversal"
  expect_output 'invalid specs.path' "$1 names traversal"
  expect_file "$outside/item/spec.md" "$1 leaves outside file"
}

symlink_escape() {
  local r="$T/symlink-$1/repo" outside="$T/symlink-$1/outside"
  new_repo "$r"
  mkdir -p "$outside/item"
  printf '# Outside\n**Status:** SPEC\n- [ ] AC-1 Device check: outside data\n' > "$outside/item/spec.md"
  ln -s ../outside "$r/link"
  printf 'preset: personal\nspecs.path: link/{slug}/spec.md\n' > "$r/.spec"
  if [ "$1" = checker ]; then run_checker "$r"; else run_matrix "$r"; fi
  expect_rc 2 "$1 rejects symlink escape"
  expect_output 'invalid specs.path' "$1 names symlink escape"
  expect_file "$outside/item/spec.md" "$1 leaves symlink target"
}

symlink_inside() {
  local r="$T/inside/repo" f
  new_repo "$r"
  f="$r/docs/specs/item/spec.md"
  mkdir -p "$(dirname "$f")"
  printf '# Inside\n**Status:** SPEC\n- [ ] AC-1 Device check: inside alias\n' > "$f"
  ln -s docs/specs "$r/alias"
  printf 'preset: personal\nspecs.path: alias/{slug}/spec.md\n' > "$r/.spec"
  run_checker "$r"; expect_rc 0 'checker accepts internal symlink'; expect_output '1 specs' 'checker resolves internal alias'
  run_matrix "$r"; expect_rc 0 'matrix accepts internal symlink'; expect_output 'inside alias' 'matrix resolves internal alias'
}

symlink_root() {
  local r="$T/root-link-$1/repo"
  new_repo "$r"
  ln -s . "$r/alias"
  printf 'preset: personal\nspecs.path: alias/{slug}/spec.md\n' > "$r/.spec"
  if [ "$1" = checker ]; then run_checker "$r"; else run_matrix "$r"; fi
  expect_rc 2 "$1 rejects root alias"
  expect_output 'invalid specs.path' "$1 names root alias"
}

custom_space() {
  local r="$T/space/repo" f
  new_repo "$r"
  f="$r/docs/my specs/item/spec.md"
  mkdir -p "$(dirname "$f")"
  printf '# Space\n**Status:** SPEC\n- [ ] AC-1 Device check: spaced folder\n' > "$f"
  printf 'preset: personal\nspecs.path: docs/my specs/{slug}/spec.md\n' > "$r/.spec"
  run_checker "$r"; expect_rc 0 'checker scans spaced directory'; expect_output '1 specs' 'checker finds spaced spec'
  run_matrix "$r"; expect_rc 0 'matrix scans spaced directory'; expect_output 'spaced folder' 'matrix finds spaced spec'
}

explicit_spec() {
  local r="$T/explicit/repo" f
  new_repo "$r"
  f="$r/docs/direct/spec.md"
  mkdir -p "$(dirname "$f")"
  printf '# Direct\n**Status:** SPEC\n- [ ] AC-1 Device check: direct selection\n' > "$f"
  printf 'preset: personal\nspecs.path: -delete/{slug}/spec.md\n' > "$r/.spec"
  OUT="$("$CHECK" --strict --spec "$f" "$r" 2>&1)"; RC=$?
  expect_rc 0 'explicit checker spec bypasses configured scan'; expect_output '1 specs' 'checker direct selection'
  OUT="$("$MATRIX" --spec "$f" "$r" 2>&1)"; RC=$?
  expect_rc 0 'explicit matrix spec bypasses configured scan'; expect_output 'direct selection' 'matrix direct selection'
}

hook_config() {
  local r="$T/hook/repo"
  new_repo "$r"
  mkdir -p "$r/.claude/specs/item" "$r/-delete"
  printf '# Hook\n**Status:** SPEC\n' > "$r/.claude/specs/item/spec.md"
  printf 'preset: personal\nspecs.path: -delete/{slug}/spec.md\n' > "$r/.spec"
  git -C "$r" add .spec .claude/specs/item/spec.md
  OUT="$(cd "$r" && SPEC_STRICT=1 "$HOOK" 2>&1)"; RC=$?
  expect_rc 2 'strict hook propagates invalid config'; expect_output 'invalid specs.path' 'strict hook diagnostic'
  OUT="$(cd "$r" && "$HOOK" 2>&1)"; RC=$?
  expect_rc 0 'advisory hook remains nonblocking'; expect_output 'invalid specs.path' 'advisory hook diagnostic'
}

case "$CASE" in
  all) option_path checker; option_path matrix; root_escape checker; root_escape matrix; symlink_escape checker; symlink_escape matrix; symlink_inside; symlink_root checker; symlink_root matrix; custom_space; explicit_spec; hook_config ;;
  option-checker) option_path checker ;;
  option-matrix) option_path matrix ;;
  traversal-checker) root_escape checker ;;
  traversal-matrix) root_escape matrix ;;
  symlink-checker) symlink_escape checker ;;
  symlink-matrix) symlink_escape matrix ;;
  symlink-inside) symlink_inside ;;
  symlink-root-checker) symlink_root checker ;;
  symlink-root-matrix) symlink_root matrix ;;
  spaces) custom_space ;;
  explicit) explicit_spec ;;
  hook) hook_config ;;
  *) echo "unknown case: $CASE" >&2; exit 2 ;;
esac
echo "test-spec-path-safety $CASE: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
