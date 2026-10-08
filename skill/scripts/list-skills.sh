#!/usr/bin/env bash
# Usage: list-skills.sh [repo-dir]
#
# Lists the repo's own agent skills for `/spec init`: one line per skill, tab-separated
#   <suggested step>	<name>	<repo-relative dir>	<description, max 160 chars>
# Searches every `skills/<name>/SKILL.md` up to 5 levels deep inside the git root (repo-dir when not in git),
# skipping node_modules and .git. Symlinks are not followed, so a symlinked skills folder is listed once, at its
# real place, and only when that place is inside the repo. Suggested step: tests, review, critic, tickets, retro, understand, design,
# build, or - (keyword match on name + description, first hit in that order). A suggestion, never a decision.
set -uo pipefail

DIR="${1:-.}"
ROOT="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)" || ROOT="$DIR"
cd "$ROOT" 2>/dev/null || { echo "list-skills: no such directory: $DIR" >&2; exit 2; }
ROOT="$(pwd -P)"

describe() {
  awk 'NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    folded && /^[ \t]+/ { l = $0; sub(/^[ \t]+/, "", l); d = d (d == "" ? "" : " ") l; next }
    folded { exit }
    /^description:/ {
      v = $0; sub(/^description:[ \t]*/, "", v)
      if (v ~ /^[>|][-+]?$/) { folded = 1; next }
      gsub(/^["'"'"']|["'"'"']$/, "", v); d = v; exit
    }
    END { gsub(/\t/, " ", d); print substr(d, 1, 160) }' "$1"
}

step_of() {
  case "$1" in
    *test*) echo tests ;;
    *review*) echo review ;;
    *critic*|*critique*|*challenge*) echo critic ;;
    *ticket*|*jira*|*story*|*issue*) echo tickets ;;
    *retro*|*upskill*|*lessons*) echo retro ;;
    *requirement*|*interview*|*domain*|*glossary*|*terminolog*) echo understand ;;
    *architect*|*design*|*adr*) echo design ;;
    dev|*-dev|dev-*|*develop*|*implement*|*engineer*) echo build ;;
  esac
}

suggest() {
  local s
  s="$(step_of "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')")"
  [ -n "$s" ] || s="$(step_of "$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')")"
  echo "${s:--}"
}

find . -maxdepth 5 \( -name node_modules -o -name .git \) -prune -o -path '*/skills/*/SKILL.md' -print 2>/dev/null |
  sort | while IFS= read -r f; do
  d="${f%/SKILL.md}"; d="${d#./}"
  name="$(basename "$d")"; desc="$(describe "$f")"
  printf '%s\t%s\t%s\t%s\n' "$(suggest "$name" "$desc")" "$name" "$d" "$desc"
done
