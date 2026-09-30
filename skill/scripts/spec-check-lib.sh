# shellcheck shell=bash
# Sourced by spec-check.sh. Needs: ROOT, TMP, REPOMAP (lines "alias<TAB>abs path").

spec_scan_dir() {
  local dir="$1" probe canonical
  while [ "${dir#./}" != "$dir" ]; do dir="${dir#./}"; done
  case "$dir" in
    ''|/*|-*|*$'\n'*|*$'\r'*) echo "invalid specs.path: $1" >&2; return 2 ;;
  esac
  case "/$dir/" in
    *'/../'*|*'/./'*) echo "invalid specs.path: $1" >&2; return 2 ;;
  esac
  probe="$dir"
  while [ ! -e "$probe" ] && [ ! -L "$probe" ]; do probe="$(dirname "$probe")"; done
  canonical="$(cd "$probe" 2>/dev/null && pwd -P)" || { echo "invalid specs.path: $1" >&2; return 2; }
  if [ -d "$dir" ] && [ "$canonical" = "$ROOT" ]; then
    echo "invalid specs.path: $1" >&2; return 2
  fi
  case "$canonical" in
    "$ROOT"|"$ROOT"/*) ;;
    *) echo "invalid specs.path: $1" >&2; return 2 ;;
  esac
  if [ -d "$dir" ]; then printf './%s\n' "${canonical#"$ROOT"/}"
  else printf './%s\n' "$dir"; fi
}

spec_scan_dirs() {
  local p="$1" d
  if [ -n "$p" ]; then
    d="${p%%\{*}"; d="${d%/}"
    spec_scan_dir "$d"
  else
    for d in .claude/specs .agents/specs; do spec_scan_dir "$d" || return 2; done
  fi
}

spec_list_files() {
  local d f raw="$TMP/spec-paths.raw"
  : > "$raw" || return 2
  while IFS= read -r d; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    find "$d" -type f \( -name 'spec.md' -o -name 'spec-*.md' -o -name '*-spec.md' \) -print0 >> "$raw" || { echo "cannot scan spec directory: $d" >&2; return 2; }
  done <<EOF
$1
EOF
  while IFS= read -r -d '' f; do
    case "$f" in *$'\n'*|*$'\r'*|*$'\t'*) echo 'unsupported spec path (newline, CR, or tab)' >&2; return 2 ;; esac
    printf '%s\n' "${f#./}"
  done < "$raw"
}

AWK_PATHLIKE='
function pathlike(p) {
  if (p == "" || p ~ /[ \t()=;'"'"'"@,|]/ || p ~ /^(\/|~|\$|-|https?:)/ || p ~ /^\.[^\/.]*\.[^\/]*$/) return 0
  if (p ~ /\/$/ || (index(p, "*") && p ~ /[A-Za-z0-9]/)) return 1
  return (index(p, "/") && known_dir(p)) || known_ext(p)
}
function explicit_path(p) {
  if (p == "" || p ~ /[ \t()=;'"'"'"@,|]/ || p ~ /^(\/|~|\$|-|https?:)/ || p ~ /(^|\/)\.\.?($|\/)/) return 0
  return p ~ /^[A-Za-z0-9_.+-]+(\/[A-Za-z0-9_.+*{}<>-]+)*\/?$/
}
function load_known(   l) { if (!kl) { kl = 1; while ((getline l < known) > 0) K[l] = 1; close(known) } }
function known_ext(p,   b) {
  b = p; sub(/.*\//, "", b)
  if (b !~ /^[^.]+(\.[^.]+)*\.[A-Za-z0-9_+-]+$/) return 0
  load_known(); sub(/.*\./, "", b); return ("e\t" b) in K
}
function known_dir(p,   d) { d = p; sub(/\/.*/, "", d); load_known(); return ("d\t" d) in K }
function norm(p) { gsub(/\{[^}]*\}/, "*", p); gsub(/<[^>]*>/, "*", p); sub(/^\.\//, "", p); return p }
function isalias(w) { return index(" " aliases " ", " " tolower(w) " ") > 0 }
function lastword(s,   m) {
  if (match(s, /[A-Za-z0-9_.-]+[ \t]*$/)) { m = substr(s, RSTART, RLENGTH); sub(/[ \t]+$/, "", m); return m }
  return ""
}
function emit_token(t, qual, force,   q, rest, parts, n, r) {
  r = ""
  if (match(t, /^[A-Za-z0-9_.-]+@[0-9a-fA-F]+:/)) { q = substr(t, 1, index(t, "@") - 1); t = substr(t, RLENGTH + 1); qual = q }
  n = split(t, parts, ":")
  if (n >= 2 && parts[1] !~ /\// && !pathlike(parts[1]) && parts[2] !~ /^~?[0-9]/) {
    qual = parts[1]; t = substr(t, length(parts[1]) + 2); n = split(t, parts, ":")
  }
  if (n >= 2 && parts[2] ~ /^~?[0-9]/) { r = substr(t, length(parts[1]) + 2); t = parts[1] }
  if (r ~ /^~/) r = ""
  gsub(/ /, "", r)
  if (r !~ /^[0-9][0-9,-]*$/) r = ""
  t = norm(t)
  if (pathlike(t) || (force && explicit_path(t))) print (qual == "" ? "-" : qual) "\t" t "\t" (r == "" ? "-" : r)
}
function scan_cell(cell, sticky,   parts, n, i, w, qual) {
  qual = sticky
  n = split(cell, parts, "`")
  if (n == 1) {
    if (!bare) return qual
    n = split(cell, parts, /[ ,+]+/)
    for (i = 1; i <= n; i++) emit_token(parts[i], qual)
    return qual
  }
  for (i = 1; i <= n; i++) {
    if (i % 2 == 1) { w = lastword(parts[i]); if (w != "" && isalias(w)) qual = tolower(w) }
    else emit_token(parts[i], qual, explicit && i == 2)
  }
  return qual
}
'

blast_entries() {
  awk -v bare=1 -v known="$(known_file)" -v aliases="$(alias_list)" "$AWK_PATHLIKE"'
    function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inb && lvl($0) <= bl) inb = 0
      if (!inb && tolower($0) ~ /blast radius/) { inb = 1; bl = lvl($0) }
      next
    }
    !inb { next }
    /^[ \t]*\|/ {
      line = $0; sub(/^[ \t]*\|/, "", line); cell = ""; bt = 0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == "`") bt = !bt
        if (c == "|" && !bt) break
        cell = cell c
      }
      if (cell ~ /^[ \t:-]*$/ || tolower(cell) ~ /^[ \t]*file[s]?[ \t]*$/) next
      scan_cell(cell, "")
      next
    }
    /^[ \t]*([-*]|[0-9]+\.)[ \t]/ { if (index($0, "`")) scan_cell($0, "") }
  ' "$1" | sort -u
}

