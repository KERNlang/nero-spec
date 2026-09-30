#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
INSTALL="$ROOT/install.sh"
SRC="$ROOT/skill"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
T="$(mktemp -d "$TMP_BASE/spec-install-copy.XXXXXX")" || exit 2
case "$T" in "$TMP_BASE"/spec-install-copy.*) [ -d "$T" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$T"' EXIT
PASS=0
FAIL=0
OUT=""
RC=0
H="$T/home"
DEST="$H/.claude/skills/spec"
mkdir -p "$H/.claude"

install() { OUT="$(HOME="$H" "$INSTALL" "$@" 2>&1)"; RC=$?; }
install_copy() { OUT="$(HOME="$H" SPEC_INSTALL_MODE=copy "$INSTALL" 2>&1)"; RC=$?; }
ok() { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); echo "FAIL $1 (exit $RC): $OUT"; }
check() { if eval "$1"; then ok; else bad "$2"; fi; }
backups() { find "$H/.ai/backups" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' '; }

install_copy
check '[ "$RC" = 0 ] && [ -d "$DEST" ] && [ ! -L "$DEST" ]' "copy mode installs a real directory"
check '[ "$(cat "$DEST/.nero-spec-install")" = "$SRC" ]' "copy carries a marker naming its source"
check 'cmp -s "$DEST/SKILL.md" "$SRC/SKILL.md"' "copy matches the source"

[ -L "$DEST" ] || echo stale > "$DEST/core.md"
install_copy
check '[ "$RC" = 0 ] && cmp -s "$DEST/core.md" "$SRC/core.md"' "rerun refreshes a stale copy"
check '[ "$(backups)" = 0 ]' "refreshing its own copy makes no backup"

install
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) check '[ "$RC" = 0 ] && { [ -L "$DEST" ] || [ -f "$DEST/.nero-spec-install" ]; }' "link mode replaces its own copy (symlink, or copy if Windows refuses)" ;;
  *) check '[ "$RC" = 0 ] && [ -L "$DEST" ]' "link mode replaces its own copy with a symlink" ;;
esac
check '[ "$(backups)" = 0 ]' "copy to link makes no backup"

install_copy
check '[ "$RC" = 0 ] && [ -d "$DEST" ] && [ ! -L "$DEST" ]' "copy mode replaces its own symlink"

install --uninstall
check '[ "$RC" = 0 ] && [ ! -e "$DEST" ]' "uninstall removes its own copy"

mkdir -p "$DEST" && echo mine > "$DEST/SKILL.md"
install_copy
check '[ "$RC" = 0 ] && [ "$(backups)" = 1 ]' "a foreign directory is backed up, not overwritten"
check 'cmp -s "$DEST/SKILL.md" "$SRC/SKILL.md"' "copy installed after backing up a foreign directory"

rm -rf "$DEST" && mkdir -p "$DEST" && echo mine > "$DEST/SKILL.md" && echo "$SRC-elsewhere" > "$DEST/.nero-spec-install"
install --uninstall
check '[ -f "$DEST/SKILL.md" ]' "uninstall keeps a copy whose marker names another source"

OUT="$(HOME="$H" SPEC_INSTALL_MODE=bogus "$INSTALL" 2>&1)"; RC=$?
check '[ "$RC" = 2 ]' "unknown SPEC_INSTALL_MODE is rejected"

echo "test-install-copy-mode: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
