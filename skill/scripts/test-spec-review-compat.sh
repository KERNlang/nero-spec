#!/usr/bin/env bash
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
T="$(mktemp -d "$TMP_BASE/spec-review-compat.XXXXXX")" || exit 2
case "$T" in "$TMP_BASE"/spec-review-compat.*) [ -d "$T" ] || exit 2 ;; *) exit 2 ;; esac
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

run_check() { OUT="$("$CHECK" --strict --spec "$2" "$1" 2>&1)"; RC=$?; }

expect_rc() {
  if [ "$RC" = "$1" ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 exit $RC: $OUT"; fi
}

expect_has() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL $2 output: $OUT"; fi
}

expect_lacks() {
  if printf '%s\n' "$OUT" | grep -qF -- "$1"; then FAIL=$((FAIL + 1)); echo "FAIL $2 output: $OUT"; else PASS=$((PASS + 1)); fi
}

status_space_cr() {
  local r="$T/status/repo" f
  new_repo "$r"
  f="$r/.claude/specs/status/spec.md"
  mkdir -p "$(dirname "$f")"
  printf '# Status\n**Status:** DONE  \n## Acceptance Criteria\n- [ ] AC-1 pending\n## Refine\nCritic: Alice\n' > "$f"
  run_check "$r" "$f"
  expect_rc 1 'Markdown hard-break status remains DONE'
  expect_has 'STATUS-OPEN' 'trailing spaces preserve DONE checks'
  expect_lacks 'STATUS-ENUM' 'trailing spaces are not invalid status'
  printf '# Status\r\n**Status:** DONE\r\n## Acceptance Criteria\r\n- [ ] AC-1 pending\r\n## Refine\r\nCritic: Alice\r\n' > "$f"
  run_check "$r" "$f"
  expect_rc 1 'CRLF status remains DONE'
  expect_has 'STATUS-OPEN' 'CRLF preserves DONE checks'
  expect_lacks 'STATUS-ENUM' 'CRLF is not invalid status'
}

critic_note() {
  local r="$T/critic/repo" f
  new_repo "$r"
  f="$r/.claude/specs/critic/spec.md"
  mkdir -p "$(dirname "$f")"
  printf '# Critic\n**Status:** READY TO BUILD\n## Refine\nCritic: pending — awaiting Alice\n' > "$f"
  run_check "$r" "$f"
  expect_rc 1 'annotated pending critic is strict finding'
  expect_has 'NO-REVIEW' 'annotated pending critic is not approval'
  for value in '- pending' '— pending' '[pending]'; do
    printf '# Critic\n**Status:** READY TO BUILD\n## Refine\nCritic: %s\n' "$value" > "$f"
    run_check "$r" "$f"
    expect_rc 1 "marked pending critic $value is strict finding"
    expect_has 'NO-REVIEW' "marked pending critic $value is not approval"
  done
  printf '# Critic\n**Status:** READY TO BUILD\n## Refine\n| **Critic:** | pending |\n' > "$f"
  run_check "$r" "$f"
  expect_rc 1 'table pending critic is strict finding'
  expect_has 'NO-REVIEW' 'table pending critic is not approval'
  printf '# Critic\n**Status:** READY TO BUILD\n## Refine\nCritic: Alice — assigned\n' > "$f"
  run_check "$r" "$f"
  expect_rc 0 'named critic with note remains accepted'
  expect_lacks 'NO-REVIEW' 'named critic control'
}

mixed_route() {
  local r="$T/method/repo" f
  new_repo "$r"
  printf "app.get('/api/orders', getHandler)\napp.route('/api/orders').post(postHandler)\n" > "$r/routes.js"
  commit_at "$r" '2026-01-01T12:00:00+00:00' mixed
  f="$r/.claude/specs/method/spec.md"
  mkdir -p "$(dirname "$f")"
  cat > "$f" <<'EOF'
# Method
**Status:** READY TO BUILD
## Contract
| Endpoint |
|---|
| `POST /api/orders` |
## Refine
Critic: Alice
EOF
  run_check "$r" "$f"
  expect_rc 0 'dynamic POST beside static GET stays plausible'
  expect_lacks 'CONTRACT-MISSING' 'partial method evidence does not imply absence'
  printf "app.get('/api/orders', getHandler)\n" > "$r/routes.js"
  commit_at "$r" '2026-01-02T12:00:00+00:00' main-get
  git -C "$r" checkout -qb topic
  printf "app.post('/api/orders', postHandler)\n" > "$r/routes.js"
  commit_at "$r" '2026-01-03T12:00:00+00:00' topic-post
  run_check "$r" "$f"
  expect_rc 1 'mixed refs remain missing on main'
  expect_has 'main declares GET' 'mixed refs retain mismatch cause'
  expect_lacks 'GET/' 'method list omits trailing slash'
}

case "$CASE" in
  all) status_space_cr; critic_note; mixed_route ;;
  status) status_space_cr ;;
  critic) critic_note ;;
  method) mixed_route ;;
  *) echo "unknown case: $CASE" >&2; exit 2 ;;
esac
echo "test-spec-review-compat $CASE: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
