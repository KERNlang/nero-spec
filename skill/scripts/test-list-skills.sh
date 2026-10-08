#!/usr/bin/env bash
# Usage: test-list-skills.sh — asserts list-skills finds, dedupes, describes and suggests repo skills.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST="$HERE/list-skills.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/list-skills-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

line() {
  if printf '%s\n' "$OUT" | grep -qxF -- "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL expected line: $1"; fi
}
noline() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then FAIL=$((FAIL + 1)); echo "FAIL unexpected line: $1"; else PASS=$((PASS + 1)); fi
}
count() {
  local n; n="$(printf '%s\n' "$OUT" | grep -c -- "$1")"
  if [ "$n" = "$2" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL count $1: $n (want $2)"; fi
}

A="$T/repo"; S="$A/tools/ai/skills"
mkdir -p "$A"; git -C "$A" init -q
skill() { mkdir -p "$S/$1"; cat > "$S/$1/SKILL.md"; }

skill plan-critic <<'EOF'
---
name: plan-critic
description: Adds a check when reviewing plans and stress-testing designs.
---
EOF
skill ui-dev <<'EOF'
---
description: "Senior web developer"
---
EOF
skill helper <<'EOF'
---
description: >
  Writes unit tests
  for services.
---
EOF
skill notes <<'EOF'
---
description: Keeps	notes tidy.
---
EOF
skill bare <<'EOF'
no frontmatter here
description: ignored
EOF
mkdir -p "$S/long"; printf -- '---\ndescription: %0200d\n---\n' 0 > "$S/long/SKILL.md"
mkdir -p "$A/.claude"; ln -s "$S" "$A/.claude/skills"
mkdir -p "$T/outside/skills/leak"; echo '---' > "$T/outside/skills/leak/SKILL.md"
mkdir -p "$A/.agents/skills"; ln -s "$T/outside/skills/leak" "$A/.agents/skills/leak"
mkdir -p "$A/node_modules/pkg/skills/vendored"
echo x > "$A/node_modules/pkg/skills/vendored/SKILL.md"

OUT="$(bash "$LIST" "$A" 2>&1)"
line "critic	plan-critic	tools/ai/skills/plan-critic	Adds a check when reviewing plans and stress-testing designs."
line "build	ui-dev	tools/ai/skills/ui-dev	Senior web developer"
line "tests	helper	tools/ai/skills/helper	Writes unit tests for services."
line "-	notes	tools/ai/skills/notes	Keeps notes tidy."
line "-	bare	tools/ai/skills/bare	"
line "-	long	tools/ai/skills/long	$(printf '%0160d' 0)"
count "	plan-critic	" 1
noline "leak"
noline "vendored"

mkdir -p "$T/plain/skills/solo"; printf -- '---\ndescription: Breaks a spec into Jira tickets\n---\n' > "$T/plain/skills/solo/SKILL.md"
OUT="$(bash "$LIST" "$T/plain" 2>&1)"
line "tickets	solo	skills/solo	Breaks a spec into Jira tickets"

if bash "$LIST" "$T/missing" > /dev/null 2>&1; then FAIL=$((FAIL + 1)); echo "FAIL missing dir should exit non-zero"; else PASS=$((PASS + 1)); fi

echo "test-list-skills: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
