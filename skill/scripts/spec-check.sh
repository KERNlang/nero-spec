#!/usr/bin/env bash
# Usage: spec-check.sh [--strict] [--spec FILE] [--repos name=path[,...]] [--stale] [--touching LIST]
#                      [--shipped-pct N] [--repeat-fix N] [--repeat-days D] [--ref-cap N] [--field-window N]
#                      [--dir-hash] [--pr-title TITLE] [repo-dir]
#
# Mechanical health checks for claim-tagged specs. Exit 1 for strict findings, 2 for broken invocation or config.
# One line per finding, then a summary. Kinds:
#   STALE          covered files changed since the anchor (same repo), or differ from a dir-hash anchor
#   XREPO          covered files in another repo changed since the anchor date
#   DEAD-CITE      VERIFIED citation to a file that is gone, or a line beyond EOF
#   STALE-CITE     VERIFIED file:line whose lines changed or moved since the anchor
#   STATUS-OPEN    Status DONE/IMPLEMENTED/SHIPPED/COMPLETE with unchecked acceptance criteria
#   STATUS-SHIPPED Status IN PROGRESS/READY but >= N% (default 80) of covered paths known to the default
#                  branch changed there after the spec (commits in anchor..branch, anchor = Verified at/Baseline or
#                  the commit that added the spec; else last change strictly after Date). Min 3 paths; paths never
#                  on the branch are ignored
#   POINTER        pointer spec whose target does not exist
#   STATUS-ENUM    Status does not start with SPEC | READY TO BUILD | IN PROGRESS | DONE (a " — note" may follow)
#   REPEAT-FIX     >= N (default 4) fix/hotfix/revert commits on covered paths within D (default 30) days of Date
#   NO-STATUS      spec without a **Status:** header
#   CONTRACT-MISSING  a `METHOD /path` in a ## Contract section is absent from a named repo's default branch or
#                  HEAD; lists the branches (newest --ref-cap, default 20) that have it. Status READY/IN PROGRESS/DONE
#   CONTRACT-FIELDS   a consumer's call sites of an endpoint (+/- --field-window lines, default 15) never name a
#                  contract field the producer has (snake_case, camelCase, PascalCase or kebab-case)
#   UNMERGED       Status READY/DONE but ADDED paths are not on that repo's default branch (branches listed)
#   NO-REVIEW      Status READY/IN PROGRESS/DONE but no `## Refine` section with a non-empty `Critic:`/`Critics:` line
#   REFINE-STEPS   same Status, **Depth:** Full or tier 2-4 and a Critic, but ## Refine has no a–g / `Steps:` coverage
#   OPEN-CAP       more than 3 lines tagged OPEN outside code, fences, ## Refine and ## Corrections Log
#   NO-GIT         target outside any git repo: root = repo-dir, else the spec's dir; git-based kinds skipped
#   POLICY-CONFLICT  .spec loosens the company policy (owned format keys, agon above agon.max, engines, addons)
#   POLICY-RULES   a policy rules file is missing, a symlink or outside the repo
#   POLICY-SKILL   a skill named in the policy `skills` has no SKILL.md inside the repo
#   POLICY-HEADER / POLICY-SECTION / POLICY-TICKET / POLICY-WORD  spec misses a required header or section
#                  (sections only at READY/IN PROGRESS/DONE), Ticket fails ticket.regex, or uses a denied word
# Policy: `.spec` `policy: <repo-relative .md>`, else the local lookup in spec-check-policy-local.sh when present.
# Invalid policy file → exit 2.
# --pr-title TITLE: only checks a PR title against the policy (pr.regex, else pr.title with <n> = digits,
# <a|b> = one of, any other <x> = text) and, with --spec, that it names the spec's Ticket key. Exit 0 ok, 1 no, 2 no policy.
#
# Anchor: **Verified at:** sha, else Baseline: sha, else the spec's Date. DONE specs without a sha fall back to
# their last commit only with --stale or drift-guard on in .spec (preset default unless -drift-guard).
# **Verified at:** dir-hash <hex> root <dir> (git or not): STALE when the sha256 over the unqualified covered files and
# dir/ trees under that root (else repo-dir) differs; >= 12 hex compared. --dir-hash (needs --spec) prints that value
# for repo-dir, else the spec's dir; exit 2 when no covered file exists or neither sha256sum nor shasum is found.
# Covered paths: ## Changes (ADDED/MODIFIED/REMOVED lines), else **Covers:**, else the Blast Radius section.
# A token is a path when it is a glob, ends in /, starts with a directory tracked in a named repo, or ends in an
# extension some tracked file has (any stack); identifiers like `user.id`, `Foo.Bar`, `foo.bar()` are ignored.
# --touching LIST: only specs named in LIST (one path per line) or whose covered paths match one; quiet when none.
# Contract rows: `| Endpoint | Fields | Producer | Consumers |` (backtick values); rows without role columns only get
# CONTRACT-MISSING over the spec's repo and the repos in Changes. Heuristics; false-positive modes in spec-check-contract.sh.
# Other repos: `name:path`, a table cell "name `path`", or a first path segment naming a sibling repo;
# names resolve via `repos: name=path, ...` in .spec or --repos (paths relative to the git root).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for helper in spec-check-lib.sh spec-check-contract.sh spec-check-policy.sh; do
  # shellcheck disable=SC1090 # helper path resolved at runtime
  [ -r "$HERE/$helper" ] && . "$HERE/$helper" || { echo "spec-check: cannot load $HERE/$helper" >&2; exit 2; }
