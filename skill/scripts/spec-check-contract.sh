# shellcheck shell=bash
# Sourced by spec-check.sh after spec-check-lib.sh. Needs: ROOT, TMP, emit, REF_CAP, FIELD_WINDOW.
# Heuristic, advisory, language-neutral: evidence is the literal route string in any tracked non-doc file; path
# params match `{x}` `:x` `<x>` `[x]` `${x}` `#{x}` `$x` `%s` `\(x)` or a `" +` concatenation; roles come only from the
# Producer / Consumers columns. CONTRACT-FIELDS needs both columns; rows without roles only get CONTRACT-MISSING over
# the spec's repo and the repos in Changes. Known false-positive modes:
#   CONTRACT-MISSING  routes assembled from tokens (`[controller]`, class-level prefixes split before a literal
#                     segment), generated clients, OpenAPI codegen.
#   CONTRACT-FIELDS   the consumer reads the field through a named type declared more than FIELD_WINDOW lines
#                     from the call (types file, generated schema), a generic spread/passthrough, or a mapper;
#                     a field the spec lists as request-only that the consumer sends from elsewhere.
#   UNMERGED          ADDED paths that moved or were renamed on the default branch.

CONTRACT_EXCLUDES=':(exclude)*.md
:(exclude)*.mdx
:(exclude)*.txt
:(exclude)*.rst
:(exclude)*.adoc'

