#!/usr/bin/env bash
# Usage: pre-commit-spec-check.sh — git pre-commit hook. Runs spec-check.sh on staged specs and on specs whose
# Changes / Covers / Blast Radius paths are staged. Advisory: always exits 0 unless SPEC_STRICT=1 and a finding exists.
# Chain from an existing hook with:  "<skill dir>/scripts/pre-commit-spec-check.sh" || exit $?
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
LIST="$(mktemp "${TMPDIR:-/tmp}/spec-staged.XXXXXX")"
trap 'rm -f "$LIST"' EXIT

git -C "$ROOT" diff --cached --name-only > "$LIST" 2>/dev/null
[ -s "$LIST" ] || exit 0

if [ "${SPEC_STRICT:-0}" = 1 ]; then
  "$HERE/spec-check.sh" --strict --touching "$LIST" "$ROOT" >&2
  exit $?
fi
"$HERE/spec-check.sh" --touching "$LIST" "$ROOT" >&2
exit 0