done
# shellcheck disable=SC1091 # optional helper, absent in vendored copies
[ -r "$HERE/spec-check-policy-local.sh" ] && . "$HERE/spec-check-policy-local.sh"

STRICT=0; DIR=""; ONE=""; PRTITLE=""; PRTITLE_SET=0; REPOS_ARG=""; SHIPPED_PCT=80; SHIPPED_MIN=3; STALE_FLAG=0; TOUCHING=""; DIRHASH=0
REPEAT_MIN=4; REPEAT_DAYS=30; REF_CAP=20; FIELD_WINDOW=15
while [ $# -gt 0 ]; do
  case "$1" in
    --strict) STRICT=1 ;;
    --spec) ONE="${2:-}"; shift ;;
    --spec=*) ONE="${1#--spec=}" ;;
    --repos) REPOS_ARG="$REPOS_ARG,${2:-}"; shift ;;
    --repos=*) REPOS_ARG="$REPOS_ARG,${1#--repos=}" ;;
    --shipped-pct) SHIPPED_PCT="${2:-80}"; shift ;;
    --repeat-fix) REPEAT_MIN="${2:-4}"; shift ;;
    --repeat-days) REPEAT_DAYS="${2:-30}"; shift ;;
    --ref-cap) REF_CAP="${2:-20}"; shift ;;
    --field-window) FIELD_WINDOW="${2:-15}"; shift ;;
    --stale) STALE_FLAG=1 ;;
    --dir-hash) DIRHASH=1 ;;
    --pr-title) PRTITLE="${2-}"; PRTITLE_SET=1; shift ;;
    --touching) TOUCHING="${2:-}"; shift ;;
    -h|--help) awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; exit 0 ;;
    -*) echo "spec-check: unknown flag $1" >&2; exit 2 ;;
    *) DIR="$1" ;;
  esac
  shift
done

