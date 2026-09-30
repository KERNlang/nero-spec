#!/usr/bin/env bash
# Usage: e2e-matrix.sh [--all] [--spec FILE]... [repo-dir]
#
# Collects every `Device check:` acceptance criterion from the specs under specs.path (from .spec, else
# .claude/specs and .agents/specs) into a markdown section for an e2e-sweep REPORT.md or run prompt.
# Skips specs whose Status is ARCHIVED, SUPERSEDED, ABANDONED, CANCELLED or WONTFIX unless --all.
# The AC id is taken from the line itself, else from the nearest AC-n line above it.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -r "$HERE/spec-check-lib.sh" ] && . "$HERE/spec-check-lib.sh" || { echo "e2e-matrix: cannot load $HERE/spec-check-lib.sh" >&2; exit 2; }

ALL=0; DIR=""; ONES=""
while [ $# -gt 0 ]; do
  case "$1" in
    --all) ALL=1 ;;
    --spec) case "${2:-}" in *$'\n'*|*$'\r'*|*$'\t'*) echo 'e2e-matrix: unsupported spec path (newline, CR, or tab)' >&2; exit 2 ;; esac
      [ -f "${2:-}" ] || { echo "e2e-matrix: no such spec: ${2:-}" >&2; exit 2; }
      ONES="$ONES$(cd "$(dirname "$2")" && pwd -P)/$(basename "$2")
"; shift ;;
    -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
    -*) echo "e2e-matrix: unknown flag $1" >&2; exit 2 ;;
    *) DIR="$1" ;;
  esac
  shift
done
if [ -z "$DIR" ] && [ -n "$ONES" ]; then DIR="$(dirname "$(printf '%s' "$ONES" | head -1)")"; fi
[ -n "$DIR" ] || DIR="."

ROOT="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)" || ROOT="$(cd "$DIR" && pwd -P)"
cd "$ROOT" || exit 2
ROOT="$(pwd -P)"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
TMP="$(mktemp -d "$TMP_BASE/e2e-matrix.XXXXXX")" || exit 2
case "$TMP" in "$TMP_BASE"/e2e-matrix.*) [ -d "$TMP" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$TMP"' EXIT

cfg() { [ -f .spec ] && awk -v k="$1" '{ sub(/[ \t]*#.*/, "") } index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); print; exit }' .spec; }

SPEC_DIRS=""
if [ -z "$ONES" ]; then SPEC_DIRS="$(spec_scan_dirs "$(cfg specs.path)")" || exit 2; fi

list_specs() {
  if [ -n "$ONES" ]; then printf '%s' "$ONES" | while IFS= read -r f; do echo "${f#$ROOT/}"; done; return; fi
  spec_list_files "$SPEC_DIRS" | sort
}
SPEC_FILES="$(list_specs)" || exit 2

skipped() {
  local s; s="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
  case "$s" in *ARCHIVED*) return 0 ;; esac
  [ "$(status_norm "$1")" = CLOSED ]
}

rows() {
  awk -v spec="$1" -v status="$2" '
    function cell(s) { gsub(/\|/, "\\|", s); sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    /^```/ { fence = !fence; next }
    fence { next }
    {
      ac = ""
      if (match($0, /AC-[0-9]+[a-z]?/)) { ac = substr($0, RSTART, RLENGTH); if ($0 ~ /^[ \t]*[-*] \[[ xX]\]/ || $0 ~ /^[ \t]*[-*] AC-/) last = ac }
      if ($0 !~ /[Dd]evice check:/) next
      if (ac == "") ac = (last == "" ? "?" : last)
      state = "open"
      if ($0 ~ /^[ \t]*[-*] \[[xX]\]/) state = "checked"
      c = $0; sub(/.*[Dd]evice check:[ \t]*/, "", c)
      sub(/[ \t]*(—|--)[ \t]*screenshot\/recording attached before DONE\.?[ \t]*$/, "", c)
      printf "| `%s` | %s | %s | %s | %s | |\n", spec, cell(status), ac, state, cell(c)
    }' "$3"
}

OUT="$(printf '%s\n' "$SPEC_FILES" | while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  st="$(status_of "$f")"
  if [ "$ALL" = 0 ] && skipped "$st"; then continue; fi
  rows "$f" "${st:-?}" "$f"
done)"

echo "## Spec device checks"
echo
if [ -z "$OUT" ]; then echo "No \`Device check:\` criteria in active specs."; exit 0; fi
echo "| Spec | Status | AC | AC state | Device check | Result |"
echo "|---|---|---|---|---|---|"
printf '%s\n' "$OUT"
