#!/usr/bin/env bash
# Usage: test-spec-check.sh — builds throwaway git repos and asserts each spec-check finding fires and stays quiet.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
T="$(mktemp -d "${TMPDIR:-/tmp}/spec-check-test.XXXXXX")"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

commit_at() {
  local repo="$1" date="$2" msg="$3"
  git -C "$repo" add -A
  GIT_AUTHOR_DATE="$date 12:00:00" GIT_COMMITTER_DATE="$date 12:00:00" git -C "$repo" commit -qm "$msg"
}

new_repo() {
  mkdir -p "$1"
  git -C "$1" init -q
  git -C "$1" symbolic-ref HEAD refs/heads/main
  git -C "$1" config user.email test@example.com
  git -C "$1" config user.name test
  git -C "$1" config commit.gpgsign false
}

lines() { local i; for i in $(seq 1 "$1"); do echo "line $i"; done; }

has() {
  if printf '%s\n' "$OUT" | grep -q -- "^$1 $2"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL expected: $1 $2"; fi
}
hasnt() {
  if printf '%s\n' "$OUT" | grep -q -- "^$1 $2"; then FAIL=$((FAIL + 1)); echo "FAIL unexpected: $1 $2"; else PASS=$((PASS + 1)); fi
}

A="$T/app"; O="$T/other"
new_repo "$A"; new_repo "$O"

mkdir -p "$A/src" "$O/lib"
lines 10 > "$A/src/a.ts"; lines 10 > "$A/src/b.ts"; lines 10 > "$A/src/c.ts"
lines 10 > "$A/src/gone.ts"; lines 10 > "$A/src/steady.ts"
lines 5 > "$O/lib/x.ts"; lines 5 > "$O/lib/y.ts"
lines 5 > "$A/src/rep.ts"; lines 5 > "$A/src/few.ts"
commit_at "$A" 2026-01-01 base
commit_at "$O" 2025-12-31 base
SHA0="$(git -C "$A" rev-parse --short HEAD)"

S="$A/.claude/specs"
spec() { mkdir -p "$S/$1"; cat > "$S/$1/spec.md"; }

spec drift-yes <<EOF
# Drift yes
**Status:** DONE
**Verified at:** $SHA0
**Covers:** src/a.ts
EOF
spec drift-no <<EOF
# Drift no
**Status:** DONE
**Verified at:** $SHA0
**Covers:** src/steady.ts

## Refine
Round 1/1, 2026-01-02. Critic: agon nero (low risk).
EOF
spec xrepo-yes <<EOF
# Xrepo yes
**Status:** DONE
**Verified at:** $SHA0
**Covers:** other:lib/x.ts
EOF
spec xrepo-no <<EOF
# Xrepo no
**Status:** DONE
**Verified at:** $SHA0
**Covers:** other:lib/y.ts
EOF
spec cite-dead <<'EOF'
# Cite dead
**Status:** SPEC
**Date:** 2026-01-10

- Gone file `src/gone.ts:3` VERIFIED
- Past EOF `src/b.ts:40` VERIFIED
EOF
spec cite-moved <<'EOF'
# Cite moved
**Status:** SPEC
**Date:** 2026-01-10

| Fact | Evidence | Tag |
|---|---|---|
| c has line 5 | `c.ts:5-6` | VERIFIED |
EOF
spec cite-ok <<'EOF'
# Cite ok
**Status:** SPEC
**Date:** 2026-01-10

- Steady `src/steady.ts:2-4` VERIFIED
- Unverified `src/gone.ts:3` ASSUMED
EOF
spec status-open <<'EOF'
# Done but open
**Status:** DONE
**Date:** 2026-01-10

## Acceptance Criteria
- [x] AC-1 first
- [ ] AC-2 second

## Notes
- [ ] not an AC
EOF
spec status-closed <<'EOF'
# Done and closed
**Status:** DONE
**Date:** 2026-01-10

## Acceptance Criteria
- [x] AC-1 first

## Notes
- [ ] not an AC
EOF
spec shipped-yes <<'EOF'
# Shipped yes
**Status:** IN PROGRESS
**Date:** 2026-01-10

