#!/usr/bin/env bash
# Usage: test-spec-check-policy.sh — asserts spec-check enforces a company policy file and rejects unsafe ones.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/spec-check-policy-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
export SPEC_MACHINE="$T/no-machine"

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
  git -C "$1" config commit.gpgsign false
}

has() {
  if printf '%s\n' "$OUT" | grep -q -- "^$1 $2"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL expected: $1 $2"; fi
}
hasnt() {
  if printf '%s\n' "$OUT" | grep -q -- "^$1 $2"; then FAIL=$((FAIL + 1)); echo "FAIL unexpected: $1 $2"; else PASS=$((PASS + 1)); fi
}
exits() {
  local want="$1" desc="$2"; shift 2
  "$@" > "$T/out" 2>&1; local got=$?
  if [ "$got" = "$want" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL exit $got (want $want): $desc"; cat "$T/out"; fi
}

A="$T/app"
new_repo "$A"
S="$A/.claude/specs"
spec() { mkdir -p "$S/$1"; cat > "$S/$1/spec.md"; }

mkdir -p "$A/.nero-spec"
cat > "$A/.nero-spec/policy.md" <<'EOF'
---
format: nero-spec-policy/v1
# comment lines are ignored
ticket.regex: ORG-\d+
branch.pattern: ORG-{n}_{Name}
pr.title: <type>: <summary> #ORG-<n>
headers: Ticket, Confidence
sections: Release Notes
words.deny: internaltool
addons.require: refine
addons.deny: agon-oracle
agon.max: restricted
agon_engines: alpha, beta
critic: subagent
rules: docs/guidelines.md
skills: build=dev|ui-dev, review=code-review, tests=ext, retro=empty
---

## Constitution

- PR title: `<type>: <summary> #ORG-<n>`.
EOF
cat > "$A/.spec" <<'EOF'
preset: personal
policy: ./.nero-spec/policy.md
EOF
mkdir -p "$A/.agents/skills/dev" "$A/.agents/skills/code-review" "$A/.agents/skills/empty" "$T/extskill"
echo dev > "$A/.agents/skills/dev/SKILL.md"; echo review > "$A/.agents/skills/code-review/SKILL.md"
echo ext > "$T/extskill/SKILL.md"; ln -s "$T/extskill" "$A/.agents/skills/ext"

spec good <<'EOF'
# Good
**Ticket:** [ORG-12](https://issues.example.com/ORG-12)
**Confidence:** 0.9
**Status:** DONE
## Release Notes
Fixed.
EOF
spec no-header <<'EOF'
# No header
**Ticket:** ORG-13
**Status:** SPEC
EOF
spec bad-ticket <<'EOF'
# Bad ticket
**Ticket:** ORG-5276x-typo, see XYZ
**Confidence:** 0.9
**Status:** SPEC
EOF
spec bad-ticket2 <<'EOF'
# Bad ticket 2
**Ticket:** ABC-1
**Confidence:** 0.9
**Status:** SPEC
EOF
spec no-section <<'EOF'
# No section
**Ticket:** ORG-14
**Confidence:** 0.9
**Status:** IN PROGRESS
EOF
spec draft-no-section <<'EOF'
# Draft
**Ticket:** ORG-15
**Confidence:** 0.9
**Status:** SPEC
EOF
spec bad-ticket3 <<'EOF'
# Bad ticket 3
**Ticket:** ORG-12-typo
**Confidence:** 0.9
**Status:** SPEC
EOF
spec bad-ticket4 <<'EOF'
# Bad ticket 4
**Ticket:** XORG-12
**Confidence:** 0.9
**Status:** SPEC
EOF
spec bad-ticket5 <<'EOF'
# Bad ticket 5
**Ticket:** ORG-12x (https://issues.example.com/ORG-12)
**Confidence:** 0.9
**Status:** SPEC
EOF
spec fenced-section <<'EOF'
# Fenced section
**Ticket:** ORG-17
**Confidence:** 0.9
**Status:** DONE
```markdown
## Release Notes
```
EOF
spec suffixed-section <<'EOF'
# Suffixed section
**Ticket:** ORG-18
**Confidence:** 0.9
**Status:** DONE
### Release Notes (de)
Behoben.
EOF
spec pointer <<'EOF'
Moved to .claude/specs/good/spec.md — reviewed with internaltool.
EOF
spec word <<'EOF'
# Word
**Ticket:** ORG-16
**Confidence:** 0.9
**Status:** SPEC
Reviewed with InternalTool today.
EOF
git -C "$A" add -A && git -C "$A" commit -qm base

OUT="$(bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-HEADER .claude/specs/good/spec.md
hasnt POLICY-SECTION .claude/specs/good/spec.md
hasnt POLICY-TICKET .claude/specs/good/spec.md
has POLICY-HEADER ".claude/specs/no-header/spec.md: missing \*\*Confidence:\*\*"
has POLICY-TICKET .claude/specs/bad-ticket/spec.md
has POLICY-TICKET .claude/specs/bad-ticket2/spec.md
has POLICY-SECTION .claude/specs/no-section/spec.md
hasnt POLICY-SECTION .claude/specs/draft-no-section/spec.md
has POLICY-TICKET .claude/specs/bad-ticket3/spec.md
has POLICY-TICKET .claude/specs/bad-ticket4/spec.md
has POLICY-TICKET .claude/specs/bad-ticket5/spec.md
has POLICY-SECTION .claude/specs/fenced-section/spec.md
hasnt POLICY-SECTION .claude/specs/suffixed-section/spec.md
has POLICY-WORD .claude/specs/pointer/spec.md
hasnt POLICY-HEADER .claude/specs/pointer/spec.md
has POLICY-RULES ".spec: rules file 'docs/guidelines.md'"
has POLICY-SKILL ".spec: skill 'ui-dev' for step 'build'"
has POLICY-SKILL ".spec: skill 'ext' for step 'tests'"
has POLICY-SKILL ".spec: skill 'empty' for step 'retro'"
hasnt POLICY-SKILL ".spec: skill 'dev'"
hasnt POLICY-SKILL ".spec: skill 'code-review'"
has POLICY-WORD ".claude/specs/word/spec.md: line 5"
hasnt POLICY-WORD .claude/specs/good/spec.md
has POLICY-CONFLICT ".spec: agon 'full' exceeds policy agon.max 'restricted'"
has POLICY-CONFLICT ".spec: addon 'agon-oracle' is denied by the policy but on in the preset"

cat > "$A/.spec" <<'EOF'
preset: personal
policy: .nero-spec/policy.md
agon: restricted
agon_engines: alpha, gamma
addons: -refine, -agon-oracle
branch.pattern: feat/{slug}
EOF
OUT="$(bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-CONFLICT ".spec: agon 'restricted'"
has POLICY-CONFLICT ".spec: agon engine 'gamma'"
hasnt POLICY-CONFLICT ".spec: agon engine 'alpha'"
has POLICY-CONFLICT ".spec: addon 'refine' is required"
hasnt POLICY-CONFLICT ".spec: addon 'agon-oracle'"
has POLICY-CONFLICT ".spec: branch.pattern"
exits 1 "strict fails on policy findings" bash "$CHECK" --strict "$A"

mkdir -p "$A/docs" && echo rules > "$A/docs/guidelines.md"
cat > "$A/.spec" <<'EOF'
preset: personal
policy: .nero-spec/policy.md
agon: full
ticket.fallback: ORG-XXXX
addons: -agon-oracle
EOF
OUT="$(bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-RULES .spec
has POLICY-CONFLICT ".spec: agon 'full' ignores policy agon_engines"
OUT="$(bash "$CHECK" --dir-hash --spec .claude/specs/good/spec.md "$A" 2>&1)"
hasnt POLICY-CONFLICT .spec
sed 's/^format: nero-spec-policy\/v1$/format: nero-spec-policy\/v1\nticket.fallback:/' "$A/.nero-spec/policy.md" > "$A/.nero-spec/fallback.md"
sed -i.bak 's#^policy: .*#policy: .nero-spec/fallback.md#' "$A/.spec"
OUT="$(bash "$CHECK" "$A" 2>&1)"
has POLICY-CONFLICT ".spec: ticket.fallback 'ORG-XXXX' differs"
mkdir -p "$A/.config/ai-skills/ui-dev" && echo web > "$A/.config/ai-skills/ui-dev/SKILL.md"
ln -s "$A/.config/ai-skills/ui-dev" "$A/.config/ai-skills/web-link"
printf -- '---\nformat: nero-spec-policy/v1\nskills.path: .config/ai-skills\nskills: build=ui-dev|web-link|dev\n---\n' > "$A/.nero-spec/skills.md"
sed -i.bak 's#^policy: .*#policy: .nero-spec/skills.md#' "$A/.spec"
OUT="$(bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-SKILL ".spec: skill 'ui-dev'"
hasnt POLICY-SKILL ".spec: skill 'web-link'"
has POLICY-SKILL ".spec: skill 'dev' for step 'build' has no SKILL.md under .config/ai-skills"
mkdir -p "$A/apps/web/my skills/api-dev" "$A/apps/web/my skills/fake"
echo api > "$A/apps/web/my skills/api-dev/SKILL.md"; ln -s "$T/extskill/SKILL.md" "$A/apps/web/my skills/fake/SKILL.md"
printf -- '---\nformat: nero-spec-policy/v1\nskills.path: .config/ai-skills, apps/web/my skills\nskills: build=ui-dev|api-dev, tests=fake\n---\n' > "$A/.nero-spec/skills.md"
OUT="$(bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-SKILL ".spec: skill 'ui-dev'"
hasnt POLICY-SKILL ".spec: skill 'api-dev'"
has POLICY-SKILL ".spec: skill 'fake' for step 'tests' has no SKILL.md under .config/ai-skills, apps/web/my skills"
awk '{ printf "%s\r\n", $0 }' "$A/.nero-spec/policy.md" > "$A/.nero-spec/crlf.md"
sed -i.bak 's#^policy: .*#policy: .nero-spec/crlf.md#' "$A/.spec"
exits 0 "CRLF policy parses" bash "$CHECK" "$A"

cat > "$A/.spec" <<'EOF'
preset: personal
agon: off
addons: -agon-oracle
EOF
OUT="$(bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-HEADER .claude/specs/no-header/spec.md
hasnt POLICY-CONFLICT .spec

mkdir -p "$T/policies"
cp "$A/.nero-spec/policy.md" "$T/policies/org.md"
printf 'policy_paths: %s=%s\n' "$T" "$T/policies/org.md" > "$T/machine"
OUT="$(SPEC_MACHINE="$T/machine" bash "$CHECK" "$A" 2>&1)"
has POLICY-HEADER .claude/specs/no-header/spec.md
rm "$A/.spec"
OUT="$(SPEC_MACHINE="$T/machine" bash "$CHECK" "$A" 2>&1)"
has POLICY-HEADER .claude/specs/no-header/spec.md
hasnt POLICY-CONFLICT ".spec: agon"
V="$T/vendored"; mkdir -p "$V"
for s in spec-check.sh spec-check-lib.sh spec-check-contract.sh spec-check-policy.sh; do cp "$HERE/$s" "$V/"; done
OUT="$(SPEC_MACHINE="$T/machine" bash "$V/spec-check.sh" "$A" 2>&1)"
hasnt POLICY-HEADER .claude/specs/no-header/spec.md
printf 'policy_paths: %s=relative.md\n' "$T" > "$T/machine-bad"
exits 2 "machine policy must be absolute" env SPEC_MACHINE="$T/machine-bad" bash "$CHECK" "$A"
printf 'policy_paths: /nonexistent-dir=%s\n' "$T/policies/org.md" > "$T/machine-other"
OUT="$(SPEC_MACHINE="$T/machine-other" bash "$CHECK" "$A" 2>&1)"
hasnt POLICY-HEADER .claude/specs/no-header/spec.md

invalid() {
  printf 'preset: personal\nagon: off\naddons: -agon-oracle\npolicy: %s\n' "$1" > "$A/.spec"
  exits 2 "$2" bash "$CHECK" "$A"
}
invalid ../outside.md "parent path"
invalid "$A/.nero-spec/policy.md" "absolute path"
# shellcheck disable=SC2088 # the literal tilde is the input under test
invalid "~/policy.md" "home path"
invalid .nero-spec/missing.md "missing file"
invalid .nero-spec/policy.txt "not markdown"
ln -s "$T/policies/org.md" "$A/.nero-spec/link.md"
invalid .nero-spec/link.md "symlink"
mkdir -p "$T/escape" && cp "$T/policies/org.md" "$T/escape/p.md"
ln -s "$T/escape" "$A/escdir"
invalid escdir/p.md "symlinked dir escape"

bad_policy() {
  printf '%s\n' "$@" > "$A/.nero-spec/bad.md"
  printf 'preset: personal\nagon: off\naddons: -agon-oracle\npolicy: .nero-spec/bad.md\n' > "$A/.spec"
  exits 2 "bad policy: $*" bash "$CHECK" "$A"
}
bad_policy --- 'format: nero-spec-policy/v1' 'tickt.regex: X' ---
bad_policy --- 'format: nero-spec-policy/v1' 'headers: A' 'headers: B' ---
bad_policy --- 'headers: A' ---
bad_policy --- 'format: nero-spec-policy/v2' ---
bad_policy --- 'format: nero-spec-policy/v1' 'agon.max: yes' ---
bad_policy --- 'format: nero-spec-policy/v1' 'critic: human' ---
bad_policy --- 'format: nero-spec-policy/v1' 'ticket.regex: ORG-(' ---
bad_policy --- 'format: nero-spec-policy/v1' 'pr.regex: ^fix(' ---
bad_policy --- 'format: nero-spec-policy/v1' 'critic: agon' 'agon.max: off' ---
bad_policy --- 'format: nero-spec-policy/v1' 'rules: ../secrets.md' ---
bad_policy --- 'format: nero-spec-policy/v1' 'rules: /etc/passwd' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: deploy=dev' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build=../dev' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build=dev|.hidden' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills.path: ../skills' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills.path: ok, ../skills' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build=' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build=dev|' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build=|dev' ---
bad_policy --- 'format: nero-spec-policy/v1' 'skills: build=dev| |api' ---
bad_policy 'format: nero-spec-policy/v1'
bad_policy --- 'format: nero-spec-policy/v1'

echo "test-spec-check-policy: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
