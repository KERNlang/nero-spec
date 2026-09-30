#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL="$HERE/../../install.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
if [ "$TMP_BASE" = / ]; then
  TMP_PREFIX=/spec-installer-hardening.
else
  TMP_PREFIX="$TMP_BASE/spec-installer-hardening."
fi
T="$(mktemp -d "${TMP_PREFIX}XXXXXX")" || exit 2
case "$T" in
  "$TMP_PREFIX"*) [ -d "$T" ] || exit 2 ;;
  *) exit 2 ;;
esac
trap 'rm -rf "$T"' EXIT
CASE="${1:-all}"
PASS=0
FAIL=0

expect() {
  if eval "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2"; fi
}

backup_slots() {
  local slot n=0
  for slot in "$T/home/.ai/backups/"*; do
    [ -d "$slot" ] || continue
    [ -e "$slot/spec" ] || [ -L "$slot/spec" ] || continue
    n=$((n + 1))
  done
  printf '%s' "$n"
}

collision() {
  local kind="$1" first="$T/a/user/skills/spec" second="$T/b/user/skills/spec" before rc
  mkdir -p "$(dirname "$first")" "$(dirname "$second")" "$T/home"
  mkdir -p "$T/bin"
  printf '#!/bin/sh\nprintf "20260929-120000\\n"\n' > "$T/bin/date"
  chmod +x "$T/bin/date"
  case "$kind" in
    files) printf first > "$first"; printf second > "$second" ;;
    dirs) mkdir -p "$first" "$second"; printf first > "$first/data"; printf second > "$second/data" ;;
    links) ln -s first-target "$first"; ln -s second-target "$second" ;;
  esac
  HOME="$T/home" PATH="$T/bin:$PATH" SPEC_TARGETS="$T/a/user/skills $T/b/user/skills" "$INSTALL" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' "$kind install exit"
  expect '[ -L "$first" ] && [ -L "$second" ]' "$kind destinations linked"
  case "$kind" in
    files)
      expect '[ "$(backup_slots)" = 2 ]' 'two reserved file backups'
      # shellcheck disable=SC2034 # read inside expect string
      before="$(find "$T/home/.ai/backups" -type f -exec cat {} \;)"
      expect '[ "$before" = firstsecond ] || [ "$before" = secondfirst ]' 'both file contents preserved' ;;
    dirs)
      expect '[ "$(backup_slots)" = 2 ]' 'two reserved directory backups'
      # shellcheck disable=SC2034 # read inside expect string
      before="$(find "$T/home/.ai/backups" -name data -type f -exec cat {} \;)"
      expect '[ "$before" = firstsecond ] || [ "$before" = secondfirst ]' 'both directory contents preserved' ;;
    links)
      expect '[ "$(backup_slots)" = 2 ]' 'two reserved symlink backups'
      # shellcheck disable=SC2034 # read inside expect string
      before="$(find "$T/home/.ai/backups" -type l -exec readlink {} \; | sort | tr '\n' ' ')"
      expect '[ "$before" = "first-target second-target " ]' 'both link targets preserved' ;;
  esac
  HOME="$T/home" PATH="$T/bin:$PATH" SPEC_TARGETS="$T/a/user/skills $T/b/user/skills" "$INSTALL" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' "$kind repeat install exit"
  expect '[ "$(backup_slots)" = 2 ]' "$kind repeat keeps backups"
  rm -rf "${T:?}/a" "${T:?}/b" "${T:?}/home"
}

space_target() {
  local dest="$T/with space/skills/spec" rc
  mkdir -p "$T/home"
  HOME="$T/home" "$INSTALL" --target "$T/with space/skills" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' 'space install exit'
  expect '[ -L "$dest" ]' 'single target with space'
  expect '[ ! -e "$T/with/spec" ] && [ ! -e "$T/space/skills/spec" ]' 'no split destinations'
}

repeated_targets() {
  local first="$T/with one/skills/spec" second="$T/with two/skills/spec" rc
  rm -rf "${T:?}/home"
  mkdir -p "$T/home"
  HOME="$T/home" "$INSTALL" --target "$(dirname "$first")" --target "$(dirname "$second")" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' 'repeated target exit'
  expect '[ -L "$first" ] && [ -L "$second" ]' 'repeated exact space targets'
}

