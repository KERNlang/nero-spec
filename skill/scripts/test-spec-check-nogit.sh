#!/usr/bin/env bash
# Usage: test-spec-check-nogit.sh — non-git targets, --dir-hash, dir-hash anchors, Critics plural, OPEN-CAP, REFINE-STEPS.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/spec-check.sh"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
T="$(mktemp -d "$TMP_BASE/spec-nogit-test.XXXXXX")" || exit 2
case "$T" in "$TMP_BASE"/spec-nogit-test.*) [ -d "$T" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$T"' EXIT
GIT_CEILING_DIRECTORIES="$T"; export GIT_CEILING_DIRECTORIES
GOLDEN=f8825ffdc0b55c58c6a26cb3d244b427a6965d0a60af8f40dcfe3c6617b499a4
PASS=0; FAIL=0; OUT=""; ERR=""; RC=0; H=""

run() { OUT="$("$@" 2>"$T/stderr")"; RC=$?; ERR="$(cat "$T/stderr")"; }
ok() { PASS=$((PASS + 1)); }
bad() { FAIL=$((FAIL + 1)); echo "FAIL $1"; }
has() { if printf '%s\n' "$OUT" | grep -q -- "^$2 $3"; then ok; else bad "$1: expected $2 $3"; fi; }
hasnt() { if printf '%s\n' "$OUT" | grep -q -- "^$2 $3"; then bad "$1: unexpected $2 $3"; else ok; fi; }
rc_is() { if [ "$RC" = "$2" ]; then ok; else bad "$1: exit $RC, want $2 — $OUT $ERR"; fi; }
count_is() { local n; n="$(printf '%s\n' "$OUT" | grep -c -- "^$2 ")"; if [ "$n" = "$3" ]; then ok; else bad "$1: $n $2 lines, want $3"; fi; }
hex64() { printf '%s' "$1" | grep -qE '^[0-9a-f]{64}$'; }
same_hash() { if hex64 "$2" && [ "$2" = "$3" ]; then ok; else bad "$1: '$2' != '$3'"; fi; }
diff_hash() { if hex64 "$2" && hex64 "$3" && [ "$2" != "$3" ]; then ok; else bad "$1: '$2' vs '$3' should differ"; fi; }
mk() { mkdir -p "$(dirname "$1")"; cat > "$1"; }
dirhash() { run env HOME="$T/nohome" "$CHECK" --spec "$1" --dir-hash "$2"; H="${OUT#dir-hash }"; H="${H%% *}"; }
covers() {
  local f="$T/hs/$1.md" p; shift; mkdir -p "$T/hs"
  printf '# covers\n**Status:** SPEC\n\n## Changes\n' > "$f"
  for p in "$@"; do printf 'MODIFIED: `%s` — edit\n' "$p" >> "$f"; done
}
new_repo() {
  mkdir -p "$1"; git -C "$1" init -q; git -C "$1" symbolic-ref HEAD refs/heads/main
  git -C "$1" config user.email test@example.com; git -C "$1" config user.name test; git -C "$1" config commit.gpgsign false
}
commit() { git -C "$1" add -A; GIT_AUTHOR_DATE="2026-01-01 12:00:00" GIT_COMMITTER_DATE="2026-01-01 12:00:00" git -C "$1" commit -qm "$2"; }

N="$T/nogit"; S="$N/.claude/specs"
mkdir -p "$N/src"; for i in 1 2 3 4 5 6 7 8 9 10; do echo "line $i"; done > "$N/src/a.ts"
mk "$S/done-open/spec.md" <<'EOF'
# Done open
**Status:** DONE
**Verified at:** 1234567

## Acceptance Criteria
- [x] AC-1 first
- [ ] AC-2 second

## Changes
MODIFIED: `src/a.ts` — edit
ADDED: `src/new.ts` — new
- Past EOF `src/a.ts:40` VERIFIED

## Refine
Round 1/1, 2026-01-02. Critic: agon nero.
EOF
mk "$S/free-text/spec.md" <<'EOF'
# Free text
**Status:** waiting on legal
EOF
mk "$S/ready-norefine/spec.md" <<'EOF'
# Ready without refine
**Status:** READY TO BUILD
EOF
mk "$S/no-status/spec.md" <<'EOF'
# No status
Some prose.
EOF
mk "$S/pointer/spec.md" <<'EOF'
Moved to `docs/specs/gone/spec.md`.
EOF

run env LC_ALL=C "$CHECK" "$N"
rc_is "AC-1 non-git dir exits 0" 0
count_is "AC-1 one NO-GIT line per spec" NO-GIT 5
has "AC-1 NO-GIT names the spec" NO-GIT ".claude/specs/done-open/spec.md: "
has "AC-1 DONE + unchecked AC" STATUS-OPEN ".claude/specs/done-open/spec.md: Status 'DONE' but 1 unchecked"
has "AC-1 free-text Status" STATUS-ENUM ".claude/specs/free-text/spec.md:"
has "AC-1 READY without Refine" NO-REVIEW ".claude/specs/ready-norefine/spec.md:"
has "AC-1 no Status" NO-STATUS ".claude/specs/no-status/spec.md:"
has "AC-1 pointer still checked" POINTER ".claude/specs/pointer/spec.md:"
for k in STALE XREPO DEAD-CITE STALE-CITE STATUS-SHIPPED REPEAT-FIX "CONTRACT-[A-Z]*" UNMERGED; do
  hasnt "AC-1 git kind $k skipped" "$k" ""
done
case "$ERR" in *fatal:*|*"not a git"*) bad "AC-1 stderr has git noise: $ERR" ;; *) ok ;; esac
run "$CHECK" --strict "$N"
rc_is "AC-1 --strict exits 1" 1
run "$CHECK" --spec "$S/ready-norefine/spec.md"
rc_is "AC-1 --spec only exits 0" 0
has "AC-1 --spec only: root = spec dir" NO-GIT "spec.md: "
has "AC-1 --spec only still checks" NO-REVIEW "spec.md: "
run "$CHECK" --spec "$S/ready-norefine/spec.md" "$N"
has "AC-1 explicit root argument" NO-GIT ".claude/specs/ready-norefine/spec.md: "
mk "$T/clean/spec.md" <<'EOF'
# Clean
**Status:** SPEC
EOF
run "$CHECK" --spec "$T/clean/spec.md"
rc_is "AC-1 clean spec exits 0" 0
count_is "AC-1 clean spec: NO-GIT only" "[A-Z-]*" 1
has "AC-1 clean spec: the one finding is NO-GIT" NO-GIT "spec.md: "
run "$CHECK" --strict --spec "$T/clean/spec.md"
rc_is "AC-1 --strict: NO-GIT alone counts" 1
run "$CHECK" "$T/missing-root"
rc_is "AC-1 missing root dir exits 2" 2
run "$CHECK" --spec "$T/clean/spec.md" "$T/missing-root"
rc_is "AC-1 --spec with missing root exits 2" 2
cp -R "$N" "$T/gitcopy"; new_repo "$T/gitcopy"; commit "$T/gitcopy" base
run "$CHECK" "$T/gitcopy"
has "AC-1 control: same fixture in git gets DEAD-CITE" DEAD-CITE ".claude/specs/done-open/spec.md:"
hasnt "AC-1 control: git repo has no NO-GIT" NO-GIT ""