## Blast Radius
| File | Action |
|---|---|
| `src/a.ts` | edit |
| `src/c.ts`, `b.ts` | edit |
| other `lib/x.ts` | edit |
| `src/never-created.ts` | new |
EOF
spec shipped-no <<'EOF'
# Shipped no
**Status:** READY TO BUILD
**Date:** 2026-01-10

## Blast Radius
| File | Action |
|---|---|
| `src/a.ts` | edit |
| `src/steady.ts` | edit |
| `src/gone.ts` | edit |
| other `lib/y.ts` | edit |
EOF
spec pointer-broken <<'EOF'
# Pointer
Spec lives in other: `other/.claude/specs/missing/spec.md`
EOF
spec pointer-ok <<'EOF'
# Pointer
Spec lives in other: other/.claude/specs/present/spec.md (do not copy)
EOF
spec status-heading <<'EOF'
# Heading status
## Status: DONE — merged

## Acceptance Criteria
- [ ] AC-1 open
EOF
spec no-status <<'EOF'
# No status
**Date:** 2026-01-10
EOF
spec changes-block <<EOF
# Changes block
**Status:** DONE — merged
**Verified at:** $SHA0
**Covers:** src/steady.ts

## Changes
ADDED: \`src/new-thing.ts\` — helper
MODIFIED: \`src/a.ts\` — the fix
- MODIFIED: \`other:lib/x.ts\` — contract
REMOVED: \`src/never.ts\` — dead code
EOF
spec stale-fallback <<'EOF'
# Stale fallback
**Status:** DONE
**Date:** 2026-01-02

## Changes
MODIFIED: `src/a.ts` — edit
EOF
spec repeat-yes <<'EOF'
# Repeat yes
**Status:** IN PROGRESS
**Date:** 2026-01-10

## Changes
MODIFIED: `src/rep.ts` — edit
EOF
spec repeat-no <<'EOF'
# Repeat no
**Status:** IN PROGRESS
**Date:** 2026-01-10

## Changes
MODIFIED: `src/few.ts` — edit
EOF
spec status-note <<'EOF'
# Status note
**Status:** implemented — locally verified

## Acceptance Criteria
- [x] AC-1 first
- [ ] AC-2 moved to Out of Scope
EOF
spec status-free <<'EOF'
# Status free text
**Status:** source fixes complete; security review pending

## Acceptance Criteria
- [ ] AC-1 first
EOF
spec status-synonym <<'EOF'
# Status synonym
**Status:** Implemented - local gate passed

## Acceptance Criteria
- [ ] AC-1 first
EOF
mkdir -p "$O/.claude/specs/present"; echo "# Present" > "$O/.claude/specs/present/spec.md"
commit_at "$A" 2026-01-05 specs
n=0
for msg in "fix: one" "fix(ui): two" 'Revert "feat: x"' "hotfix three"; do
  n=$((n + 1)); echo "$msg" >> "$A/src/rep.ts"; commit_at "$A" "2026-01-1$n" "$msg"
done
n=0
for msg in "fix: a" "fix: b" "fix: c" "refactor: prefix cleanup"; do
  n=$((n + 1)); echo "$msg" >> "$A/src/few.ts"; commit_at "$A" "2026-01-1$n" "$msg"
done

{ echo inserted; echo inserted; cat "$A/src/c.ts"; } > "$T/c" && mv "$T/c" "$A/src/c.ts"
echo more >> "$A/src/a.ts"
lines 3 > "$A/src/b.ts"
git -C "$A" rm -q src/gone.ts
commit_at "$A" 2026-02-01 change
echo more >> "$O/lib/x.ts"
commit_at "$O" 2026-02-01 change
echo late >> "$A/src/few.ts"; commit_at "$A" 2026-03-01 "fix: late"

for i in 1 2 3; do lines 4 > "$A/src/sd$i.ts"; lines 4 > "$A/src/sy$i.ts"; done
commit_at "$A" 2026-03-05 "feat: same-day work"
for k in sameday-no sameday-yes; do
  p=sd; [ "$k" = sameday-yes ] && p=sy
  spec "$k" <<EOF
# $k
**Status:** IN PROGRESS
**Date:** 2026-03-05

## Blast Radius
| File | Action |
|---|---|
| \`src/${p}1.ts\` | edit |
| \`src/${p}2.ts\` | edit |
| \`src/${p}3.ts\` | edit |
EOF
done
commit_at "$A" 2026-03-05 "docs: specs"
for i in 1 2 3; do echo more >> "$A/src/sy$i.ts"; done
commit_at "$A" 2026-03-05 "feat: build after spec"

recreated() { spec recreated <<EOF
# Recreated
**Status:** IN PROGRESS
**Date:** 2026-03-07
**Covers:** src/rc1.ts, src/rc2.ts, src/rc3.ts
EOF
}
for i in 1 2 3; do lines 4 > "$A/src/rc$i.ts"; done
recreated; commit_at "$A" 2026-03-06 "docs: first spec"
git -C "$A" rm -rq .claude/specs/recreated; commit_at "$A" 2026-03-07 "docs: drop spec"
for i in 1 2 3; do echo again >> "$A/src/rc$i.ts"; done; commit_at "$A" 2026-03-07 "feat: work before new spec"
recreated; commit_at "$A" 2026-03-07 "docs: new spec"

OUT="$("$CHECK" --repos other=../other "$A" 2>&1)"; RC=$?
has STALE ".claude/specs/drift-yes/spec.md: 1 files: src/a.ts"
hasnt STALE ".claude/specs/drift-no/"
has XREPO ".claude/specs/xrepo-yes/spec.md: 1 files: other:lib/x.ts"
hasnt XREPO ".claude/specs/xrepo-no/"
has DEAD-CITE ".claude/specs/cite-dead/spec.md: \`src/gone.ts\` existed at"
has DEAD-CITE ".claude/specs/cite-dead/spec.md: \`src/b.ts:40\` line 40 beyond EOF (3 lines)"
has STALE-CITE ".claude/specs/cite-moved/spec.md: 0 changed + 1 moved"
hasnt "[A-Z-]*" ".claude/specs/cite-ok/"
has STATUS-OPEN ".claude/specs/status-open/spec.md: Status 'DONE' but 1 unchecked"
hasnt STATUS-OPEN ".claude/specs/status-closed/"
has STATUS-SHIPPED ".claude/specs/shipped-yes/spec.md: 4/4 covered paths"
hasnt STATUS-SHIPPED ".claude/specs/shipped-no/"
hasnt STATUS-SHIPPED ".claude/specs/sameday-no/"
has STATUS-SHIPPED ".claude/specs/sameday-yes/spec.md: 3/3 covered paths"
hasnt STATUS-SHIPPED ".claude/specs/recreated/"
has POINTER ".claude/specs/pointer-broken/spec.md: target \`other/.claude/specs/missing/spec.md\`"
hasnt POINTER ".claude/specs/pointer-ok/"
has NO-STATUS ".claude/specs/no-status/"
has STATUS-OPEN ".claude/specs/status-heading/"
hasnt NO-STATUS ".claude/specs/status-heading/"
hasnt NO-STATUS ".claude/specs/pointer-"
hasnt NO-STATUS ".claude/specs/drift-"
has STALE ".claude/specs/changes-block/spec.md: 1 files: src/a.ts"
has XREPO ".claude/specs/changes-block/spec.md: 1 files: other:lib/x.ts"
hasnt STATUS-ENUM ".claude/specs/changes-block/"
hasnt STALE ".claude/specs/stale-fallback/"
has REPEAT-FIX ".claude/specs/repeat-yes/spec.md: 4 fix/revert commits"
hasnt REPEAT-FIX ".claude/specs/repeat-no/"
hasnt STATUS-OPEN ".claude/specs/status-note/"
hasnt STATUS-ENUM ".claude/specs/status-note/"
has STATUS-ENUM ".claude/specs/status-free/"
hasnt STATUS-OPEN ".claude/specs/status-free/"
has STATUS-OPEN ".claude/specs/status-synonym/"
hasnt STATUS-ENUM ".claude/specs/status-synonym/"
hasnt STATUS-ENUM ".claude/specs/drift-"
[ "$RC" = 0 ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL advisory run exited $RC"; }

"$CHECK" --strict --repos other=../other "$A" >/dev/null 2>&1
[ $? = 1 ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL --strict should exit 1"; }

OUT="$("$CHECK" --spec "$S/drift-no/spec.md" 2>&1)"
printf '%s\n' "$OUT" | grep -q '^spec-check: 1 specs, 0 findings' && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL --spec single: $OUT"; }

OUT="$("$CHECK" --stale --repos other=../other "$A" 2>&1)"
has STALE ".claude/specs/stale-fallback/spec.md: 1 files: src/a.ts"

printf 'src/rep.ts\n' > "$T/touch"
OUT="$("$CHECK" --touching "$T/touch" "$A" 2>&1)"
has REPEAT-FIX ".claude/specs/repeat-yes/"
printf '%s\n' "$OUT" | grep -q '^spec-check: 1 specs' && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL --touching count: $OUT"; }
printf 'README.none\n' > "$T/touch"
OUT="$("$CHECK" --touching "$T/touch" "$A" 2>&1)"
[ -z "$OUT" ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL --touching none should be silent: $OUT"; }

printf 'preset: personal\nrepos: other=../other  # sibling\n' > "$A/.spec"
OUT="$("$CHECK" "$A" 2>&1)"
has XREPO ".claude/specs/xrepo-yes/"
has STALE ".claude/specs/stale-fallback/"
printf 'preset: personal\naddons: -drift-guard\n' > "$A/.spec"
OUT="$("$CHECK" "$A" 2>&1)"
hasnt STALE ".claude/specs/stale-fallback/"

rm -f "$A/.spec"
echo more >> "$A/src/steady.ts"; git -C "$A" add src/steady.ts
OUT="$(cd "$A" && "$HERE/pre-commit-spec-check.sh" 2>&1)"; RC=$?
has STALE ".claude/specs/drift-no/"
hasnt STALE ".claude/specs/changes-block/"
hasnt REPEAT-FIX ".claude/specs/repeat-yes/"
[ "$RC" = 0 ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL hook advisory exited $RC"; }
(cd "$A" && SPEC_STRICT=1 "$HERE/pre-commit-spec-check.sh" >/dev/null 2>&1)
[ $? = 1 ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL hook SPEC_STRICT=1 should exit 1"; }
git -C "$A" reset -q; git -C "$A" checkout -q -- src/steady.ts
mkdir -p "$A/docs/specs/solo"; printf '# Solo\n**Date:** 2026-01-10\n' > "$A/docs/specs/solo/spec.md"
printf 'preset: personal\nspecs.path: docs/specs/{slug}/spec.md\n' > "$A/.spec"
OUT="$("$CHECK" "$A" 2>&1)"
has NO-STATUS "docs/specs/solo/"
hasnt NO-STATUS ".claude/specs/no-status/"

P="$T/api"; W="$T/web"
new_repo "$P"; new_repo "$W"
mkdir -p "$P/app" "$W/src"
cat > "$P/app/auth.py" <<'EOF'
@router.post("/change-email/verify")
def verify(): return {"access_token": a, "refresh_token": r, "expires_in": 900}
@router.post("/login")
def login(): return {"access_token": a}
@router.get("/users/{user_id}")
def user(): return {}
@router.delete("/items/{item_id}")
@router.post("/legacy")
EOF
{
  echo 'login = () => post<{ access_token: string }>("/api/auth/login");'
  lines 40
  echo 'verify = () => post<{ success: boolean; expiresIn: number }>("/api/auth/change-email/verify");'
  echo 'user = (id) => get(`/api/users/${id}`);'
  echo 'drop = (id) => del(`${SHOP_URL}/items/${id}`);'
  echo '// /api/auth/legacy was removed'
} > "$W/src/api.ts"
commit_at "$P" 2026-01-01 base
commit_at "$W" 2026-01-01 base
git -C "$W" checkout -qb feat/guest
echo 'anon = () => post("/api/auth/anonymous");' > "$W/src/guest.ts"
commit_at "$W" 2026-01-02 guest
git -C "$W" checkout -q main
echo '@router.post("/anonymous")' >> "$P/app/auth.py"
commit_at "$P" 2026-01-02 anon

S="$P/.claude/specs"
spec contract-fire <<'EOF'
# Contract fire
**Status:** READY TO BUILD
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| `POST /api/auth/change-email/verify` | `access_token`, `refresh_token` | api | web |
| `POST /api/auth/anonymous` | | api | web |
EOF
spec contract-quiet <<'EOF'
# Contract quiet
**Status:** IN PROGRESS
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| `POST /api/auth/login` | `access_token` | api | web |
| `POST /api/auth/change-email/verify` | `expires_in`, `ghost_field` | api | web |
| `GET /api/users/{user_id}` | | api | web |
| `POST /api/auth/future` | `new_field` | api | web |
EOF
spec contract-prefix <<'EOF'
# Contract prefix-built route
**Status:** DONE
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| `DELETE /api/shop/items/{item_id}` | | api | web |
EOF
spec contract-comment <<'EOF'
# Contract only in a comment
**Status:** DONE
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| `POST /api/auth/legacy` | | api | web |
EOF
spec contract-draft <<'EOF'
# Contract draft
**Status:** SPEC
## Contract
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|
| `POST /api/auth/anonymous` | | api | web |
EOF
spec contract-fallback <<'EOF'
# Contract fallback
**Status:** IN PROGRESS
## Contract (Verified)
| Field / Behavior | Type | Evidence | Tag |
|---|---|---|---|
| `POST /api/auth/change-email/verify` returns `refresh_token` | str | `app/auth.py:2` | VERIFIED |
| `POST /api/auth/anonymous` returns `TokenResponse` | new | `app/auth.py:8` | VERIFIED |
## Changes
MODIFIED: `web:src/api.ts` — adopt tokens
EOF
spec unmerged-yes <<'EOF'
# Unmerged yes
**Status:** READY TO BUILD
## Changes
ADDED: `web:src/guest.ts` — guest client
EOF
spec unmerged-no <<'EOF'
# Unmerged no
**Status:** READY TO BUILD
## Changes
ADDED: `web:src/api.ts` — merged already
ADDED: `web:src/notyet.ts` — not built
MODIFIED: `web:src/guest.ts` — not an add
EOF
spec unmerged-wip <<'EOF'
# Unmerged wip
**Status:** IN PROGRESS
## Changes
ADDED: `web:src/guest.ts` — guest client
EOF
spec unmerged-done <<'EOF'
# Unmerged done
**Status:** DONE
## Changes
ADDED: `web:src/notyet.ts` — never built
EOF
commit_at "$P" 2026-01-03 specs

OUT="$("$CHECK" --repos web=../web "$P" 2>&1)"
has CONTRACT-FIELDS ".claude/specs/contract-fire/spec.md: web ignores \`access_token\`, \`refresh_token\` of POST /api/auth/change-email/verify (src/api.ts:42"
has CONTRACT-MISSING ".claude/specs/contract-fire/spec.md: POST /api/auth/anonymous — web: missing on main, only on feat/guest"
hasnt CONTRACT-MISSING ".claude/specs/contract-fire/spec.md: POST /api/auth/change-email"
hasnt "CONTRACT-[A-Z]*" ".claude/specs/contract-quiet/"
hasnt "CONTRACT-[A-Z]*" ".claude/specs/contract-draft/"
hasnt "CONTRACT-[A-Z]*" ".claude/specs/contract-prefix/"
has CONTRACT-MISSING ".claude/specs/contract-comment/spec.md: POST /api/auth/legacy — web: missing everywhere"
hasnt CONTRACT-FIELDS ".claude/specs/contract-fallback/"
has CONTRACT-MISSING ".claude/specs/contract-fallback/spec.md: POST /api/auth/anonymous — web: missing on main, only on feat/guest"
has UNMERGED ".claude/specs/unmerged-yes/spec.md: 1 ADDED paths not on the default branch while Status is 'READY TO BUILD': web:src/guest.ts on feat/guest"
hasnt UNMERGED ".claude/specs/unmerged-no/"
hasnt UNMERGED ".claude/specs/unmerged-wip/"
has UNMERGED ".claude/specs/unmerged-done/spec.md: 1 ADDED paths not on the default branch while Status is 'DONE': web:src/notyet.ts nowhere"

git -C "$P" checkout -q -b topic
sed -i.bak 's#"/anonymous"#"/renamed"#' "$P/app/auth.py" && rm -f "$P/app/auth.py.bak"
commit_at "$P" 2026-01-04 rename
OUT="$("$CHECK" --repos web=../web "$P" 2>&1)"
has CONTRACT-MISSING ".claude/specs/contract-fire/spec.md: POST /api/auth/anonymous — api: missing on HEAD (topic)"
git -C "$P" checkout -q main

. "$HERE/test-spec-check-stacks.sh"

echo "test-spec-check: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