contract_rows() {
  awk '
    function lvl(s) { match(s, /^#+/); return RLENGTH }
    function add(list, v) { return index("," list ",", "," v ",") ? list : (list == "" ? v : list "," v) }
    function cells(line, out,   n, i, c, cell, bt) {
      sub(/^[ \t]*\|/, "", line); n = 0; cell = ""; bt = 0
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == "`") bt = !bt
        if (c == "|" && !bt) { out[++n] = cell; cell = ""; continue }
        cell = cell c
      }
      if (cell ~ /[^ \t]/) out[++n] = cell
      return n
    }
    function idents(s, acc,   parts, n, i, t) {
      n = split(s, parts, "`")
      for (i = 2; i <= n; i += 2) { t = parts[i]; if (t ~ /^[A-Za-z][A-Za-z0-9]*([_-][A-Za-z0-9]+)*$/) acc = add(acc, t) }
      return acc
    }
    function repos(s, acc,   parts, n, i, t) {
      gsub(/`/, "", s); n = split(tolower(s), parts, /[ \t,;+\/&]+/)
      for (i = 1; i <= n; i++) { t = parts[i]; if (t != "" && t != "and" && t != "-") acc = add(acc, t) }
      return acc
    }
    function merge(a, b,   parts, n, i) { n = split(b, parts, ","); for (i = 1; i <= n; i++) if (parts[i] != "") a = add(a, parts[i]); return a }
    function scan(s, fields, prods, cons,   m, meth, p, k) {
      while (match(s, /(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)[ \t]+\/[A-Za-z0-9_.\/{}:<>$\[\]-]*/)) {
        m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
        meth = m; sub(/[ \t].*/, "", meth)
        p = m; sub(/^[A-Z]+[ \t]+/, "", p); sub(/[.:]+$/, "", p)
        k = meth " " p
        if (!(k in F)) { order[++no] = k; F[k] = ""; P[k] = ""; C[k] = "" }
        F[k] = merge(F[k], fields); P[k] = merge(P[k], prods); C[k] = merge(C[k], cons)
      }
    }
    /^#+ / {
      if (inc && lvl($0) <= cl) inc = 0
      if (!inc && tolower($0) ~ /contract/) { inc = 1; cl = lvl($0) }
      hdr = 0; next
    }
    !inc { next }
    /^[ \t]*\|/ {
      n = cells($0, row)
      if (n && row[1] ~ /^[ \t:-]*$/) next
      if (!hdr) {
        hdr = 1; fcol = pcol = ccol = 0
        for (i = 1; i <= n; i++) {
          h = tolower(row[i])
          if (h ~ /field/ && !fcol) fcol = i
          if (h ~ /producer/) pcol = i
          if (h ~ /consumer/) ccol = i
        }
        if (fcol || pcol || ccol) next
      }
      prods = pcol ? repos(row[pcol], "") : ""; cons = ccol ? repos(row[ccol], "") : ""
      for (i = 1; i <= n; i++) {
        if (i == pcol || i == ccol || row[i] !~ /(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)[ \t]+\//) continue
        scan(row[i], idents(fcol ? row[fcol] : row[i], ""), prods, cons)
      }
      next
    }
    { hdr = 0; if ($0 ~ /(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)[ \t]+\//) scan($0, idents($0, ""), "", "") }
    END { for (i = 1; i <= no; i++) { k = order[i]; print k "\t" (F[k] == "" ? "-" : F[k]) "\t" (P[k] == "" ? "-" : P[k]) "\t" (C[k] == "" ? "-" : C[k]) } }
  ' "$1"
}

ere_escape() { printf '%s' "$1" | sed 's/[][\.*^$+?(){}|]/\\&/g'; }

PARAM_RX='\$\{[^}]*\}|#?\{[^}/]*\}|:[A-Za-z_][A-Za-z0-9_]*|<[^>/]+>|\[[^]/]+\]|\$[A-Za-z_][A-Za-z0-9_]*|%[a-z]|\\\([^)]*\)'
QUOTE='["'"'"'`]'

path_rx() {
  printf '%s\n' "$1" | tr '/' '\n' | while IFS= read -r s; do
    case "$s" in [\[\{:\<\$]*) printf '(%s)\n' "$PARAM_RX" ;; *) printf '%s\n' "$(ere_escape "$s")" ;; esac
  done | paste -sd/ -
}

lead_rx() { case "$1" in /*) printf '(/|%s)%s' "$QUOTE" "$(ere_escape "${1#/}")" ;; *) ere_escape "$1" ;; esac; }

ep_patterns() {
  local ep="$1" role="$2" rest="" rem="" tail stail stem segs n i sfx q nxt
  case "$ep" in
    *[\[\{:\<\$]*)
      rest="$(printf '%s' "$ep" | sed -E 's#^[^[{:<$]*/[[{:<$][^/]*##')"
      rem="$(printf '%s' "$ep" | sed -E 's#^[^[{:<$]*/##')"
      ep="$(printf '%s' "$ep" | sed -E 's#/[[{:<$].*#/#')"
      nxt="$(printf '%s' "${rest#/}" | sed -E 's#/.*##')"
      case "$nxt" in ''|[\[\{:\<\$]*) nxt='([^A-Za-z0-9_/-]|$)'; [ -n "$rest" ] && nxt=/ ;; *) nxt="/$(ere_escape "$nxt")" ;; esac
      tail='(('"$PARAM_RX"')'"$nxt"'|'"$QUOTE"'[[:space:]]*\+)'
      stail="$tail" ;;
    *) tail='([^A-Za-z0-9_/-]|$)'; stail='["'"'"'`?]' ;;
  esac
  stem="${ep#/api}"
  printf '%s%s\n' "$(lead_rx "$ep")" "$tail"
  [ "$stem" != "$ep" ] && [ -n "${stem#/}" ] && printf '%s%s\n' "$(lead_rx "$stem")" "$tail"
  segs="$(printf '%s' "$stem" | tr '/' '\n' | awk 'NF')"
  n="$(printf '%s\n' "$segs" | awk 'NF { c++ } END { print c + 0 }')"
  i=1
  while [ "$i" -lt "$n" ]; do
    sfx="$(printf '%s\n' "$segs" | tail -n "$i" | paste -sd/ -)"
    case "$ep" in */) sfx="$sfx/" ;; esac
    q='["'"'"'`}]/'; [ "$i" -gt 1 ] && q='["'"'"'`}]/?'
    [ "$i" = 1 ] && [ "$role" != producer ] && q='\}/'
    printf '%s%s%s\n' "$q" "$(ere_escape "$sfx")" "$stail"
    i=$((i + 1))
  done
  [ "$role" = producer ] && [ -n "$rest" ] && printf '%s' "$rem" | grep -q '/[^[{:<$]' &&
    printf '%s/?%s(%s|/|$)\n' "$QUOTE" "$(path_rx "$rem")" "$QUOTE"
  return 0
}

cap_refs() {
  local f
  f="$TMP/refs-$(key_of "$1")"
  [ -f "$f" ] || git -C "$1" for-each-ref --sort=-committerdate --format='%(objectname) %(refname:short)' refs/heads refs/remotes 2>/dev/null |
    awk -v cap="$REF_CAP" '$2 != "origin" && $2 !~ /\/HEAD$/ && !s[$1]++ && ++n <= cap { print $2 }' > "$f"
  echo "$f"
}

side_refs() {
  local repo="$1" d h hn
  d="$(def_branch "$repo")"; hn="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  h="$(git -C "$repo" rev-parse -q --verify HEAD 2>/dev/null)"
  if [ "$h" = "$(git -C "$repo" rev-parse -q --verify "$d" 2>/dev/null)" ]; then echo "$d	$d"
  else echo "$d	$d"; echo "HEAD	HEAD ($hn)"; fi
}

code_hits() {
  local repo="$1" pats="$2" ref_file ref file line content; shift 2
  (IFS=$'\n'; set -f; git -C "$repo" grep -I -z -n -E -f "$pats" "$@" -- . $CONTRACT_EXCLUDES 2>/dev/null) |
    while IFS= read -r -d '' ref_file && IFS= read -r -d '' line && IFS= read -r content; do
      case "$ref_file" in *:*) ref="${ref_file%%:*}"; file="${ref_file#*:}" ;; *) echo 'invalid git grep framing' >&2; return 2 ;; esac
      case "$line" in ''|*[!0-9]*) echo 'invalid git grep line number' >&2; return 2 ;; esac
      case "$file" in *$'\n'*|*$'\r'*|*$'\t'*) echo 'unsupported source path (newline, CR, or tab)' >&2; return 2 ;; esac
      printf '%s\t%s\t%s\t%s\n' "$ref" "$file" "$line" "$content"
    done | awk -F '\t' '{ c = $0; for (i = 1; i <= 3; i++) { j = index(c, "\t"); c = substr(c, j + 1) }
      if (c !~ /^[ \t]*(\/\/|\/?\*|\{\/\*|<!--|--[ \t]|#([^[!]|![^[]|$))/ || c ~ /^[ \t]*#(define|include|if|elif|region)[ \t]/) print $1 "\t" $2 "\t" $3 "\t" c }'
}

grep_refs() {
  local repo="$1" pats="$2" key; shift 2
  key="$TMP/grep-$(key_of "$repo" "$(cat "$pats")" "$@")"
  [ -f "$key" ] || code_hits "$repo" "$pats" "$@" | cut -f1 | sort -u > "$key"
  cat "$key"
}

join_list() { awk -v cap="${2:-3}" 'NF { n++; if (n <= cap) l = l (n > 1 ? ", " : "") $0 } END { if (n) print l (n > cap ? ", +" (n - cap) : "") }' "${1:--}"; }

declared_methods() {
  local repo="$1" path="$2" ref="$3" method rx pats="$TMP/method-pats" methods="" all_hits literal static uncertain
  case "$path" in *'{'*|*'}'*|*':'*|*'<'*|*'['*|*'$'*|*'%'*|*'*'*) return 0 ;; esac
  literal="${QUOTE}$(ere_escape "$path")${QUOTE}"
  printf '%s\n' "$literal" > "$pats"
  all_hits="$(code_hits "$repo" "$pats" "$ref")"
  [ -n "$all_hits" ] || return 0
  for method in GET POST PUT PATCH DELETE HEAD OPTIONS; do
    rx="(^|[^[:alnum:]_])(app|router)[[:space:]]*\\.[[:space:]]*$(printf '%s' "$method" | tr '[:upper:]' '[:lower:]')[[:space:]]*\\([[:space:]]*${QUOTE}$(ere_escape "$path")${QUOTE}"
    printf '%s\n' "$rx" > "$pats"
    [ -n "$(code_hits "$repo" "$pats" "$ref")" ] && methods="$methods${methods:+$'\n'}$method"
  done
  [ -n "$methods" ] || return 0
  static="(^|[^[:alnum:]_])(app|router)[[:space:]]*\\.[[:space:]]*(get|post|put|patch|delete|head|options)[[:space:]]*\\([[:space:]]*$literal"
  uncertain="$(printf '%s\n' "$all_hits" | SPEC_LITERAL_RX="$literal" SPEC_STATIC_RX="$static" awk -F '\t' 'BEGIN { p = ENVIRON["SPEC_LITERAL_RX"]; s = ENVIRON["SPEC_STATIC_RX"] }
    { c = $0; for (i = 1; i <= 3; i++) { j = index(c, "\t"); c = substr(c, j + 1) }
    a = c; b = c; if (gsub(p, "", a) != gsub(s, "", b)) { print 1; exit } }')"
  [ -n "$uncertain" ] || printf '%s\n' "$methods"
}

presence() {
  local repo="$1" path="$2" role="$3" cls="$4" method="$5" pats="$TMP/pats" miss="" mismatch="" ok=0 total=0 ref label hits branches methods
  ep_patterns "$path" "$role" > "$pats"
  while IFS='	' read -r ref label; do
    total=$((total + 1))
    if [ -n "$(grep_refs "$repo" "$pats" "$ref")" ]; then
      methods=""
      [ "$role" = producer ] && methods="$(declared_methods "$repo" "$path" "$ref")"
      if [ -z "$methods" ] || printf '%s\n' "$methods" | grep -qxF -- "$method"; then
        ok=$((ok + 1)); continue
      fi
      mismatch="$mismatch${mismatch:+, }$label declares $(printf '%s\n' "$methods" | paste -sd/ -)"
    fi
    miss="$miss${miss:+ + }$label"
  done <<EOF
$(side_refs "$repo")
EOF
  [ "$ok" = "$total" ] && return 0
  [ "$ok" -gt 0 ] && { printf '%s: missing on %s%s' "$(basename "$repo")" "$miss" "${mismatch:+; $mismatch}"; return 0; }
  [ -n "$mismatch" ] && { printf '%s: missing on %s; %s' "$(basename "$repo")" "$miss" "$mismatch"; return 0; }
  # shellcheck disable=SC2046 # deliberate split of ref names into args
  hits="$(grep_refs "$repo" "$pats" $(cat "$(cap_refs "$repo")"))"
  if [ -n "$hits" ]; then branches="$(printf '%s\n' "$hits" | join_list - 3)"
    printf '%s: missing on %s, only on %s' "$(basename "$repo")" "$miss" "$branches"
  elif [ "$cls" = "done" ]; then printf '%s: missing everywhere (last %s refs)' "$(basename "$repo")" "$REF_CAP"; fi
}

field_regex() {
  local s c
  s="$(printf '%s' "$1" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]-' '[:lower:]_')"
  c="$(printf '%s' "$s" | awk -F_ '{ o = $1; for (i = 2; i <= NF; i++) o = o toupper(substr($i, 1, 1)) substr($i, 2); print o }')"
  printf '(^|[^A-Za-z0-9_-])(%s|%s|%s)([^A-Za-z0-9_-]|$)' "$s" "$c" "$(printf '%s' "$s" | tr _ -)"
}

producer_has() {
  local rx="$1" p ref label; shift
  for p in "$@"; do
    while IFS='	' read -r ref label; do
      (IFS=$'\n'; set -f; git -C "$p" grep -I -q -i -E -e "$rx" "$ref" -- . $CONTRACT_EXCLUDES 2>/dev/null) && return 0
    done <<EOF
$(side_refs "$p")
EOF
  done
  return 1
}

consumer_fields() {
  local f="$1" ep="$2" fields="$3" c="$4" prods="$5" route="${2#* }" pats="$TMP/cpats" win="$TMP/win" \
    ref label hits site="" miss="" onrefs="" fld rx missing_here IFS_OLD
  ep_patterns "$route" consumer | awk 'NR == 1 || /^\[/' > "$pats"
  head -1 "$pats" > "$pats.full"
  while IFS='	' read -r ref label; do
    hits="$(code_hits "$c" "$pats.full" "$ref" | cut -f2,3)"
    [ -n "$hits" ] || hits="$(code_hits "$c" "$pats" "$ref" | cut -f2,3)"
    [ -n "$hits" ] || continue
    : > "$win"
    while IFS='	' read -r file line; do
      case "$line" in ''|*[!0-9]*) echo "invalid contract line number: $line" >&2; return 2 ;; esac
      [ -n "$site" ] || site="$file:$line"
      git -C "$c" show "$ref:$file" 2>/dev/null | awk -v a="$((10#$line - FIELD_WINDOW))" -v b="$((10#$line + FIELD_WINDOW))" 'NR >= a && NR <= b' >> "$win"
    done <<EOF
$hits
EOF
    missing_here=""
    IFS_OLD="$IFS"; IFS=','
    for fld in $fields; do
      IFS="$IFS_OLD"
      rx="$(field_regex "$fld")"
      if ! grep -qiE -e "$rx" "$win"; then
        # shellcheck disable=SC2086
        producer_has "$rx" $prods && missing_here="$missing_here $fld"
      fi
      IFS=','
    done
    IFS="$IFS_OLD"
    [ -n "$missing_here" ] || continue
    miss="$miss$missing_here"; onrefs="$onrefs${onrefs:+, }$label"
  done <<EOF
$(side_refs "$c")
EOF
  [ -n "$miss" ] || return 0
  miss="$(printf '%s\n' $miss | awk 'NF && !s[$0]++ { printf "%s`%s`", (n++ ? ", " : ""), $0 }')"
  emit CONTRACT-FIELDS "$f" "$(basename "$c") ignores $miss of $ep ($site ±$FIELD_WINDOW lines on $onrefs) — check the consumer type"
}