preflight() {
  local dest="$T/preflight/skills/spec" rc
  mkdir -p "$(dirname "$dest")" "$T/home/.ai"
  printf original > "$dest"
  printf blocked > "$T/home/.ai/backups"
  HOME="$T/home" SPEC_TARGETS="$T/preflight/skills" "$INSTALL" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'invalid backup directory rejects install'
  expect '[ "$(cat "$dest")" = original ]' 'existing target survives backup failure'
  HOME="$T/home" "$INSTALL" --target relative/skills > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'relative explicit target rejected'
  expect '[ "$(cat "$dest")" = original ]' 'existing target survives invalid target'
  mkdir -p "$T/copy"
  cp "$INSTALL" "$T/copy/install.sh"
  HOME="$T/home" SPEC_TARGETS="$T/preflight/skills" bash "$T/copy/install.sh" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'missing skill source rejects install'
  expect '[ "$(cat "$dest")" = original ]' 'existing target survives missing source'
  rm "$T/home/.ai/backups"
  mkdir -p "$T/sandbox"
  HOME="$T/home" SPEC_TARGETS="$T/preflight/skills $T/with space/skills" bash -c 'cd "$1" && "$2"' _ "$T/sandbox" "$INSTALL" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'malformed space in legacy target list rejected'
  expect '[ -f "$dest" ] && [ "$(cat "$dest")" = original ]' 'all targets untouched on malformed legacy list'
  expect '[ ! -e "$T/sandbox/space/skills/spec" ]' 'no relative fragment created'
}

dry_run() {
  local dest="$T/dry/skills/spec" rc
  rm -rf "${T:?}/home"
  mkdir -p "$(dirname "$dest")" "$T/home"
  printf original > "$dest"
  HOME="$T/home" SPEC_TARGETS="$T/dry/skills" "$INSTALL" --dry-run > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' 'dry run exit'
  expect '[ "$(cat "$dest")" = original ]' 'dry run preserves destination'
  expect '[ ! -e "$T/home/.ai/backups" ]' 'dry run creates no reservation'
  expect '! grep -q "✓" "$T/out"' 'dry run reports no completed install'
}

root_parent_label() {
  local dir="$T/root-parent/skills" dest="$T/root-parent/skills/spec" rc backup dirname_bin
  rm -rf "${T:?}/home"
  mkdir -p "$dir" "$T/home" "$T/root-parent-bin"
  printf original > "$dest"
  dirname_bin="$(command -v dirname)"
  cat > "$T/root-parent-bin/dirname" <<'SH'
#!/bin/sh
if [ "$1" = "$SPEC_FAKE_ROOT_PARENT" ]; then
  printf '/\n'
else
  "$SPEC_REAL_DIRNAME" "$@"
fi
SH
  chmod +x "$T/root-parent-bin/dirname"
  HOME="$T/home" PATH="$T/root-parent-bin:$PATH" SPEC_FAKE_ROOT_PARENT="$dir" SPEC_REAL_DIRNAME="$dirname_bin" "$INSTALL" --target "$dir" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' 'root parent label install exit'
  expect '[ -L "$dest" ]' 'root parent label destination linked'
  expect '[ "$(backup_slots)" = 1 ]' 'root parent label backup reserved'
  # shellcheck disable=SC2034 # read inside expect string
  backup="$(find "$T/home/.ai/backups" -name spec -type f -exec cat {} \;)"
  expect '[ "$backup" = original ]' 'root parent label preserves original'
}

glob_target() {
  local rc
  mkdir -p "$T/sandbox" "$T/home" "$T/glob-one/skills" "$T/glob-two/skills"
  printf one > "$T/glob-one/skills/spec"
  printf two > "$T/glob-two/skills/spec"
  HOME="$T/home" SPEC_TARGETS="$T/glob*/skills" bash -c 'cd "$1" && "$2"' _ "$T/sandbox" "$INSTALL" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'glob target rejected'
  expect '[ -f "$T/glob-one/skills/spec" ] && [ "$(cat "$T/glob-one/skills/spec")" = one ]' 'glob first destination untouched'
  expect '[ -f "$T/glob-two/skills/spec" ] && [ "$(cat "$T/glob-two/skills/spec")" = two ]' 'glob second destination untouched'
}