numeric_option() {
  local name="$1" value="$2"
  case "$value" in ''|*[!0-9]*) echo "spec-check: $name must be a nonnegative integer" >&2; return 2 ;; esac
  [ "${#value}" -le 6 ] || { echo "spec-check: $name is too large" >&2; return 2; }
  printf '%s\n' "$((10#$value))"
}
SHIPPED_PCT="$(numeric_option --shipped-pct "$SHIPPED_PCT")" || exit 2
REPEAT_MIN="$(numeric_option --repeat-fix "$REPEAT_MIN")" || exit 2
REPEAT_DAYS="$(numeric_option --repeat-days "$REPEAT_DAYS")" || exit 2
REF_CAP="$(numeric_option --ref-cap "$REF_CAP")" || exit 2
FIELD_WINDOW="$(numeric_option --field-window "$FIELD_WINDOW")" || exit 2

if [ -n "$ONE" ]; then
  case "$ONE" in *$'\n'*|*$'\r'*|*$'\t'*) echo 'spec-check: unsupported spec path (newline, CR, or tab)' >&2; exit 2 ;; esac
  [ -f "$ONE" ] || { echo "spec-check: no such spec: $ONE" >&2; exit 2; }
  ONE="$(cd "$(dirname "$ONE")" && pwd -P)/$(basename "$ONE")"
  [ -n "$DIR" ] || DIR="$(dirname "$ONE")"
fi
[ -n "$DIR" ] || DIR="."
if [ -n "$TOUCHING" ]; then
  [ -f "$TOUCHING" ] || { echo "spec-check: no such list: $TOUCHING" >&2; exit 2; }
  TOUCHING="$(cd "$(dirname "$TOUCHING")" && pwd -P)/$(basename "$TOUCHING")"
fi

NOGIT=0
if ! ROOT="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  [ -d "$DIR" ] || { echo "spec-check: no such directory: $DIR" >&2; exit 2; }
  NOGIT=1; ROOT="$DIR"
fi
cd "$ROOT" || exit 2
ROOT="$(pwd -P)"
TMP_BASE="$(cd "${TMPDIR:-/tmp}" && pwd -P)" || exit 2
TMP="$(mktemp -d "$TMP_BASE/spec-check.XXXXXX")" || exit 2
case "$TMP" in "$TMP_BASE"/spec-check.*) [ -d "$TMP" ] || exit 2 ;; *) exit 2 ;; esac
trap 'rm -rf "$TMP"' EXIT

cfg() { [ -f .spec ] && awk -v k="$1" '{ sub(/[ \t]*#.*/, "") } index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); print; exit }' .spec; }

drift_guard_on() {
  [ "$STALE_FLAG" = 1 ] && return 0
  [ -f .spec ] || return 1
  local a; a="$(cfg addons | tr -d ' ')"
  case ",$a," in *,-drift-guard,*) return 1 ;; *,drift-guard,*|*,+drift-guard,*) return 0 ;; esac
  [ -n "$(cfg drift)" ] && return 0
  case "$(cfg preset | tr -d ' ')" in personal|team|enterprise|operator-reviewed) return 0 ;; esac
  return 1
}
STALE_FALLBACK=0; drift_guard_on && STALE_FALLBACK=1
policy_load || exit 2
if [ "$PRTITLE_SET" = 1 ]; then
  [ -n "$POLICY_FILE" ] || { echo "spec-check: --pr-title needs a company policy" >&2; exit 2; }
  policy_check_pr_title "$PRTITLE" "$ONE"; exit $?
fi