to_repos() {
  local IFS=','; local n r
  for n in $1; do [ "$n" = - ] && continue; r="$(resolve_repo "$n")" && echo "$r"; done | awk '!s[$0]++'
}

check_contract() {
  local f="$1" cls="$2" entries="$3" ep fields pn cn prods cons named r out role line lenient
  [ "$cls" = open ] || [ "$cls" = "done" ] || return 0
  named="$(printf '%s\n%s\n' "$ROOT" "$(printf '%s\n' "$entries" | while IFS='	' read -r q p x; do
    [ -n "$p" ] || continue; [ "$q" = - ] && q=""; x="$(split_qual "$q" "$p")" && echo "${x%%	*}"; done)" | awk 'NF && !s[$0]++')"
  while IFS='	' read -r ep fields pn cn; do
    [ -n "$ep" ] || continue
    prods="$(to_repos "$pn")"; cons="$(to_repos "$cn")"; lenient="$ROOT"
    [ -n "$prods$cons" ] && lenient="$prods"
    out=""
    for r in $(if [ -n "$prods$cons" ]; then printf '%s\n%s\n' "$prods" "$cons"; else printf '%s\n' "$named"; fi | awk 'NF && !s[$0]++'); do
      role=consumer; printf '%s\n' "$lenient" | grep -qxF -- "$r" && role=producer
      line="$(presence "$r" "${ep#* }" "$role" "$cls" "${ep%% *}")"
      [ -n "$line" ] && out="$out${out:+; }$line"
    done
    [ -n "$out" ] && emit CONTRACT-MISSING "$f" "$ep — $out"
    [ "$fields" != - ] && [ -n "$prods" ] && [ -n "$cons" ] || continue
    for r in $cons; do
      printf '%s\n' "$prods" | grep -qxF -- "$r" && continue
      # shellcheck disable=SC2046
      consumer_fields "$f" "$ep" "$fields" "$r" "$(printf '%s ' $prods)"
    done
  done <<EOF
$(contract_rows "$f")
EOF
}

added_entries() {
  awk -v explicit=1 -v known="$(known_file)" -v aliases="$(alias_list)" "$AWK_PATHLIKE"'
    function lvl(s) { match(s, /^#+/); return RLENGTH }
    /^#+ / {
      if (inc && lvl($0) <= cl) inc = 0
      h = tolower($0); sub(/^#+[ \t]+/, "", h); sub(/[ \t]+$/, "", h)
      if (!inc && h == "changes") { inc = 1; cl = lvl($0) }
      next
    }
    inc && /^[ \t]*([-*][ \t]+)?\**ADDED\**:/ { scan_cell($0, "") }
  ' "$1" | sort -u
}

in_list() {
  local list="$1" p="$2"
  case "$p" in
    */) awk -v s="$p" 'index($0, s) == 1 || index($0, "/" s) { f = 1; exit } END { exit !f }' "$list" ;;
    *) grep -qxF -- "$p" "$list" || awk -v s="/$p" 'length($0) > length(s) && substr($0, length($0) - length(s) + 1) == s { f = 1; exit } END { exit !f }' "$list" ;;
  esac
}

check_unmerged() {
  local f="$1" cls="$2" status="$3" q p x repo rp d ref where items="" n=0
  case "$(status_norm "$status")" in "READY TO BUILD"|DONE) ;; *) return 0 ;; esac
  while IFS='	' read -r q p x; do
    [ -n "$p" ] || continue
    case "$p" in *\**) continue ;; esac
    [ "$q" = - ] && q=""
    x="$(split_qual "$q" "$p")" || continue
    repo="${x%%	*}"; rp="${x#*	}"; d="$(def_branch "$repo")"
    in_list "$(list_files "$repo" "$d")" "$rp" && continue
    where=""
    while IFS= read -r ref; do
      [ -n "$ref" ] && in_list "$(list_files "$repo" "$ref")" "$rp" && where="$where$ref"$'\n'
    done < "$(cap_refs "$repo")"
    if [ -n "$where" ]; then where="on $(printf '%s' "$where" | join_list - 2)"
    elif [ "$cls" = "done" ]; then where="nowhere"
    else continue; fi
    n=$((n + 1))
    [ "$n" -le 3 ] && items="$items${items:+; }$(basename "$repo"):$rp $where"
  done <<EOF
$(added_entries "$f")
EOF
  [ "$n" -gt 0 ] || return 0
  [ "$n" -gt 3 ] && items="$items; +$((n - 3))"
  emit UNMERGED "$f" "$n ADDED paths not on the default branch while Status is '${status%% —*}': $items"
}
