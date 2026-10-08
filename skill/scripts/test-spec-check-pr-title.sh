#!/usr/bin/env bash
# Usage: test-spec-check-pr-title.sh — asserts spec-check --pr-title enforces the policy PR title format and ticket key.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/spec-check-pr-title-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
export SPEC_MACHINE="$T/no-machine"

title() {
  local want="$1" desc="$2" got; shift 2
  bash "$CHECK" "$@" > "$T/out" 2>&1; got=$?
  if [ "$got" = "$want" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL exit $got (want $want): $desc"; cat "$T/out"; fi
}
says() {
  if grep -qF -- "$1" "$T/out"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL output lacks: $1"; cat "$T/out"; fi
}

A="$T/app"
mkdir -p "$A/.nero-spec" "$A/.claude/specs/ORG-12-thing"
git -C "$A" init -q
printf 'preset: personal\nagon: off\npolicy: .nero-spec/policy.md\n' > "$A/.spec"
SP="$A/.claude/specs/ORG-12-thing/spec.md"
printf '# Thing\n\n**Status:** SPEC\n**Ticket:** ([was ORG-99](https://example.com/browse/ORG-99)) ORG-12\n' > "$SP"
policy() { printf -- '---\nformat: nero-spec-policy/v1\nticket.regex: ORG-\\d+\n%s---\n' "$1" > "$A/.nero-spec/policy.md"; }

policy 'pr.title: <feat|fix>(core): <Summary> #ORG-<n>
'
title 0 "valid title" --spec "$SP" --pr-title "fix(core): Add thing #ORG-12" "$A"
says "PR-TITLE ok"
title 1 "trailing typo after the key" --spec "$SP" --pr-title "fix(core): Add thing #ORG-12x" "$A"
says "does not match the policy format"
title 1 "prefix before the type" --pr-title "Xfix(core): Add thing #ORG-12" "$A"
title 1 "type outside the list" --pr-title "chore(core): Add thing #ORG-12" "$A"
title 1 "template parentheses are literal" --pr-title "fixcore: Add thing #ORG-12" "$A"
title 1 "missing summary" --pr-title "fix(core):  #ORG-12" "$A"
title 1 "key not at the end" --pr-title "fix(core): Add #ORG-12 thing" "$A"
title 0 "no spec: any key" --pr-title "fix(core): Add thing #ORG-13" "$A"
title 1 "wrong ticket for the spec" --spec "$SP" --pr-title "fix(core): Add thing #ORG-13" "$A"
says "does not name the spec's ticket ORG-12"
title 1 "longer key is not the spec's key" --spec "$SP" --pr-title "fix(core): Add thing #ORG-123" "$A"
title 1 "link target key is ignored" --spec "$SP" --pr-title "fix(core): Add thing #ORG-99" "$A"
printf "# Other\n\n**Status:** SPEC\n" > "$A/.claude/specs/ORG-12-thing/noticket.md"
title 1 "spec without a Ticket key" --spec "$A/.claude/specs/ORG-12-thing/noticket.md" --pr-title "fix(core): Add thing #ORG-12" "$A"
says "has no **Ticket:** key"
title 2 "empty title" --pr-title "" "$A"
title 2 "multi-line title" --pr-title "fix(core): Add thing #ORG-12
fix(core): Add thing #ORG-12" "$A"

policy 'pr.title: <type>: <summary> #ORG-<n>
pr.regex: ^(feat|fix): [A-Z].* #ORG-\d+$
'
title 0 "pr.regex match" --pr-title "fix: Add thing #ORG-12" "$A"
title 1 "pr.regex wins over the looser template" --pr-title "fix: add thing #ORG-12" "$A"
says "pr.regex ^(feat|fix)"

printf -- '---\nformat: nero-spec-policy/v1\npr.title: <fix>: <Summary> #ORG-<n>\n---\n' > "$A/.nero-spec/policy.md"
title 0 "no ticket.regex: no ticket tie" --spec "$SP" --pr-title "fix: Add thing #ORG-12" "$A"
policy 'pr.title: <feat|fix>(<scope>): <Summary>
'
title 0 "format without a ticket: title without a key passes" --spec "$SP" --pr-title "fix(ui): Add thing" "$A"
title 1 "a key in the title must be the spec's" --spec "$SP" --pr-title "fix(ORG-13): Add thing" "$A"
title 0 "ticket-scope style" --spec "$SP" --pr-title "fix(ORG-12): Add thing" "$A"
policy 'headers: Ticket
'
title 2 "policy without a PR format" --pr-title "fix: Add thing #ORG-12" "$A"
rm "$A/.spec"
title 2 "no policy" --pr-title "fix: Add thing #ORG-12" "$A"
says "needs a company policy"

title 2 "missing spec file" --spec "$A/nope.md" --pr-title "fix(core): Add thing #ORG-12" "$A"
says "no such spec"

echo "test-spec-check-pr-title: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