changes_entries() {
  awk -v explicit=1 -v known="$(known_file)" -v aliases="$(alias_list)" "$AWK_PATHLIKE"'
    function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inc && lvl($0) <= cl) inc = 0
      h = tolower($0); sub(/^#+[ \t]+/, "", h); sub(/[ \t\r]+$/, "", h)
      if (!inc && h == "changes") { inc = 1; cl = lvl($0) }
      next
    }
    inc && /^[ \t]*([-*][ \t]+)?\**(ADDED|MODIFIED|REMOVED|RENAMED)\**:/ { scan_cell($0, "") }
  ' "$1" | sort -u
}

covers_entries() {
  local v; v="$(header "Covers" "$1")"
  [ -n "$v" ] || return 0
  printf '%s\n' "$v" | tr ',' '\n' | awk -v known="$(known_file)" -v aliases="$(alias_list)" "$AWK_PATHLIKE"'
    { gsub(/`/, ""); gsub(/^[ \t]+|[ \t\r]+$/, ""); if ($0 != "") emit_token($0, "") }' | sort -u
}

verified_cites() {
  awk -v known="$(known_file)" -v aliases="$(alias_list)" "$AWK_PATHLIKE"'
    /(^|[^A-Za-z])VERIFIED/ && !/NOT VERIFIED/ && index($0, "`") {
      n = split($0, cells, "|"); q = ""
      for (k = 1; k <= n; k++) q = scan_cell(cells[k], q)
    }' "$1" | sort -u
}

header() {
  awk -v k="$1" 'index($0, "**" k ":**") { sub(/.*\*\*[^*]+:\*\*[ \t]*/, ""); print; exit }' "$2"
}

status_of() {
  local s; s="$(header "Status" "$1")"
  [ -n "$s" ] || s="$(awk 'NR > 25 { exit } {
      l = $0; gsub(/\*/, "", l); sub(/^[ \t|#]+/, "", l)
      if (match(l, /^([A-Za-z]+ )?[Ss]tatus[ \t]*[:|][ \t]*/)) { l = substr(l, RLENGTH + 1); sub(/[ \t|]+$/, "", l); if (l != "") { print l; exit } }
    }' "$1")"
  printf '%s' "$s"
}

status_norm() {
  local s; s="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]' | sed -E 's/^[^A-Z]*//; s/[[:space:]]*(—|--| - |\(|;|,).*//; s/[[:space:]]+$//')"
  case "$s" in
    DONE|IMPLEMENTED|SHIPPED|COMPLETE|BUILT|MERGED|DEPLOYED|LIVE) echo DONE ;;
    "IN PROGRESS"|IN-PROGRESS|WIP|BUILDING) echo "IN PROGRESS" ;;
    "READY TO BUILD"|READY|APPROVED) echo "READY TO BUILD" ;;
    SPEC|DRAFT) echo SPEC ;;
    SUPERSEDED|"SUPERSEDED BY "*|ABANDONED|CANCELLED|CANCELED|WONTFIX) echo CLOSED ;;
  esac
}