R1="$T/r1"
mkdir -p "$R1/d/sub" "$R1/d/.git" "$R1/d/node_modules"
printf 'alpha\n' > "$R1/a.txt"; printf 'beta\n' > "$R1/b.txt"
printf 'x\n' > "$R1/d/x.txt"; printf 'y\n' > "$R1/d/sub/y.txt"
printf 'ds' > "$R1/d/.DS_Store"; printf 'ref\n' > "$R1/d/.git/HEAD"; printf 'm\n' > "$R1/d/node_modules/m.js"
covers s1 a.txt d/; covers s1r d/ a.txt
dirhash "$T/hs/s1.md" "$R1"; H1="$H"
rc_is "AC-2 print mode exits 0" 0
if [ "$OUT" = "dir-hash $H1 root $R1" ] && hex64 "$H1"; then ok; else bad "AC-2 exact output: '$OUT'"; fi
dirhash "$T/hs/s1r.md" "$R1"; same_hash "AC-2 covered order irrelevant" "$H" "$H1"
printf 'changed' > "$R1/d/.DS_Store"
dirhash "$T/hs/s1.md" "$R1"; same_hash "AC-2 .DS_Store ignored" "$H" "$H1"
printf 'moved\n' > "$R1/d/.git/HEAD"; printf 'm2\n' > "$R1/d/node_modules/m.js"; printf 'n\n' > "$R1/d/node_modules/n.js"
dirhash "$T/hs/s1.md" "$R1"; same_hash "AC-2 nested .git/ and node_modules/ pruned" "$H" "$H1"
printf 'y2\n' > "$R1/d/sub/y.txt"
dirhash "$T/hs/s1.md" "$R1"; diff_hash "AC-2 dir entry hashes files below it" "$H" "$H1"
printf 'y\n' > "$R1/d/sub/y.txt"
dirhash "$T/hs/s1.md" "$R1"; same_hash "AC-2 restored content hashes back" "$H" "$H1"
cp -R "$R1" "$T/r1copy"
dirhash "$T/hs/s1.md" "$T/r1copy"; same_hash "AC-2 root-independent" "$H" "$H1"
mkdir -p "$T/r3"; printf 'alpha\n' > "$T/r3/a.txt"
if ln -s "$R1/d" "$T/r3/d" 2>/dev/null && [ -L "$T/r3/d" ]; then
  dirhash "$T/hs/s1.md" "$T/r3"; same_hash "AC-2 covered dir that is a symlink" "$H" "$H1"