failed_move() {
  local dest="$T/failed-move/skills/spec" rc
  rm -rf "${T:?}/home"
  mkdir -p "$(dirname "$dest")" "$T/home" "$T/fail-bin"
  printf original > "$dest"
  printf '#!/bin/sh\nexit 23\n' > "$T/fail-bin/mv"
  chmod +x "$T/fail-bin/mv"
  HOME="$T/home" PATH="$T/fail-bin:$PATH" "$INSTALL" --target "$(dirname "$dest")" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'move failure exits nonzero'
  expect '[ -f "$dest" ] && [ "$(cat "$dest")" = original ]' 'move failure preserves destination'
}

failed_link() {
  local dest="$T/failed-link/skills/spec" rc backup
  rm -rf "${T:?}/home" "$T/fail-bin"
  mkdir -p "$(dirname "$dest")" "$T/home" "$T/fail-bin"
  printf original > "$dest"
  printf '#!/bin/sh\nexit 23\n' > "$T/fail-bin/ln"
  chmod +x "$T/fail-bin/ln"
  HOME="$T/home" PATH="$T/fail-bin:$PATH" "$INSTALL" --target "$(dirname "$dest")" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" -ne 0 ]' 'link failure exits nonzero'
  expect '[ ! -e "$dest" ] && [ ! -L "$dest" ]' 'link failure leaves destination absent'
  expect '[ "$(backup_slots)" = 1 ]' 'link failure leaves unique backup'
  # shellcheck disable=SC2034 # read inside expect string
  backup="$(find "$T/home/.ai/backups" -name spec -type f -exec cat {} \;)"
  expect '[ "$backup" = original ]' 'link failure backup preserves data'
}

uninstall_with_invalid_backup_dir() {
  local dest="$T/uninstall/skills/spec" rc source
  rm -rf "${T:?}/home"
  mkdir -p "$(dirname "$dest")" "$T/home/.ai"
  source="$(cd "$HERE/.." && pwd)"
  ln -s "$source" "$dest"
  printf blocked > "$T/home/.ai/backups"
  HOME="$T/home" "$INSTALL" --uninstall --target "$(dirname "$dest")" > "$T/out" 2>&1
  rc=$?
  expect '[ "$rc" = 0 ]' 'uninstall ignores unusable backup directory'
  expect '[ ! -e "$dest" ] && [ ! -L "$dest" ]' 'uninstall removes own link'
  expect '[ "$(cat "$T/home/.ai/backups")" = blocked ]' 'uninstall leaves backup path untouched'
}

terminal_dot() {
  local path rc
  rm -rf "${T:?}/home"
  mkdir -p "$T/home" "$T/terminal/sub"
  for path in "$T/terminal/sub/." "$T/terminal/sub/.."; do
    HOME="$T/home" "$INSTALL" --dry-run --target "$path" > "$T/out" 2>&1
    # shellcheck disable=SC2034 # read inside expect string
    rc=$?
    expect '[ "$rc" = 2 ]' "terminal component rejected: $path"
    expect '[ ! -e "$T/terminal/spec" ] && [ ! -e "$T/terminal/sub/spec" ]' "terminal component leaves destinations untouched: $path"
  done
}

case "$CASE" in
  all) collision files; collision dirs; collision links; space_target; repeated_targets; preflight; dry_run; root_parent_label; glob_target; failed_move; failed_link; uninstall_with_invalid_backup_dir; terminal_dot ;;
  files|dirs|links) collision "$CASE" ;;
  space) space_target ;;
  repeated-targets) repeated_targets ;;
  preflight) preflight ;;
  dry-run) dry_run ;;
  root-parent) root_parent_label ;;
  glob) glob_target ;;
  failed-move) failed_move ;;
  failed-link) failed_link ;;
  uninstall-backup) uninstall_with_invalid_backup_dir ;;
  terminal-dot) terminal_dot ;;
  *) echo "unknown case: $CASE" >&2; exit 2 ;;
esac
echo "test-spec-hardening-installer $CASE: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