status_class() {
  case "$(status_norm "$1")" in
    DONE) echo "done" ;;
    "IN PROGRESS"|"READY TO BUILD") echo open ;;
    *) echo other ;;
  esac
}

refine_critic() {
  awk 'function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inr && lvl($0) <= rl) inr = 0
      h = tolower($0); sub(/^#+[ \t]+/, "", h)
      if (!inr && h ~ /^refine([^a-z]|$)/) { inr = 1; rl = lvl($0); seen = 1 }
      next
    }
    inr && match($0, /[Cc]ritics?\**:/) {
      v = substr($0, RSTART + RLENGTH); gsub(/<[^>]*>/, "", v); sub(/^[^A-Za-z0-9]+/, "", v)
      if (tolower(v) ~ /^(pending|unapproved|not[ \t-]*approved|awaiting[ \t-]*review|review[ \t-]*pending)([^a-z]|$)/) { pending = 1; exit }
      gsub(/<[^>]*>|[*`_.,;:()\[\]|-]|—|[ \t\r]/, "", v)
      if (v != "" && tolower(v) !~ /^(none|tbd|todo|n\/?a)$/) { ok = 1; exit }
    }
    END { print (ok ? "ok" : (pending ? "pending" : (seen ? "empty" : "none"))) }' "$1"
}

refine_pass() {
  awk 'function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inr && lvl($0) <= rl) inr = 0
      h = tolower($0); sub(/^#+[ \t]+/, "", h)
      if (!inr && h ~ /^refine([^a-z]|$)/) { inr = 1; rl = lvl($0) }
      next
    }
    inr && match($0, /[Pp]ass\**:/) {
      v = tolower(substr($0, RSTART + RLENGTH)); gsub(/^[*`_ \t]+/, "", v)
      if (v ~ /^(no|fail|failed|blocked|pending)([^a-z]|$)/) { print "negative"; exit }
    }' "$1"
}

unchecked_acs() {
  awk 'function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inac && lvl($0) <= al) inac = 0
      if (!inac && tolower($0) ~ /acceptance|criteria|definition of done|done when/) { inac = 1; al = lvl($0) }
      next
    }
    inac && /^[ \t]*[-*] \[ \]/ && tolower($0) !~ /out of scope/ { n++ }
    END { print n + 0 }' "$1"
}

spec_date() {
  header "Date" "$1" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1
}

baseline_sha() {
  awk '/Baseline/ && /:/ { sub(/.*Baseline[^:]*:/, ""); if (match($0, /[0-9a-f]{7,40}/)) { print substr($0, RSTART, RLENGTH); exit } }' "$1"
}