else
  echo "SKIP AC-2 covered dir that is a symlink: ln -s cannot create a symlink here"
fi
covers s2 a.txt gone.txt; covers s3 a.txt
dirhash "$T/hs/s2.md" "$R1"; H2="$H"
rc_is "AC-2 one of two covered files missing still hashes" 0
dirhash "$T/hs/s3.md" "$R1"; H3="$H"
diff_hash "AC-2 missing entry differs from omitted entry" "$H2" "$H3"
covers s4 gone.txt gone2.txt
dirhash "$T/hs/s4.md" "$R1"; rc_is "AC-2 no covered file exists exits 2" 2
covers s0
dirhash "$T/hs/s0.md" "$R1"; rc_is "AC-2 no covered entries exits 2" 2
covers s5 a.txt 'd/*.txt'
dirhash "$T/hs/s5.md" "$R1"
same_hash "AC-2 glob entry skipped" "$H" "$H3"
case "$ERR" in *'d/*.txt'*) ok ;; *) bad "AC-2 glob skip note on stderr: '$ERR'" ;; esac
printf 'secret\n' > "$T/outside.txt"
covers s7 a.txt ../outside.txt "$T/outside.txt" d/../../outside.txt
dirhash "$T/hs/s7.md" "$R1"
same_hash "AC-2 entries escaping root never hashed" "$H" "$H3"
mkdir -p "$T/r4" "$T/r5"
printf 'alpha\n' > "$T/r4/a.txt"; printf 'beta\n' > "$T/r4/b.txt"
printf 'beta\n' > "$T/r5/a.txt"; printf 'alpha\n' > "$T/r5/b.txt"
covers s6 a.txt b.txt
dirhash "$T/hs/s6.md" "$T/r4"; H4="$H"
dirhash "$T/hs/s6.md" "$T/r5"; diff_hash "AC-2 swapped contents differ" "$H" "$H4"
GOLD="$T/gold"; mkdir -p "$GOLD/d/c" "$GOLD/d/c-"
printf 'alpha\n' > "$GOLD/a.txt"; printf 'beta\n' > "$GOLD/d/b.txt"; printf 'gamma\r\n' > "$GOLD/d/c/e.txt"; printf 'x' > "$GOLD/d/.DS_Store"
printf 'delta\n' > "$GOLD/d/c-/f.txt"; printf 'epsilon\n' > "$GOLD/d/c.txt"
covers golden a.txt d/ missing.txt
dirhash "$T/hs/golden.md" "$GOLD"
if [ "$OUT" = "dir-hash $GOLDEN root $GOLD" ]; then ok; else bad "AC-2 golden: '$OUT'"; fi
mkdir -p "$T/home/proj" "$T/homey"; printf 'alpha\n' > "$T/home/proj/a.txt"; printf 'alpha\n' > "$T/home/a.txt"; printf 'alpha\n' > "$T/homey/a.txt"
run env HOME="$T/home" "$CHECK" --spec "$T/hs/s3.md" --dir-hash "$T/home/proj"
if [ "$OUT" = "dir-hash $H3 root ~/proj" ]; then ok; else bad "AC-2 \$HOME/ prefix shown as ~: '$OUT'"; fi
run env HOME="$T/home" "$CHECK" --spec "$T/hs/s3.md" --dir-hash "$T/home"
if [ "$OUT" = "dir-hash $H3 root ~" ]; then ok; else bad "AC-2 \$HOME itself shown as ~: '$OUT'"; fi
run env HOME="$T/home" "$CHECK" --spec "$T/hs/s3.md" --dir-hash "$T/homey"
if [ "$OUT" = "dir-hash $H3 root $T/homey" ]; then ok; else bad "AC-2 sibling sharing the \$HOME prefix not shown as ~: '$OUT'"; fi