REPOMAP=""
add_repos() {
  local IFS=','; local pair name path abs
  for pair in $1; do
    pair="$(printf '%s' "$pair" | awk '{ $1 = $1; print }')"
    [ -n "$pair" ] || continue
    name="${pair%%=*}"; path="${pair#*=}"
    case "$path" in "~"/*) path="$HOME/${path#\~/}" ;; esac
    case "$path" in /*) ;; *) path="$ROOT/$path" ;; esac
    if [ "$name" = "$pair" ] || [ ! -d "$path" ]; then echo "spec-check: ignoring repos entry '$pair'" >&2; continue; fi
    abs="$(cd "$path" && pwd)"
    REPOMAP="$REPOMAP$name	$abs
$(basename "$abs")	$abs
"
  done
}
add_repos "$REPOS_ARG"
add_repos "$(cfg repos)"

SPEC_DIRS=""
if [ -z "$ONE" ]; then SPEC_DIRS="$(spec_scan_dirs "$(cfg specs.path)")" || exit 2; fi

FINDINGS="$TMP/findings"; : > "$FINDINGS"
EMITTED="$TMP/emitted"; : > "$EMITTED"
emit() {
  local l="$1 $2: $3"
  grep -qxF -- "$l" "$EMITTED" && return 0
  echo "$l"; echo "$l" >> "$EMITTED"; echo "$1" >> "$FINDINGS"
}

list_specs() {
  if [ -n "$ONE" ]; then echo "${ONE#$ROOT/}"; return; fi
  spec_list_files "$SPEC_DIRS" | sort
}
SPEC_FILES="$(list_specs)" || exit 2
[ "$DIRHASH" = 1 ] || policy_check_repo

is_pointer() {
  [ "$(grep -c '[^[:space:]]' "$1")" -le 6 ] && tr -d '`' < "$1" | grep -qE '[~A-Za-z0-9_./@-]*specs/[~A-Za-z0-9_./@-]*\.md'
}

check_pointer() {
  local f="$1" line t first rest ok r w
  while IFS= read -r line; do
    for t in $(printf '%s\n' "$line" | tr -d '`' | grep -oE '[~A-Za-z0-9_./@-]*specs/[~A-Za-z0-9_./@-]*\.md'); do
      ok=0; first="${t%%/*}"; rest="${t#*/}"
      # shellcheck disable=SC2088 # matches a literal leading tilde
      case "$t" in "~/"*) t="$HOME/${t#\~/}" ;; esac
      if [ -e "$t" ] && case "$t" in /*) true ;; *) false ;; esac; then ok=1
      elif [ -e "$ROOT/$t" ]; then ok=1
      elif [ "$first" != "$t" ] && [ ! -d "$ROOT/$first" ] && r="$(resolve_repo "$first")" && [ -e "$r/$rest" ]; then ok=1
      else
        for r in $(other_repos) $(for w in $(printf '%s' "$line" | tr -c 'A-Za-z0-9_.-' ' '); do sibling_repo "$w"; done); do
          [ -e "$r/$t" ] && { ok=1; break; }
        done
      fi
      [ "$ok" = 1 ] || emit POINTER "$f" "target \`$t\` does not exist"
    done
  done < "$f"
}

entries_of() {
  local e; e="$(changes_entries "$1")"
  [ -n "$e" ] || e="$(covers_entries "$1")"
  [ -n "$e" ] || e="$(blast_entries "$1")"
  printf '%s' "$e"
}

split_qual() {
  local qual="$1" path="$2" first="${2%%/*}" r
  if [ -z "$qual" ] && [ "$first" != "$path" ] && [ ! -d "$ROOT/$first" ] && r="$(sibling_repo "$first")"; then
    echo "$r	${path#*/}"; return 0
  fi
  r="$(resolve_repo "$qual")" || return 1
  echo "$r	$path"
}