known_file() {
  local f="$TMP/known" r
  [ -f "$f" ] && { echo "$f"; return; }
  for r in "$ROOT" $(other_repos); do cat "$(list_files "$r" "")"; done |
    awk '{ n = split($0, s, "/"); for (i = 1; i < n; i++) print "d\t" s[i]
      if (match(s[n], /\.[^.]+$/) && RSTART > 1) print "e\t" substr(s[n], RSTART + 1) }' | sort -u > "$f"
  echo "$f"
}

alias_list() {
  printf '%s\n' "$REPOMAP" | awk -F'\t' 'NF { printf "%s ", tolower($1) }'
}

resolve_repo() {
  local a; a="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  [ -n "$a" ] || { echo "$ROOT"; return 0; }
  local hit; hit="$(printf '%s\n' "$REPOMAP" | awk -F'\t' -v a="$a" 'tolower($1) == a { print $2; exit }')"
  if [ -n "$hit" ]; then echo "$hit"; return 0; fi
  [ "$a" = "$(basename "$ROOT" | tr '[:upper:]' '[:lower:]')" ] && { echo "$ROOT"; return 0; }
  sibling_repo "$1"
}

sibling_repo() {
  local d="$ROOT/../$1"
  [ -n "$1" ] && [ "$1" != "." ] && [ "$1" != ".." ] && [ -d "$d" ] || return 1
  d="$(cd "$d" && pwd)"
  [ "$(git -C "$d" rev-parse --show-toplevel 2>/dev/null)" = "$d" ] && echo "$d"
}

other_repos() {
  printf '%s\n' "$REPOMAP" | awk -F'\t' -v r="$ROOT" 'NF && $2 != r && !seen[$2]++ { print $2 }'
}

key_of() { printf '%s' "$*" | cksum | awk '{ print $1 }'; }

def_branch() {
  local b
  b="$(git -C "$1" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)" && { echo "$b"; return; }
  for b in main master; do git -C "$1" rev-parse -q --verify "$b" >/dev/null && { echo "$b"; return; }; done
  echo HEAD
}

list_files() {
  local f
  f="$TMP/ls-$(key_of "$1" "$2")"
  if [ ! -f "$f" ]; then
    if [ -z "$2" ]; then git -C "$1" ls-files > "$f" 2>/dev/null
    else git -C "$1" ls-tree -r --name-only "$2" > "$f" 2>/dev/null; fi
  fi
  echo "$f"
}

find_path() {
  local list; list="$(list_files "$1" "$3")"
  if [ "$4" = exact ]; then grep -qxF -- "$2" "$list" && echo "$2"; return; fi
  local hits; hits="$(awk -v s="/$2" 'length($0) > length(s) && substr($0, length($0) - length(s) + 1) == s' "$list")"
  [ -n "$hits" ] || return 1
  [ "$(printf '%s\n' "$hits" | wc -l | tr -d ' ')" = 1 ] && { echo "$hits"; return 0; }
  echo AMBIGUOUS
}

cite_base() {
  if [ "$1" = "$ROOT" ] && [ -n "$CITE_ANCHOR" ]; then echo "$CITE_ANCHOR"; else base_before "$1" "$CITE_DATE"; fi
}

locate() {
  local mode="$1" p="$2" r t m pass hits
  shift 2
  for pass in exact suffix; do
    hits=""
    for r in "$@"; do
      t=""
      if [ "$mode" = base ]; then t="$(cite_base "$r")"; [ -n "$t" ] || continue; fi
      m="$(find_path "$r" "$p" "$t" "$pass")" || continue
      hits="$hits$r	$m"$'\n'
    done
    [ -n "$hits" ] && break
  done
  [ -n "$hits" ] || return 1
  if [ "$(printf '%s' "$hits" | wc -l | tr -d ' ')" = 1 ] && [ "${hits#*	}" != "AMBIGUOUS"$'\n' ]; then printf '%s' "${hits%$'\n'}"; else echo AMBIGUOUS; fi
}

base_before() {
  git -C "$1" rev-list -1 --before="$2 00:00:00" HEAD 2>/dev/null
}

