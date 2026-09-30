#!/usr/bin/env bash
# Links this repo's skill/ into every installed agent's skill dir. Idempotent.
# Backups go to ~/.ai/backups/ — never inside a skills dir, where agents would load them as a duplicate skill.
# Usage: ./install.sh [--dry-run] [--uninstall] [--target PATH ...]
# Override targets: SPEC_TARGETS="dir1 dir2" ./install.sh, or repeat --target PATH for paths with spaces.
# SPEC_INSTALL_MODE=copy copies instead of symlinking (automatic on Windows when symlinks are refused).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skill"
NAME="spec"
BACKUP_DIR="$HOME/.ai/backups"
DRY=0; UNINSTALL=0; EXPLICIT_TARGETS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --target)
      [ $# -ge 2 ] && [ -n "$2" ] || { echo "--target needs a path" >&2; exit 2; }
      EXPLICIT_TARGETS+=("$2"); shift ;;
    --target=*) EXPLICIT_TARGETS+=("${1#--target=}") ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

[ -d "$SRC" ] && [ -f "$SRC/SKILL.md" ] || { echo "missing $SRC/SKILL.md" >&2; exit 1; }

run() { if [ "$DRY" = 1 ]; then echo "  would: $*"; else "$@"; fi; }

# Git Bash/MSYS silently deep-copies on `ln -s` unless nativestrict is set; without
# Developer Mode or admin rights Windows refuses symlinks, so we fall back to a marked copy.
IS_WINDOWS=0
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) IS_WINDOWS=1; export MSYS=winsymlinks:nativestrict CYGWIN=winsymlinks:nativestrict ;; esac
MODE="${SPEC_INSTALL_MODE:-link}"
case "$MODE" in link|copy) ;; *) echo "SPEC_INSTALL_MODE must be link or copy" >&2; exit 2 ;; esac
MARKER=".nero-spec-install"
is_ours_link() { [ -L "$1" ] && [ "$(readlink "$1")" = "$SRC" ]; }
is_ours_copy() { [ -d "$1" ] && [ ! -L "$1" ] && [ -f "$1/$MARKER" ] && [ "$(cat "$1/$MARKER")" = "$SRC" ]; }
install_copy() {
  cp -R "$SRC" "$1" && printf '%s\n' "$SRC" > "$1/$MARKER"
}
to_posix() {
  case "$1" in
    [A-Za-z]:[\\/]*) if [ "$IS_WINDOWS" = 1 ] && command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s\n' "$1"; fi ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# A skills dir is a target only if its agent is installed (parent dir exists).
if [ ${#EXPLICIT_TARGETS[@]} -gt 0 ]; then
  TARGETS=("${EXPLICIT_TARGETS[@]}")
elif [ -n "${SPEC_TARGETS:-}" ]; then
  set -f
  # shellcheck disable=SC2206 # deliberate split; globbing is off via set -f
  TARGETS=($SPEC_TARGETS)
  set +f
else
  TARGETS=()
  for d in "$HOME/.ai" "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini/config"; do
    [ -d "$d" ] && TARGETS+=("$d/skills")
  done
fi
[ ${#TARGETS[@]} -gt 0 ] || { echo "no agent dirs found (~/.ai, ~/.claude, ~/.codex, ~/.gemini/config)"; exit 0; }

for i in "${!TARGETS[@]}"; do TARGETS[i]="$(to_posix "${TARGETS[i]}")"; done
for dir in "${TARGETS[@]}"; do
  case "$dir" in
    /*) ;;
    *) echo "invalid target (absolute path required): $dir" >&2; exit 2 ;;
  esac
  case "$dir" in
    /|*'*'*|*'?'*|*'['*|*/../*|*/./*|*/..|*/.) echo "invalid target: $dir" >&2; exit 2 ;;
  esac
  probe="$dir"
  while [ ! -e "$probe" ] && [ ! -L "$probe" ]; do probe="$(dirname "$probe")"; done
  [ -d "$probe" ] || { echo "invalid target parent: $probe" >&2; exit 2; }
done
if [ "$UNINSTALL" = 0 ] && { [ -e "$BACKUP_DIR" ] || [ -L "$BACKUP_DIR" ]; }; then
  [ -d "$BACKUP_DIR" ] || { echo "invalid backup directory: $BACKUP_DIR" >&2; exit 2; }
fi

for dir in "${TARGETS[@]}"; do
  bak=""
  dest="$dir/$NAME"
  if [ "$UNINSTALL" = 1 ]; then
    if is_ours_link "$dest"; then
      run rm "$dest"
      [ "$DRY" = 1 ] || echo "✓ removed $dest"
    elif is_ours_copy "$dest"; then
      run rm -rf "$dest"
      [ "$DRY" = 1 ] || echo "✓ removed $dest (copy)"
    fi
    continue
  fi
  if [ "$MODE" = link ] && is_ours_link "$dest"; then
    echo "= $dest (already linked)"; continue
  fi
  if [ "$MODE" = copy ] && is_ours_link "$dest"; then
    run rm "$dest"
  fi
  if is_ours_copy "$dest"; then
    run rm -rf "$dest"
  fi
  run mkdir -p "$dir"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    run mkdir -p "$BACKUP_DIR"
    parent_label="$(basename "$(dirname "$dir")")"
    [ "$parent_label" != / ] || parent_label=root
    template="$BACKUP_DIR/$(basename "$dir")-$parent_label-$NAME-$(date +%Y%m%d-%H%M%S)-XXXXXX"
    if [ "$DRY" = 1 ]; then
      echo "  would: reserve $template"
      echo "  would: mv $dest to reserved spec backup"
    else
      slot="$(mktemp -d "$template")" || { echo "cannot reserve backup for $dest" >&2; exit 1; }
      bak="$slot/spec"
      if ! mv "$dest" "$bak"; then echo "cannot back up $dest to $bak" >&2; exit 1; fi
      echo "  backup: $bak"
    fi
  fi
  if [ "$DRY" = 0 ] && { [ -e "$dest" ] || [ -L "$dest" ]; }; then
    echo "destination still exists after backup: $dest" >&2; exit 1
  fi
  if [ "$MODE" = link ] && run ln -s "$SRC" "$dest" 2>/dev/null && { [ "$DRY" = 1 ] || is_ours_link "$dest"; }; then
    [ "$DRY" = 1 ] || echo "✓ $dest → $SRC"
  elif [ "$MODE" = copy ] || [ "$IS_WINDOWS" = 1 ]; then
    [ "$DRY" = 1 ] || { [ ! -e "$dest" ] && [ ! -L "$dest" ]; } || rm -rf "$dest"
    if ! run install_copy "$dest"; then echo "cannot copy to $dest${bak:+; backup: $bak}" >&2; exit 1; fi
    [ "$DRY" = 1 ] || echo "✓ $dest (copy of $SRC; rerun install.sh after git pull)"
  else
    echo "cannot link $dest${bak:+; backup: $bak}" >&2; exit 1
  fi
done