check_status_shipped() {
  local f="$1" date="$2" entries="$3" base="${4:-}" known=0 hits=0 q p x repo rp br
  [ -n "$base" ] || base="$(git log --follow --diff-filter=A --format=%H -1 -- "$f" 2>/dev/null)"
  while IFS='	' read -r q p x; do
    [ -n "$p" ] || continue
    [ "$q" = - ] && q=""
    x="$(split_qual "$q" "$p")" || continue
    repo="${x%%	*}"; rp="${x#*	}"; br="$(def_branch "$repo")"
    # shellcheck disable=SC2046 # pathspecs are newline-split under IFS with globbing off
    x="$(IFS=$'\n'; set -f; git -C "$repo" log -1 --format=%cs "$br" -- $(pathspecs "$rp") 2>/dev/null)"
    [ -n "${SPEC_CHECK_DEBUG:-}" ] && echo "  debug shipped: $(basename "$repo") $rp last=${x:-never}" >&2
    [ -n "$x" ] || continue
    known=$((known + 1))
    if [ -n "$base" ] && git -C "$repo" merge-base --is-ancestor "$base" "$br" 2>/dev/null; then
      # shellcheck disable=SC2046 # pathspecs are newline-split under IFS with globbing off
      x="$(IFS=$'\n'; set -f; git -C "$repo" log -1 --format=%h "$base..$br" -- $(pathspecs "$rp") 2>/dev/null)"
      [ -n "$x" ] && hits=$((hits + 1))
    else
      [ "$x" \> "$date" ] && hits=$((hits + 1))
    fi
  done <<EOF
$entries
EOF
  [ "$known" -ge "$SHIPPED_MIN" ] && [ $((hits * 100)) -ge $((known * SHIPPED_PCT)) ] &&
    emit STATUS-SHIPPED "$f" "$hits/$known covered paths changed on the default branch since $date — possibly shipped, update Status"
}

check_repeat_fix() {
  local f="$1" since="$2" entries="$3" until q p x repo rp subjects="" n
  until="$(date_plus "$since" "$REPEAT_DAYS")"
  while IFS='	' read -r q p x; do
    [ -n "$p" ] || continue
    [ "$q" = - ] && q=""
    x="$(split_qual "$q" "$p")" || continue
    repo="${x%%	*}"; rp="${x#*	}"
    # shellcheck disable=SC2046 # pathspecs are newline-split under IFS with globbing off
    x="$(IFS=$'\n'; set -f; git -C "$repo" log --all --since="$since 00:00:00" --until="$until 23:59:59" --format='%h	%s' -- $(pathspecs "$rp") 2>/dev/null)"
    while IFS='	' read -r q p; do
      [ -n "$p" ] && is_fix_subject "$p" && subjects="$subjects$(basename "$repo")@$q	$p"$'\n'
    done <<EOF
$x
EOF
  done <<EOF
$entries
EOF
  n="$(printf '%s' "$subjects" | awk -F'\t' 'NF && !s[$1]++ { n++ } END { print n + 0 }')"
  [ "$n" -ge "$REPEAT_MIN" ] || return 0
  emit REPEAT-FIX "$f" "$n fix/revert commits on covered paths within $REPEAT_DAYS days of $since ($(printf '%s' "$subjects" | awk -F'\t' 'NF && !s[$1]++ && ++k <= 3 { printf "%s%s", (k > 1 ? ", " : ""), $1 }')) — escalate: repeated fixes, write a bigger spec"
}

touches() {
  local f="$1" entries="$2" q p x t
  grep -qxF -- "$f" "$TOUCHING" && return 0
  while IFS='	' read -r q p x; do
    [ -n "$p" ] || continue
    [ "$q" = - ] && q=""
    x="$(split_qual "$q" "$p")" || continue
    [ "${x%%	*}" = "$ROOT" ] || continue
    p="${x#*	}"
    while IFS= read -r t; do
      [ -n "$t" ] && ( set -f; entry_matches "$p" "$t" ) && return 0
    done < "$TOUCHING"
  done <<EOF
$entries
EOF
  return 1
}

xrepo_record_path() {
  local file="$1" first="$2" epoch="$3" anchor="$4" out="$5"
  if [ "$first" = 1 ]; then
    case "$file" in $'\n'*) file="${file#$'\n'}" ;; *) echo 'invalid git history framing' >&2; return 2 ;; esac
  fi
  case "$file" in *$'\n'*|*$'\r'*|*$'\t'*) echo 'unsupported history path (newline, CR, or tab)' >&2; return 2 ;; esac
  [ "$epoch" -ge "$anchor" ] && printf '%s\n' "$file" >> "$out"
  return 0
}