mkbin() {
  local d="$1" t p; shift; mkdir -p "$d"
  for t in "$@"; do
    p="$(command -v "$t")" || continue
    case "$p" in /*) printf '#!/bin/sh\nexec "%s" "$@"\n' "$p" > "$d/$t"; chmod +x "$d/$t" ;; esac
  done
}
TOOLS="awk basename cat cksum cut dirname find grep head mktemp rm sed sort tail tr uniq wc git"
# shellcheck disable=SC2086 # TOOLS is a word list
mkbin "$T/bin-shasum" $TOOLS shasum
# shellcheck disable=SC2086 # TOOLS is a word list
mkbin "$T/bin-none" $TOOLS
if env PATH="$T/bin-shasum" "$BASH" -c 'command -v shasum && ! command -v sha256sum' >/dev/null 2>&1; then
  run env HOME="$T/nohome" PATH="$T/bin-shasum" "$BASH" "$CHECK" --spec "$T/hs/golden.md" --dir-hash "$GOLD"
  if [ "$OUT" = "dir-hash $GOLDEN root $GOLD" ]; then ok; else bad "AC-2 shasum fallback: '$OUT' $ERR"; fi
else
  echo "SKIP AC-2 shasum fallback: no shasum on this system to fall back to"
fi
run env HOME="$T/nohome" PATH="$T/bin-none" "$BASH" "$CHECK" --spec "$T/hs/golden.md" --dir-hash "$GOLD"
rc_is "AC-2 neither sha256sum nor shasum exits 2" 2

A="$T/anc"; AS="$A/.claude/specs"
mkdir -p "$A/src" "$A/lib"; printf 'one\n' > "$A/src/a.txt"; printf 'two\n' > "$A/lib/b.txt"
covers anc src/a.txt lib/; covers only src/a.txt
dirhash "$T/hs/anc.md" "$A"; HA="$H"
dirhash "$T/hs/only.md" "$A"; HO="$H"
anchored() {
  local f="$1" v="$2" p; shift 2
  { printf '# Anchored\n**Status:** SPEC\n**Verified at:** %s\n\n## Changes\n' "$v"
    for p in "$@"; do printf 'MODIFIED: `%s` — edit\n' "$p"; done; } | mk "$f"
}
anchored "$AS/dh/spec.md" "dir-hash $HA root $A" src/a.txt lib/
anchored "$AS/only/spec.md" "dir-hash $HO root $A" src/a.txt
anchored "$AS/prefix/spec.md" "dir-hash $(printf '%s' "$HA" | cut -c1-12) root $A" src/a.txt lib/
anchored "$AS/short/spec.md" "dir-hash $(printf '%s' "$HA" | cut -c1-11) root $A" src/a.txt lib/
anchored "$AS/wrong/spec.md" "dir-hash 000000000000 root $A" src/a.txt lib/
anchored "$AS/noroot/spec.md" "dir-hash $HA" src/a.txt lib/
run "$CHECK" "$A"
rc_is "AC-3 anchored non-git dir exits 0" 0
has "AC-3 dir-hash runs in a non-git dir" NO-GIT ".claude/specs/dh/spec.md:"
hasnt "AC-3 equal hash is quiet" STALE ".claude/specs/dh/"
hasnt "AC-3 12-hex prefix is quiet" STALE ".claude/specs/prefix/"
has "AC-3 11-hex prefix is too short" STALE ".claude/specs/short/"
has "AC-3 wrong 12-hex prefix" STALE ".claude/specs/wrong/spec.md: .*dir-hash 000000000000"
hasnt "AC-3 anchor without root uses spec-check's root" STALE ".claude/specs/noroot/"
run "$CHECK" --spec "$AS/noroot/spec.md" "$R1"
has "AC-3 anchor without root follows the root argument" STALE ".*/noroot/spec.md: "
printf 'one edited\n' > "$A/src/a.txt"
run "$CHECK" "$A"
has "AC-3 content edit" STALE ".claude/specs/dh/spec.md: .*dir-hash $(printf '%s' "$HA" | cut -c1-12)"
printf 'one\n' > "$A/src/a.txt"; printf 'three\n' > "$A/lib/c.txt"
run "$CHECK" "$A"
has "AC-3 new file in covered dir" STALE ".claude/specs/dh/spec.md:"
rm "$A/lib/c.txt"; rm "$A/lib/b.txt"
run "$CHECK" "$A"
has "AC-3 covered file deleted" STALE ".claude/specs/dh/spec.md:"
printf 'two\n' > "$A/lib/b.txt"; printf 'ds' > "$A/lib/.DS_Store"
run "$CHECK" "$A"
hasnt "AC-3 .DS_Store added is quiet" STALE ".claude/specs/dh/"
rm "$A/src/a.txt"
run "$CHECK" "$A"
has "AC-3 only covered file deleted" STALE ".claude/specs/only/spec.md:"
rc_is "AC-3 only covered file deleted exits 0" 0
printf 'one\n' > "$A/src/a.txt"
anchored "$T/elsewhere/spec.md" "dir-hash $HA root $A" src/a.txt lib/
run "$CHECK" --spec "$T/elsewhere/spec.md"
has "AC-3 no root argument: NO-GIT" NO-GIT "spec.md:"
hasnt "AC-3 no root argument uses the anchor's root" STALE ""
mkdir -p "$T/home/x"; cp -R "$A/src" "$A/lib" "$T/home/x/"
anchored "$T/tilde/spec.md" "dir-hash $HA root ~/x" src/a.txt lib/
run env HOME="$T/home" "$CHECK" --spec "$T/tilde/spec.md"
hasnt "AC-3 root ~/x expands with HOME" STALE ""
run env HOME="$T/elsewhere" "$CHECK" --spec "$T/tilde/spec.md"
has "AC-3 control: other HOME goes STALE" STALE "spec.md:"
anchored "$T/tilde-home/spec.md" "dir-hash $HA root ~" src/a.txt lib/
run env HOME="$T/home/x" "$CHECK" --spec "$T/tilde-home/spec.md"
hasnt "AC-3 root ~ expands to HOME" STALE ""
mkdir -p "$T/crlf"
printf '# CRLF\r\n**Status:** SPEC\r\n**Verified at:** dir-hash %s root `~/x`\r\n\r\n## Changes\r\nMODIFIED: `src/a.txt` — edit\r\nMODIFIED: `lib/` — dir\r\n' "$HA" > "$T/crlf/spec.md"
run env HOME="$T/home" "$CHECK" --spec "$T/crlf/spec.md"
has "AC-3 CRLF spec runs" NO-GIT "spec.md:"
hasnt "AC-3 CRLF + backtick root is quiet" STALE ""
mkdir -p "$T/sp ace"; cp -R "$A/src" "$A/lib" "$T/sp ace/"
dirhash "$T/hs/anc.md" "$T/sp ace"
if [ "$OUT" = "dir-hash $HA root $T/sp ace" ]; then ok; else bad "AC-3 print root with a space: '$OUT'"; fi
anchored "$T/space/spec.md" "dir-hash $HA root $T/sp ace" src/a.txt lib/
run "$CHECK" --spec "$T/space/spec.md"
hasnt "AC-3 root with a space is quiet" STALE ""
printf 'edited\n' > "$T/sp ace/src/a.txt"
run "$CHECK" --spec "$T/space/spec.md"
has "AC-3 control: root with a space goes STALE on edit" STALE "spec.md:"

G="$T/git"; GS="$G/.claude/specs"; new_repo "$G"
mkdir -p "$G/src" "$G/lib"; printf 'one\n' > "$G/src/a.txt"; printf 'two\n' > "$G/lib/b.txt"; commit "$G" base
C1="$(git -C "$G" rev-parse HEAD)"
dirhash "$T/hs/anc.md" "$G"; HG="$H"
anchored "$GS/dh/spec.md" "dir-hash $HG root $G" src/a.txt lib/
anchored "$GS/shaish/spec.md" "dir-hash $C1 root $G" src/a.txt lib/
commit "$G" specs
run "$CHECK" "$G"
hasnt "AC-3 git repo: no NO-GIT" NO-GIT ""
hasnt "AC-3 git repo: equal dir-hash is quiet" STALE ".claude/specs/dh/"
printf 'one edited\n' > "$G/src/a.txt"; commit "$G" edit
run "$CHECK" "$G"
has "AC-3 git repo: edit goes STALE via dir-hash" STALE ".claude/specs/dh/spec.md: .*dir-hash"
has "AC-3 git repo: sha-shaped dir-hash compared as dir-hash" STALE ".claude/specs/shaish/spec.md: .*dir-hash"
hasnt "AC-3 git repo: dir-hash never tried as a git sha" STALE ".claude/specs/shaish/spec.md: [0-9]* files:"

C="$T/crit"; CS="$C/.claude/specs"
mk "$CS/plural/spec.md" <<'EOF'
# Plural
**Status:** READY TO BUILD

## Refine
Round 2/2, 2026-01-02, anchor n/a. Critics: agon nero r1 (agy, FLAWED 28%), nero r2 (agy, FLAWED 34%).
EOF
mk "$CS/plural-pending/spec.md" <<'EOF'
# Plural pending
**Status:** READY TO BUILD

## Refine
Round 1/2. Critics: pending
EOF
mk "$CS/singular/spec.md" <<'EOF'
# Singular
**Status:** IN PROGRESS

## Refine
Round 1/1, 2026-01-02. Critic: agon nero (low risk).
EOF
mkdir -p "$CS/crlf-plural" "$CS/crlf-pending"
printf '# CRLF plural\r\n**Status:** READY TO BUILD\r\n\r\n## Refine\r\nRound 1/1. Critics: agon nero\r\n' > "$CS/crlf-plural/spec.md"
printf '# CRLF pending\r\n**Status:** READY TO BUILD\r\n\r\n## Refine\r\nRound 1/1. Critics: pending\r\n' > "$CS/crlf-pending/spec.md"
run "$CHECK" "$C"
hasnt "AC-4 Critics: plural accepted" NO-REVIEW ".claude/specs/plural/"
has "AC-4 Critics: pending" NO-REVIEW ".claude/specs/plural-pending/spec.md: Status 'READY TO BUILD' but Critic is pending"
hasnt "AC-4 Critic: mid-line unchanged" NO-REVIEW ".claude/specs/singular/"
hasnt "AC-4 CRLF Critics: accepted" NO-REVIEW ".claude/specs/crlf-plural/"
has "AC-4 CRLF Critics: pending" NO-REVIEW ".claude/specs/crlf-pending/spec.md: .*Critic is pending"

O="$T/open"; OS="$O/.claude/specs"
MSG="OPEN (max 3) — decide the rest as ASSUMED with reasoning (core step 5)"
mk "$OS/four/spec.md" <<'EOF'
# Four
**Status:** SPEC
## Open Questions
1. OPEN: a?
2. OPEN — b?
3. (OPEN) c?
4. OPEN d, and OPEN again on the same line
EOF
mk "$OS/three/spec.md" <<'EOF'
# Three
**Status:** SPEC
- OPEN: a?
- OPEN: b?
- OPEN: c?
EOF
mk "$OS/excluded/spec.md" <<'EOF'
# Excluded
**Status:** SPEC
- OPEN: a?
- OPEN: b?
- OPEN: c?
- STATUS-OPEN fires on done specs
- REOPENED after review
- OPEN-CAP is a finding kind
- an open question in lowercase
- the `OPEN` tag in code
- OPENED and OPEN_X are words
EOF
mk "$OS/numbered/spec.md" <<'EOF'
# Numbered
**Status:** SPEC
- OPEN: a?
- OPEN: b?
- OPEN-2: c?
- OPEN-Q1: d?
EOF
mk "$OS/fenced/spec.md" <<'EOF'
# Fenced
**Status:** SPEC
- OPEN: a?
- OPEN: b?
- OPEN: c?
```text
OPEN: in a backtick fence
OPEN: again
```
~~~
OPEN: in a tilde fence
OPEN: again
~~~
EOF
mk "$OS/sections/spec.md" <<'EOF'
# Sections
**Status:** SPEC
- OPEN: a?
- OPEN: b?
- OPEN: c?
## Corrections Log
| OPEN claim | reality | impact |
## Refine
Fixed: OPEN d from round 1.
EOF
mk "$OS/after/spec.md" <<'EOF'
# After Refine
**Status:** SPEC
- OPEN: a?
- OPEN: b?
- OPEN: c?
## Refine
Fixed: OPEN d from round 1.
## Notes
- OPEN: e?
EOF
run "$CHECK" "$O"
has "AC-5 OPEN-CAP runs in a non-git dir" NO-GIT ".claude/specs/four/spec.md:"
has "AC-5 four lines, two on one line count once" OPEN-CAP ".claude/specs/four/spec.md: 4 $MSG\$"
hasnt "AC-5 exactly 3 is quiet" OPEN-CAP ".claude/specs/three/"
hasnt "AC-5 STATUS-OPEN, REOPENED, OPEN-CAP, lowercase, inline code not counted" OPEN-CAP ".claude/specs/excluded/"
has "AC-5 OPEN-2 and OPEN-Q1 counted" OPEN-CAP ".claude/specs/numbered/spec.md: 4 OPEN"
hasnt "AC-5 fenced OPEN not counted" OPEN-CAP ".claude/specs/fenced/"
hasnt "AC-5 Refine and Corrections Log not counted" OPEN-CAP ".claude/specs/sections/"
has "AC-5 counting resumes after Refine" OPEN-CAP ".claude/specs/after/spec.md: 4 OPEN"

ST="$T/steps"
rs() {
  local d="$ST/.claude/specs/$1"; mkdir -p "$d"
  { printf '# %s\n**Status:** %s\n' "$1" "$2"; [ -n "$3" ] && printf '**Depth:** %s\n' "$3"
    printf '\n## Refine\nRound 1/1, 2026-01-02. %s\n' "$4"; [ -n "${5:-}" ] && printf '\n## Notes\n%s\n' "$5"; } > "$d/spec.md"
}
rs full "READY TO BUILD" "Full — triggers: auth" "Critic: agon nero."
rs surgical "READY TO BUILD" "Surgical" "Critic: agon nero."
rs nodepth "READY TO BUILD" "" "Critic: agon nero."
rs tier2 "READY TO BUILD" "tier-2 — trigger: shared contract" "Critic: agon nero."
rs tier3 "IN PROGRESS" "Tier 3" "Critics: agon council."
rs tier1 "READY TO BUILD" "tier-1" "Critic: agon nero."
rs endash "READY TO BUILD" "Full" "Critic: agon nero. Steps: a–g."
rs hyphen "READY TO BUILD" "Full" "Critic: agon nero. Steps: a-g."
rs prose "READY TO BUILD" "Full" "Critics: agon nero; a–g applied."
rs letters "READY TO BUILD" "Full" "Critic: agon nero. Steps: a, c, d, e, f, g"
rs upper "READY TO BUILD" "Full" "Critic: agon nero. Steps: A–G."
rs partial "READY TO BUILD" "Full" "Critic: agon nero. Steps: a, d, e."
rs words "READY TO BUILD" "Full" "Critic: agon nero. Notes: data-gathering and schema-generation."
rs outside "READY TO BUILD" "Full" "Critic: agon nero." "Steps: a–g."
rs nocritic "READY TO BUILD" "Full" "No critic ran."
rs pending "READY TO BUILD" "Full" "Critics: pending"
rs spec SPEC "Full" "Critic: agon nero."
rs status-done DONE "Full" "Critic: agon nero."
for loc in default C; do
  if [ "$loc" = C ]; then run env LC_ALL=C "$CHECK" "$ST"; else run "$CHECK" "$ST"; fi
  L="AC-6 ($loc locale)"
  has "$L READY + Full + Critic without steps" REFINE-STEPS ".claude/specs/full/spec.md: Full-depth Refine names a Critic but records no step coverage (Steps: a–g)"
  hasnt "$L Surgical" REFINE-STEPS ".claude/specs/surgical/"
  hasnt "$L no Depth header" REFINE-STEPS ".claude/specs/nodepth/"
  has "$L tier-2" REFINE-STEPS ".claude/specs/tier2/"
  has "$L Tier 3 + IN PROGRESS + Critics" REFINE-STEPS ".claude/specs/tier3/"
  hasnt "$L tier-1" REFINE-STEPS ".claude/specs/tier1/"
  hasnt "$L Steps: a–g" REFINE-STEPS ".claude/specs/endash/"
  hasnt "$L Steps: a-g" REFINE-STEPS ".claude/specs/hyphen/"
  hasnt "$L a–g in prose" REFINE-STEPS ".claude/specs/prose/"
  hasnt "$L Steps: a, c, d, e, f, g" REFINE-STEPS ".claude/specs/letters/"
  hasnt "$L Steps: A–G" REFINE-STEPS ".claude/specs/upper/"
  has "$L Steps: a, d, e" REFINE-STEPS ".claude/specs/partial/"
  has "$L data-gathering / schema-generation only" REFINE-STEPS ".claude/specs/words/"
  has "$L Steps: outside ## Refine" REFINE-STEPS ".claude/specs/outside/"
  has "$L no Critic: NO-REVIEW" NO-REVIEW ".claude/specs/nocritic/"
  hasnt "$L no Critic: no REFINE-STEPS" REFINE-STEPS ".claude/specs/nocritic/"
  has "$L Critics: pending: NO-REVIEW" NO-REVIEW ".claude/specs/pending/spec.md: .*pending"
  hasnt "$L Critics: pending: no REFINE-STEPS" REFINE-STEPS ".claude/specs/pending/"
  hasnt "$L Status SPEC" REFINE-STEPS ".claude/specs/spec/"
  has "$L Status DONE" REFINE-STEPS ".claude/specs/status-done/"
done

mkdir -p "$GS"
cp -R "$CS/plural" "$CS/plural-pending" "$OS/four" "$ST/.claude/specs/full" "$ST/.claude/specs/endash" "$GS/"
commit "$G" "more specs"
run "$CHECK" "$G"
hasnt "AC-1 git repo: no NO-GIT" NO-GIT ""
hasnt "AC-4 git repo: Critics: accepted" NO-REVIEW ".claude/specs/plural/"
has "AC-4 git repo: Critics: pending" NO-REVIEW ".claude/specs/plural-pending/"
has "AC-5 git repo: OPEN-CAP" OPEN-CAP ".claude/specs/four/spec.md: 4 $MSG\$"
has "AC-6 git repo: REFINE-STEPS" REFINE-STEPS ".claude/specs/full/"
hasnt "AC-6 git repo: Steps: a–g" REFINE-STEPS ".claude/specs/endash/"

echo "test-spec-check-nogit: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
