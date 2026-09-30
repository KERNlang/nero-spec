#!/usr/bin/env bash
# Usage: test-e2e-matrix.sh — builds a throwaway repo and asserts e2e-matrix.sh rows.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M="$HERE/e2e-matrix.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/e2e-matrix-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

has() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL expected: $1"; fi
}
hasnt() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then FAIL=$((FAIL + 1)); echo "FAIL unexpected: $1"; else PASS=$((PASS + 1)); fi
}

R="$T/app"; mkdir -p "$R"; git -C "$R" init -q
S="$R/.claude/specs"
spec() { mkdir -p "$S/$1"; cat > "$S/$1/spec.md"; }

spec paywall <<'EOF'
# Paywall
**Status:** IN PROGRESS
## Acceptance Criteria
- [ ] AC-1 Price shown
- [ ] AC-2 Device check: paywall on iPhone SE, de locale — screenshot/recording attached before DONE
- [x] AC-3 Device check: trial text only | when trial exists
EOF
spec nested <<'EOF'
# Nested
**Status:** READY TO BUILD
## Acceptance Criteria
- [ ] AC-4 Offline banner
  Tricky inputs: airplane mode, flaky network
  Device check: banner appears within 2 s offline
```
- [ ] AC-9 Device check: inside a fence
```
EOF
spec archived <<'EOF'
# Old
**Status:** ARCHIVED — replaced
- [ ] AC-1 Device check: archived screen
EOF
spec superseded <<'EOF'
# Older
**Status:** SUPERSEDED by x
- [ ] AC-1 Device check: superseded screen
EOF
spec done <<'EOF'
# Done
**Status:** DONE
- [x] AC-7 Device check: done screen
EOF
spec none <<'EOF'
# No device
**Status:** SPEC
- [ ] AC-1 Unit only
EOF

OUT="$("$M" "$R" 2>&1)"
has "## Spec device checks"
has "| Spec | Status | AC | AC state | Device check | Result |"
has '| `.claude/specs/paywall/spec.md` | IN PROGRESS | AC-2 | open | paywall on iPhone SE, de locale | |'
has '| `.claude/specs/paywall/spec.md` | IN PROGRESS | AC-3 | checked | trial text only \| when trial exists | |'
has '| `.claude/specs/nested/spec.md` | READY TO BUILD | AC-4 | open | banner appears within 2 s offline | |'
has '| `.claude/specs/done/spec.md` | DONE | AC-7 | checked | done screen | |'
hasnt "AC-1 | open | Price shown"
hasnt "inside a fence"
hasnt "archived screen"
hasnt "superseded screen"
hasnt "none/spec.md"

OUT="$("$M" --all "$R" 2>&1)"
has "archived screen"
has "superseded screen"

OUT="$("$M" --spec "$S/done/spec.md" 2>&1)"
has "done screen"
hasnt "paywall"

mkdir -p "$R/docs/specs/x"
printf '# X\n**Status:** SPEC\n- [ ] AC-1 Device check: custom path\n' > "$R/docs/specs/x/spec.md"
printf 'preset: personal\nspecs.path: docs/specs/{slug}/spec.md\n' > "$R/.spec"
OUT="$("$M" "$R" 2>&1)"
has "custom path"
hasnt "paywall"

E="$T/empty"; mkdir -p "$E"; git -C "$E" init -q
OUT="$("$M" "$E" 2>&1)"
has 'No `Device check:` criteria in active specs.'

OUT="$("$M" --bogus 2>&1)"; RC=$?
if [ "$RC" = 2 ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL expected exit 2 on unknown flag, got $RC"; fi

echo "test-e2e-matrix: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