xrepo_changes() {
  local repo="$1" rp="$2" anchor="$3" raw="$TMP/xrepo-raw" out="$TMP/xrepo-paths" token pending="" epoch="" first=0
  : > "$out"
  # shellcheck disable=SC2046 # pathspecs are newline-split under IFS with globbing off
  (IFS=$'\n'; set -f; git -C "$repo" log -z --name-only --format='%ct%x00' "$(def_branch "$repo")" -- $(pathspecs "$rp")) > "$raw" || return 2
  while IFS= read -r -d '' token; do
    if [ -z "$token" ]; then
      case "$pending" in ''|*[!0-9]*) echo 'invalid git history framing' >&2; return 2 ;; esac
      epoch="$pending"; pending=""; first=1
    else
      if [ -n "$pending" ]; then
        [ -n "$epoch" ] || { echo 'invalid git history framing' >&2; return 2; }
        xrepo_record_path "$pending" "$first" "$epoch" "$anchor" "$out" || return 2
        first=0
      fi
      pending="$token"
    fi
  done < "$raw"
  if [ -n "$pending" ]; then xrepo_record_path "$pending" "$first" "$epoch" "$anchor" "$out" || return 2; fi
  cat "$out"
}

check_drift() {
  local f="$1" anchor="$2" label="$3" entries="$4" adate aepoch q p x repo rp changed local_changed="" xrepo=""
  adate="$(git show -s --format=%ci "$anchor" 2>/dev/null)"; aepoch="$(git show -s --format=%ct "$anchor" 2>/dev/null)"
  while IFS='	' read -r q p x; do
    [ -n "$p" ] || continue
    [ "$q" = - ] && q=""
    x="$(split_qual "$q" "$p")" || continue
    repo="${x%%	*}"; rp="${x#*	}"
    # shellcheck disable=SC2046
    if [ "$repo" = "$ROOT" ]; then
      changed="$(IFS=$'\n'; set -f; git diff --name-only "$anchor" -- $(pathspecs "$rp") 2>/dev/null; git ls-files --others --exclude-standard -- $(pathspecs "$rp") 2>/dev/null)"
      [ -n "$changed" ] && local_changed="$local_changed$changed"$'\n'
    else
      changed="$(xrepo_changes "$repo" "$rp" "$aepoch")" || exit 2
      [ -n "$changed" ] && xrepo="$xrepo$(printf '%s\n' "$changed" | sed "s|^|$(basename "$repo"):|")"$'\n'
    fi
  done <<EOF
$entries
EOF
  summarize() { printf '%s' "$1" | awk 'NF && !s[$0]++ { n++; if (n <= 3) l = l (n > 1 ? ", " : "") $0 } END { if (n) print n " files: " l (n > 3 ? ", +" (n - 3) : "") }'; }
  [ -n "$local_changed" ] && emit STALE "$f" "$(summarize "$local_changed") changed since $(git rev-parse --short "$anchor") ($label)"
  [ -n "$xrepo" ] && emit XREPO "$f" "$(summarize "$xrepo") changed since ${adate%% *} ($label)"
}

