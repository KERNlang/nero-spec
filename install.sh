#!/usr/bin/env bash
# Links this repo's skill/ into every installed agent's skill dir. Idempotent.
# Backups go to ~/.ai/backups/ — never inside a skills dir, where agents would load them as a duplicate skill.
# Usage: ./install.sh [--dry-run] [--uninstall] [--target PATH ...]
# Override targets: SPEC_TARGETS="dir1 dir2" ./install.sh, or repeat --target PATH for paths with spaces.
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
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$SRC" ]; then
      run rm "$dest"
      [ "$DRY" = 1 ] || echo "✓ removed $dest"
    fi
    continue
  fi
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$SRC" ]; then
    echo "= $dest (already linked)"; continue
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
  if ! run ln -s "$SRC" "$dest"; then
    echo "cannot link $dest${bak:+; backup: $bak}" >&2; exit 1
  fi
  [ "$DRY" = 1 ] || echo "✓ $dest → $SRC"
done