pathspecs() {
  local p="$1"
  case "$p" in */) p="${p}**" ;; esac
  case "$p" in
    */*) printf '%s\n' ":(glob)$p" ":(glob)**/$p" ;;
    *) printf '%s\n' ":(glob)**/$p" ;;
  esac
}

range_status() {
  awk -v ranges="$2" '
    /^@@/ {
      split($2, o, ","); split($3, nw, ",")
      a = substr(o[1], 2) + 0; b = (o[2] == "" ? 1 : o[2] + 0); d = (nw[2] == "" ? 1 : nw[2] + 0)
      h++; A[h] = a; B[h] = b; D[h] = d
    }
    END {
      n = split(ranges, R, ",")
      for (i = 1; i <= n; i++) {
        split(R[i], lm, "-"); L = lm[1] + 0; M = (lm[2] == "" ? L : lm[2] + 0)
        ch = 0; sh = 0
        for (j = 1; j <= h; j++) {
          if (B[j] > 0) { e = A[j] + B[j] - 1; if (A[j] <= M && e >= L) ch = 1; else if (e < L) sh += D[j] - B[j] }
          else { if (A[j] >= L && A[j] < M) ch = 1; else if (A[j] < L) sh += D[j] }
        }
        if (ch) print R[i] "\tchanged"
        else if (sh != 0) print R[i] "\tmoved"
      }
    }' "$1"
}

date_plus() {
  awk -v d="$1" -v n="$2" '
    function dfc(y, m, dd,   era, yoe, doy) { y -= (m <= 2); era = int((y >= 0 ? y : y - 399) / 400); yoe = y - era * 400
      doy = int((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5) + dd - 1; return era * 146097 + yoe * 365 + int(yoe / 4) - int(yoe / 100) + doy - 719468 }
    function cfd(z,   era, doe, yoe, y, doy, mp, dd, m) { z += 719468; era = int((z >= 0 ? z : z - 146096) / 146097); doe = z - era * 146097
      yoe = int((doe - int(doe / 1460) + int(doe / 36524) - int(doe / 146096)) / 365); y = yoe + era * 400
      doy = doe - (365 * yoe + int(yoe / 4) - int(yoe / 100)); mp = int((5 * doy + 2) / 153); dd = doy - int((153 * mp + 2) / 5) + 1
      m = mp + (mp < 10 ? 3 : -9); return sprintf("%04d-%02d-%02d", y + (m <= 2), m, dd) }
    BEGIN { split(d, p, "-"); print cfd(dfc(p[1] + 0, p[2] + 0, p[3] + 0) + n) }'
}

is_fix_subject() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | grep -qE '(^|[^a-z])(fix|fixes|fixed|hotfix|revert|reverts)([^a-z]|$)'
}

entry_matches() {
  local p="$1" t="$2"
  case "$p" in */) p="$p*" ;; esac
  # shellcheck disable=SC2254
  case "$t" in $p|*/$p) return 0 ;; esac
  return 1
}