check_cites() {
  local f="$1" q p ranges cands r m found n maxl key base out="$TMP/cites"
  CITE_DATE="$2"
  # shellcheck disable=SC2034 # read by spec-check-lib.sh
  CITE_ANCHOR="$3"
  : > "$out"
  while IFS='	' read -r q p ranges; do
    [ -n "$p" ] || continue
    [ "$q" = - ] && q=""
    [ "$ranges" = - ] && ranges=""
    case "$p" in *\**) continue ;; esac
    if [ -n "$q" ]; then cands="$(resolve_repo "$q")" || continue
    elif r="$(split_qual "" "$p")" && [ "${r%%	*}" != "$ROOT" ]; then cands="${r%%	*}"; p="${r#*	}"
    else cands="$ROOT $(other_repos)"; fi
    # shellcheck disable=SC2086
    if ! found="$(locate head "$p" $cands)"; then
      found="$(locate base "$p" $cands)" && [ "$found" != AMBIGUOUS ] &&
        emit DEAD-CITE "$f" "\`$p\` existed at $(git -C "${found%%	*}" rev-parse --short "$(cite_base "${found%%	*}")"), gone now"
      continue
    fi
    [ "$found" = AMBIGUOUS ] || [ -z "$ranges" ] && continue
    r="${found%%	*}"; m="${found#*	}"
    n="$(awk 'END { print NR }' "$r/$m" 2>/dev/null)"; n="${n:-0}"
    maxl="$(printf '%s' "$ranges" | tr ',-' '\n\n' | sort -n | tail -1)"
    if [ "$maxl" -gt "$n" ]; then emit DEAD-CITE "$f" "\`$p:$ranges\` line $maxl beyond EOF ($n lines)"; continue; fi
    base="$(cite_base "$r")"
    [ -n "$base" ] || continue
    key="$TMP/diff-$(key_of "$r" "$base" "$m")"
    [ -f "$key" ] || git -C "$r" diff -U0 "$base" -- "$m" > "$key" 2>/dev/null
    range_status "$key" "$ranges" | sed "s|^|$m	|" >> "$out"
  done <<EOF
$(verified_cites "$f")
EOF
  [ -s "$out" ] || return 0
  emit STALE-CITE "$f" "$(sort -u "$out" | awk -F'\t' -v since="$CITE_DATE" '
    { b = $1; sub(/.*\//, "", b); r[b] = r[b] (r[b] == "" ? "" : ",") $2; if ($3 == "changed") { c++; ch[b] = 1 } else m++; if (!(b in seen)) { seen[b] = ++k; ord[k] = b } }
    END {
      for (i = 1; i <= k; i++) if (ord[i] in ch) l = l (l == "" ? "" : "; ") ord[i] ":" r[ord[i]]; else mv++
      printf "%d changed + %d moved cited ranges since %s — changed: %s%s — re-verify", c, m, since, (l == "" ? "none" : l), (mv ? "; moved only: " mv " files" : "")
    }')"
}

check_review() {
  case "$(status_norm "$2")" in "READY TO BUILD"|"IN PROGRESS"|DONE) ;; *) return 0 ;; esac
  case "$(refine_critic "$1")" in
    none) emit NO-REVIEW "$1" "Status '${2%% —*}' but no ## Refine section naming a Critic" ;;
    empty) emit NO-REVIEW "$1" "Status '${2%% —*}' but ## Refine names no Critic" ;;
    pending) emit NO-REVIEW "$1" "Status '${2%% —*}' but Critic is pending" ;;
    *) [ "$(refine_pass "$1")" = negative ] && emit NO-REVIEW "$1" "Status '${2%% —*}' but Refine Pass is negative"
       depth_full "$1" && ! refine_steps "$1" &&
         emit REFINE-STEPS "$1" "Full-depth Refine names a Critic but records no step coverage (Steps: a–g)" ;;
  esac
}

