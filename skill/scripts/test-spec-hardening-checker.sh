#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
MATRIX="$HERE/e2e-matrix.sh"
HOOK="$HERE/pre-commit-spec-check.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
T="$(mktemp -d "$TMP_BASE/spec-check-hardening.XXXXXX")" || exit 2
case "$T" in "$TMP_BASE"/spec-check-hardening.*) [ -d "$T" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$T"' EXIT
CASE="${1:-all}"
PASS=0
FAIL=0
OUT=""
RC=0

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" symbolic-ref HEAD refs/heads/main
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
  git -C "$1" config commit.gpgsign false
}

commit_at() {
  git -C "$1" add -A
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$1" commit -qm "$3"
}

run_check() {
  OUT="$("$CHECK" --strict --spec "$1" "${2:-$(dirname "$1")}" 2>&1)"
  RC=$?
}

has() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL expected $2: $OUT"; fi
}

hasnt() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then FAIL=$((FAIL + 1)); echo "FAIL unexpected $2: $OUT"; else PASS=$((PASS + 1)); fi
}

exit_is() {
  if [ "$RC" = "$1" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 exit $RC: $OUT"; fi
}

spec_file() {
  mkdir -p "$(dirname "$1")"
  cat > "$1"
}

missing_source() {
  local r="$T/missing/repo" v="$T/missing/vendor" f
  new_repo "$r"
  mkdir -p "$v"
  cp "$CHECK" "$HERE/spec-check-lib.sh" "$v/"
  f="$r/.claude/specs/x/spec.md"
  spec_file "$f" <<'EOF'
# Missing source
**Status:** READY TO BUILD
## Contract
| Endpoint |
|---|
| `POST /api/missing` |
## Refine
Critic: reviewer
EOF
  OUT="$("$v/spec-check.sh" --strict "$r" 2>&1)"; RC=$?
  exit_is 2 'missing contract helper'
  has 'spec-check-contract.sh' 'missing contract helper diagnostic'
  hasnt '0 findings' 'missing helper zero-findings summary'
  cp "$HOOK" "$v/"
  git -C "$r" add .claude/specs/x/spec.md
  OUT="$(cd "$r" && SPEC_STRICT=1 "$v/pre-commit-spec-check.sh" 2>&1)"; RC=$?
  exit_is 2 'strict hook with missing helper'
  has 'spec-check-contract.sh' 'strict hook diagnostic'
  OUT="$(cd "$r" && "$v/pre-commit-spec-check.sh" 2>&1)"; RC=$?
  exit_is 0 'advisory hook remains nonblocking'
  has 'spec-check-contract.sh' 'advisory hook surfaces diagnostic'
  cp "$HERE/spec-check-contract.sh" "$v/"
  rm "$v/spec-check-lib.sh"
  OUT="$("$v/spec-check.sh" --strict "$r" 2>&1)"; RC=$?
  exit_is 2 'missing shared library'
  has 'spec-check-lib.sh' 'missing shared library diagnostic'
  hasnt '0 findings' 'missing library zero-findings summary'
}

vendor_manifest() {
  local body
  body="$(sed -n '/## 2b\. Mode/,/## 2c\./p' "$HERE/../init.md")"
  OUT="$body"
  has 'spec-check-contract.sh' 'manifest contract helper'
  has '`.spec`' 'vendored machine-readable config'
  if printf '%s\n' "$OUT" | grep -qiF 'do not write a `.spec`'; then FAIL=$((FAIL + 1)); echo 'FAIL vendored recipe forbids shared config'; else PASS=$((PASS + 1)); fi
}

vendor_config() {
  local r="$T/vendor/repo" f
  new_repo "$r"
  f="$r/docs/custom/item/spec.md"
  spec_file "$f" <<'EOF'
# Custom
**Status:** DONE
## Acceptance Criteria
- [ ] AC-1 Device check: custom screen
## Refine
Critic: reviewer
EOF
  printf 'preset: personal\nspecs.path: docs/custom/{slug}/spec.md\n' > "$r/.spec"
  OUT="$("$CHECK" --strict "$r" 2>&1)"; RC=$?
  has 'STATUS-OPEN' 'configured checker path'; exit_is 1 'configured checker'
  OUT="$("$MATRIX" "$r" 2>&1)"; RC=$?
  has 'custom screen' 'configured e2e path'; exit_is 0 'configured e2e'
  git -C "$r" add .spec docs/custom/item/spec.md
  OUT="$(cd "$r" && SPEC_STRICT=1 "$HOOK" 2>&1)"; RC=$?
  has 'STATUS-OPEN' 'configured hook path'; exit_is 1 'configured hook'
}

method() {
  local r="$T/method/repo" f
  new_repo "$r"; mkdir -p "$r/src"
  printf "app.get('/api/orders', handler)\n" > "$r/src/routes.js"
  commit_at "$r" '2026-01-01T12:00:00+00:00' base
  f="$r/.claude/specs/method/spec.md"
  spec_file "$f" <<'EOF'
# Method
**Status:** READY TO BUILD
## Contract
| Endpoint |
|---|
| `POST /api/orders` |
## Refine
Critic: reviewer
EOF
  run_check "$f" "$r"; has 'CONTRACT-MISSING' 'wrong concrete method'; exit_is 1 'wrong concrete method'
  printf "app.post('/api/orders', handler)\n" > "$r/src/routes.js"
  commit_at "$r" '2026-01-02T12:00:00+00:00' matching
  run_check "$f" "$r"; hasnt 'CONTRACT-MISSING' 'matching concrete method'; exit_is 0 'matching concrete method'
  printf "const routes = {'/api/orders': handler}\n" > "$r/src/routes.js"
  commit_at "$r" '2026-01-03T12:00:00+00:00' dynamic
  run_check "$f" "$r"; hasnt 'CONTRACT-MISSING' 'path-only dynamic route'; exit_is 0 'path-only dynamic route'
}

untracked() {
  local r="$T/untracked/repo" f sha
  new_repo "$r"; mkdir -p "$r/src"
  printf base > "$r/src/base.ts"
  commit_at "$r" '2026-01-01T12:00:00+00:00' base
  sha="$(git -C "$r" rev-parse --short HEAD)"
  f="$r/.claude/specs/untracked/spec.md"
  spec_file "$f" <<EOF
# Untracked
**Status:** SPEC
**Verified at:** $sha
## Changes
ADDED: \`src/new.ts\` — new file
EOF
  printf new > "$r/src/new.ts"
  run_check "$f" "$r"; has 'STALE' 'untracked covered path'; exit_is 1 'untracked drift'
  printf 'src/ignored.ts\n' > "$r/.gitignore"
  printf ignored > "$r/src/ignored.ts"
  spec_file "$f" <<EOF
# Ignored
**Status:** SPEC
**Verified at:** $sha
## Changes
ADDED: \`src/ignored.ts\` — ignored file
EOF
  run_check "$f" "$r"; hasnt 'STALE' 'ignored untracked path'; exit_is 0 'ignored untracked control'
}

changes_paths() {
  local r="$T/paths/repo" f
  new_repo "$r"; printf base > "$r/README.md"
  commit_at "$r" '2026-01-01T12:00:00+00:00' base
  f="$r/.claude/specs/paths/spec.md"
  spec_file "$f" <<'EOF'
# Paths
**Status:** DONE
## Changes
ADDED: `Dockerfile` — root file
ADDED: `newdir/x.rare` — uncommon new directory
## Acceptance Criteria
- [x] AC-1 entries
## Refine
Critic: reviewer
EOF
  run_check "$f" "$r"; has 'UNMERGED' 'explicit added paths'; has '2 ADDED paths' 'both explicit paths'; exit_is 1 'explicit paths'
}

status() {
  local r="$T/status/repo" f s
  new_repo "$r"
  f="$r/.claude/specs/status/spec.md"
  for s in DONEISH 'READY FOR PLAN'; do
    spec_file "$f" <<EOF
# Status
**Status:** $s
## Refine
Critic: reviewer
EOF
    run_check "$f" "$r"; has 'STATUS-ENUM' "$s invalid"; exit_is 1 "$s invalid"
  done
  for s in 'DONE — release note' 'DONE - release note' 'DONE (release note)' IMPLEMENTED 'SUPERSEDED by x'; do
    spec_file "$f" <<EOF
# Status
**Status:** $s
## Refine
Critic: reviewer
EOF
    run_check "$f" "$r"; hasnt 'STATUS-ENUM' "$s valid"; exit_is 0 "$s valid"
  done
}

repeat_fix() {
  local r="$T/repeat/repo" f d
  new_repo "$r"; mkdir -p "$r/src"
  printf base > "$r/src/a.ts"
  commit_at "$r" '2026-01-01T12:00:00+00:00' base
  f="$r/.claude/specs/repeat/spec.md"
  spec_file "$f" <<'EOF'
# Repeated fixes
**Status:** SPEC
**Date:** 2026-01-01
## Changes
MODIFIED: `src/a.ts` — repeated fix
EOF
  for d in 02 03 04 05; do printf '%s\n' "$d" >> "$r/src/a.ts"; commit_at "$r" "2026-01-${d}T12:00:00+00:00" fix; done
  run_check "$f" "$r"; has 'REPEAT-FIX' 'distinct commits same subject'; exit_is 1 'repeat fix'
  local o="$T/repeat/overlap" of
  new_repo "$o"; mkdir -p "$o/src"
  printf base > "$o/src/a.ts"; printf base > "$o/src/b.ts"
  commit_at "$o" '2026-01-01T12:00:00+00:00' base
  of="$o/.claude/specs/overlap/spec.md"
  spec_file "$of" <<'EOF'
# Overlap
**Status:** SPEC
**Date:** 2026-01-01
## Changes
MODIFIED: `src/a.ts` — first path
MODIFIED: `src/b.ts` — second path
EOF
  printf changed >> "$o/src/a.ts"; printf changed >> "$o/src/b.ts"
  commit_at "$o" '2026-01-02T12:00:00+00:00' fix
  OUT="$("$CHECK" --strict --repeat-fix 2 --spec "$of" "$o" 2>&1)"; RC=$?
  hasnt 'REPEAT-FIX' 'one commit on two paths'; exit_is 0 'overlapping path control'
}

crossrepo() {
  local w="$T/cross/web" a="$T/cross/api" f sha prior_web="$T/cross/prior-web" prior_api="$T/cross/prior-api" prior_spec
  new_repo "$w"; new_repo "$a"
  printf base > "$w/README.md"; mkdir -p "$a/src"; printf base > "$a/src/route.ts"
  commit_at "$w" '2026-01-01T12:00:00+00:00' anchor
  commit_at "$a" '2026-01-01T11:59:59+00:00' api-base
  sha="$(git -C "$w" rev-parse --short HEAD)"
  f="$w/.claude/specs/cross/spec.md"
  spec_file "$f" <<EOF
# Cross repo
**Status:** SPEC
**Verified at:** $sha
## Changes
MODIFIED: \`api:src/route.ts\` — route
EOF
  printf 'repos: api=../api\n' > "$w/.spec"
  run_check "$f" "$w"; hasnt 'XREPO' 'unchanged api control'; exit_is 0 'unchanged api control'
  printf changed >> "$a/src/route.ts"
  commit_at "$a" '2026-01-01T12:00:00+00:00' same-second
  run_check "$f" "$w"; has 'XREPO' 'same-second crossrepo change'; exit_is 1 'same-second crossrepo'
  new_repo "$prior_web"; new_repo "$prior_api"
  printf base > "$prior_web/README.md"; mkdir -p "$prior_api/src"; printf base > "$prior_api/src/route.ts"
  commit_at "$prior_api" '2026-01-01T12:00:00+00:00' api-first
  commit_at "$prior_web" '2026-01-01T12:00:00+00:00' web-second
  sha="$(git -C "$prior_web" rev-parse --short HEAD)"
  prior_spec="$prior_web/.claude/specs/prior/spec.md"
  spec_file "$prior_spec" <<EOF
# Conservative second
**Status:** SPEC
**Verified at:** $sha
## Changes
MODIFIED: \`prior-api:src/route.ts\` — route
EOF
  printf 'repos: prior-api=../prior-api\n' > "$prior_web/.spec"
  run_check "$prior_spec" "$prior_web"; has 'XREPO' 'same-second prior commit is conservatively included'; exit_is 1 'same-second prior boundary'
}

critic() {
  local r="$T/critic/repo" f status critic pass
  new_repo "$r"; f="$r/.claude/specs/critic/spec.md"
  for status in 'READY TO BUILD' 'IN PROGRESS' DONE; do
    spec_file "$f" <<EOF
# Critic
**Status:** $status
## Refine
Critic: pending
Pass: no (1 HIGH open)
EOF
    run_check "$f" "$r"; has 'NO-REVIEW' "$status pending and negative"; exit_is 1 "$status pending and negative"
  done
  spec_file "$f" <<'EOF'
# Negative pass
**Status:** DONE
## Refine
Critic: reviewer
Pass: no (1 HIGH open)
EOF
  run_check "$f" "$r"; has 'NO-REVIEW' 'named critic negative pass'; exit_is 1 'named critic negative pass'
  spec_file "$f" <<'EOF'
# Pending critic
**Status:** DONE
## Refine
Critic: pending
Pass: yes
EOF
  run_check "$f" "$r"; has 'NO-REVIEW' 'pending critic positive pass'; exit_is 1 'pending critic positive pass'
  spec_file "$f" <<'EOF'
# Draft
**Status:** SPEC
## Refine
Critic: pending
Pass: no
EOF
  run_check "$f" "$r"; hasnt 'NO-REVIEW' 'draft pending allowed'; exit_is 0 'draft pending allowed'
  spec_file "$f" <<'EOF'
# Legacy
**Status:** DONE
## Refine
Critic: reviewer
EOF
  run_check "$f" "$r"; hasnt 'NO-REVIEW' 'legacy named critic'; exit_is 0 'legacy named critic'
}

case "$CASE" in
  all) missing_source; vendor_manifest; vendor_config; method; untracked; changes_paths; status; repeat_fix; crossrepo; critic ;;
  missing-source) missing_source ;;
  vendor-manifest) vendor_manifest ;;
  vendor-config) vendor_config ;;
  method) method ;;
  untracked) untracked ;;
  changes-paths) changes_paths ;;
  status) status ;;
  repeat) repeat_fix ;;
  crossrepo) crossrepo ;;
  critic) critic ;;
  *) echo "unknown case: $CASE" >&2; exit 2 ;;
esac
echo "test-spec-hardening-checker $CASE: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