open_count() {
  awk 'function lvl(s) { match(s, /^#+/); return RLENGTH }
    { sub(/\r$/, "") }
    match($0, /^[ \t]*(```|~~~)/) { c = substr($0, RSTART + RLENGTH - 3, 3); if (fence == "") { fence = c; next } if (c == fence) { fence = ""; next } }
    fence != "" { next }
    /^#+ / {
      if (skip && lvl($0) <= sl) skip = 0
      h = tolower($0); sub(/^#+[ \t]+/, "", h)
      if (!skip && h ~ /^(refine|corrections log)([^a-z]|$)/) { skip = 1; sl = lvl($0) }
      next
    }
    skip { next }
    { l = $0; gsub(/``[^`]*``/, "", l); gsub(/`[^`]*`/, "", l); if (l ~ /(^|[^A-Za-z0-9_-])OPEN([^A-Za-z0-9_-]|-[A-Z]?[0-9]|$)/) n++ }
    END { print n + 0 }' "$1"
}

depth_full() {
  awk '/^[ \t]*\*\*Depth:\*\*/ { v = tolower($0); sub(/^[ \t]*\*\*depth:\*\*/, "", v); sub(/^[^a-z0-9]+/, "", v)
      f = (v ~ /^(full|tier[ -]?[2-4])([^a-z0-9]|$)/); exit }
    END { exit !f }' "$1"
}

refine_steps() {
  awk 'function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inr && lvl($0) <= rl) inr = 0
      h = tolower($0); sub(/^#+[ \t]+/, "", h)
      if (!inr && h ~ /^refine([^a-z]|$)/) { inr = 1; rl = lvl($0) }
      next
    }
    !inr { next }
    /(^|[^A-Za-z0-9_])[aA](–|-)[gG]([^A-Za-z0-9_]|$)/ { ok = 1; exit }
    match($0, /[Ss]teps\**:/) {
      v = substr($0, RSTART + RLENGTH); sub(/\..*/, "", v); gsub(/[^A-Za-z]+/, " ", v); n = split(tolower(v), w, " "); s = ""
      for (i = 1; i <= n; i++) if (length(w[i]) == 1) s = s w[i]
      if (s ~ /a/ && s ~ /c/ && s ~ /d/ && s ~ /e/ && s ~ /f/ && s ~ /g/) { ok = 1; exit }
    }
    END { exit !ok }' "$1"
}

tilde_path() {
  local h
  for h in "${HOME:-}" "$(cd "${HOME:-/}" 2>/dev/null && pwd -P)"; do
    [ -n "$h" ] && [ "$h" != / ] || continue
    # shellcheck disable=SC2088 # prints a literal tilde
    case "$1" in "$h") echo '~'; return ;; "$h"/*) echo "~/${1#"$h"/}"; return ;; esac
  done
  printf '%s\n' "$1"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi
}

dir_hash() {
  local root="$1" q p f h found=0 out="$TMP/dirhash" list="$TMP/dirhash-files"
  command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 ||
    { echo "spec-check: dir-hash needs sha256sum or shasum" >&2; return 2; }
  : > "$out"
  while IFS='	' read -r q p _; do
    [ -n "$p" ] && [ "$q" = - ] || continue
    case "$p" in *\**) echo "spec-check: dir-hash skips glob entry $p" >&2; continue ;; esac
    if [ -d "$root/$p" ]; then
      (cd "$root" && find -H "./${p%/}" \( -name .git -o -name node_modules \) -prune -o -type f ! -name .DS_Store -print0) > "$list"
      while IFS= read -r -d '' f; do
        f="${f#./}"
        case "$f" in *$'\n'*|*$'\r'*|*$'\t'*) echo "spec-check: dir-hash skips unsupported path $f" >&2; continue ;; esac
        h="$(sha256_of < "$root/$f")"; printf '%s\t%s\n' "$f" "${h%% *}" >> "$out"; found=1
      done < "$list"
    elif [ -f "$root/$p" ]; then
      h="$(sha256_of < "$root/$p")"; printf '%s\t%s\n' "$p" "${h%% *}" >> "$out"; found=1
    else
      printf '%s\t-\n' "$p" >> "$out"
    fi
  done <<EOF
$2
EOF
  h="$(LC_ALL=C sort -u "$out" | sha256_of)"; echo "${h%% *}"
  [ "$found" = 1 ] || return 3
}

dirhash_anchor() {
  header "Verified at" "$1" | tr -d '`\r' | awk 'match($0, /^[ \t]*dir-hash([ \t]|$)/) {
    v = substr($0, RSTART + RLENGTH); sub(/^[ \t]+/, "", v); h = v; sub(/[ \t].*/, "", h); r = ""
    if (match(v, /[ \t]root[ \t]+/)) { r = substr(v, RSTART + RLENGTH); sub(/[ \t]+$/, "", r) }
    print h "\t" r }'
}

check_dirhash() {
  local f="$1" want="${2%%	*}" root="${2#*	}" have
  [ -n "$root" ] || root="$ROOT"
  case "$root" in "~") root="${HOME:-}" ;; "~"/*) root="${HOME:-}/${root#\~/}" ;; esac
  have="$(dir_hash "$root" "$3")"
  [ $? = 2 ] && return 0
  [ "${#want}" -ge 12 ] && case "$have" in "$want"*) return 0 ;; esac
  emit STALE "$f" "covered files under $(tilde_path "$root") differ from dir-hash $(printf '%s' "$want" | cut -c1-12) (Verified at) — re-verify, then refresh with --dir-hash"
}