check_git() {
  local f="$1" status="$2" cls="$3" entries="$4" dh="$5" date anchor="" label="" last
  date="$(spec_date "$f")"
  last="$(git log -1 --format=%H -- "$f" 2>/dev/null)"
  [ -n "$date" ] || date="$(git log -1 --format=%cs -- "$f" 2>/dev/null)"
  [ -n "$dh" ] || for label in "Verified at" Baseline; do
    if [ "$label" = Baseline ]; then anchor="$(baseline_sha "$f")"; else anchor="$(header "$label" "$f" | grep -oE '[0-9a-f]{7,40}' | head -1)"; fi
    [ -n "$anchor" ] && git cat-file -e "$anchor^{commit}" 2>/dev/null && break
    anchor=""
  done
  [ -n "$anchor" ] && date="$(git show -s --format=%cs "$anchor")"
  [ "$cls" = open ] && [ -n "$date" ] && [ -n "$entries" ] && check_status_shipped "$f" "$date" "$entries" "$anchor"

  if [ -n "$entries" ]; then
    if [ -n "$anchor" ]; then check_drift "$f" "$anchor" "$label" "$entries"
    elif [ -z "$dh" ] && [ "$cls" = "done" ] && [ -n "$last" ] && [ "$STALE_FALLBACK" = 1 ]; then check_drift "$f" "$last" "spec last commit" "$entries"; fi
    [ -n "$date" ] && check_repeat_fix "$f" "$date" "$entries"
  fi
  [ -n "$date" ] && check_cites "$f" "$date" "${anchor:-$(base_before "$ROOT" "$date")}"
  check_contract "$f" "$cls" "$entries"
  check_unmerged "$f" "$cls" "$status"
}

check_spec() {
  local f="$1" status cls entries n dh
  if [ -n "$TOUCHING" ]; then touches "$f" "$(entries_of "$f")" || return 1; fi
  [ "$NOGIT" = 1 ] && emit NO-GIT "$f" "$(tilde_path "$ROOT") is not in a git repo — git-based checks skipped; anchor with --dir-hash"
  if is_pointer "$f"; then check_pointer "$f"; [ -n "$POLICY_FILE" ] && policy_check_words "$f"; return 0; fi
  status="$(status_of "$f")"; cls="$(status_class "$status")"
  [ -n "$status" ] || emit NO-STATUS "$f" "no **Status:** header"
  [ -n "$status" ] && [ -z "$(status_norm "$status")" ] &&
    emit STATUS-ENUM "$f" "'$(printf '%s' "$status" | cut -c1-40)' — lead with SPEC | READY TO BUILD | IN PROGRESS | DONE, note after ' — '"
  if [ "$cls" = "done" ]; then
    n="$(unchecked_acs "$f")"
    [ "$n" -gt 0 ] && emit STATUS-OPEN "$f" "Status '${status%% —*}' but $n unchecked acceptance criteria"
  fi
  n="$(open_count "$f")"
  [ "$n" -gt 3 ] && emit OPEN-CAP "$f" "$n OPEN (max 3) — decide the rest as ASSUMED with reasoning (core step 5)"
  entries="$(entries_of "$f")"; dh="$(dirhash_anchor "$f")"
  [ -n "$dh" ] && check_dirhash "$f" "$dh" "$entries"
  [ "$NOGIT" = 1 ] || check_git "$f" "$status" "$cls" "$entries" "$dh"
  check_review "$f" "$status"
  policy_check_spec "$f" "$status"
  return 0
}

if [ "$DIRHASH" = 1 ]; then
  [ -n "$ONE" ] || { echo "spec-check: --dir-hash needs --spec FILE" >&2; exit 2; }
  h="$(dir_hash "$ROOT" "$(entries_of "$ONE")")" || { [ $? = 3 ] && echo "spec-check: no covered file of $ONE exists under $ROOT" >&2; exit 2; }
  echo "dir-hash $h root $(tilde_path "$ROOT")"; exit 0
fi

count=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  check_spec "$f" && count=$((count + 1))
done <<EOF
$SPEC_FILES
EOF

total="$(wc -l < "$FINDINGS" | tr -d ' ')"
[ -n "$TOUCHING" ] && [ "$count" = 0 ] && exit 0
by_kind="$(sort "$FINDINGS" | uniq -c | awk '{ printf "%s%s %s", (NR > 1 ? ", " : ""), $1, $2 }')"
echo "spec-check: $count specs, $total findings${by_kind:+ ($by_kind)}"
[ "$count" -gt 0 ] || echo "spec-check: no specs found under ${SPEC_DIRS:-.claude/specs .agents/specs}"
[ "$STRICT" = 1 ] && [ "$total" -gt 0 ] && exit 1
exit 0
