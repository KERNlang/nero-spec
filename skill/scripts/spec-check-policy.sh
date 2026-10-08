# shellcheck shell=bash
# Sourced by spec-check.sh. Needs: ROOT, TMP, HERE, cfg, emit, header, status_norm.
# Policy = one company module: `.spec` `policy:` (repo file), else policy_local_path from the optional
# spec-check-policy-local.sh (not shipped in vendored copies).

POLICY_KEYS=" format ticket.regex ticket.prefixes ticket.fallback branch.pattern pr.title pr.regex headers sections words.deny addons.require addons.deny agon.max agon_engines critic rules skills skills.path "
POLICY_STEPS=" understand design critic build tests review tickets retro "
SKILL_DIRS_DEFAULT=".agents/skills .claude/skills .ai/skills"
POLICY_OWNED="ticket.regex ticket.prefixes ticket.fallback branch.pattern"
POLICY_FILE=""; POLICY_KV=""

policy_fail() { echo "spec-check: invalid policy: $1" >&2; return 2; }

repo_rel_path() {
  local p="$1"
  while [ "${p#./}" != "$p" ]; do p="${p#./}"; done
  case "$p" in ''|/*|-*|'~'*|*://*|*$'\n'*|*$'\r'*) return 1 ;; esac
  case "/$p/" in *'/../'*|*'/./'*) return 1 ;; esac
  printf '%s' "$p"
}

inside_root() {
  local canonical
  [ -L "$1" ] && return 1
  canonical="$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)" || return 1
  case "$canonical" in "$ROOT"|"$ROOT"/*) return 0 ;; esac
  return 1
}

policy_repo_path() {
  local p
  p="$(repo_rel_path "$1")" || { policy_fail "$1 (repo-relative path without . or .. components required)"; return 2; }
  case "$p" in *.md) ;; *) policy_fail "$1 (must be a .md file)"; return 2 ;; esac
  [ -f "$p" ] || { policy_fail "$1 (file not found)"; return 2; }
  inside_root "$p" || { policy_fail "$1 (a symlink or outside the repo)"; return 2; }
  printf '%s\n' "$ROOT/$p"
}

policy_parse() {
  awk -v keys="$POLICY_KEYS" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") { print "no frontmatter"; bad = 1; exit } ; next }
    $0 == "---" { closed = 1; exit }
    /^[ \t]*(#|$)/ { next }
    {
      i = index($0, ":"); if (!i) { print "bad line: " $0; bad = 1; exit }
      k = substr($0, 1, i - 1); v = substr($0, i + 1); gsub(/^[ \t]+|[ \t]+$/, "", k); gsub(/^[ \t]+|[ \t]+$/, "", v)
      if (index(keys, " " k " ") == 0) { print "unknown key: " k; bad = 1; exit }
      if (k in seen) { print "duplicate key: " k; bad = 1; exit }
      seen[k] = 1; print k "\t" v > "/dev/stderr"
    }
    END { if (!bad && !closed) print "unterminated frontmatter" }' "$1" 2> "$POLICY_KV"
}

ticket_re() { pol ticket.regex | sed 's/\\d/[0-9]/g'; }

pr_title_re() {
  if [ -n "$(pol pr.regex)" ]; then pol pr.regex | sed 's/\\d/[0-9]/g'; return 0; fi
  [ -n "$(pol pr.title)" ] || return 0
  pol pr.title | awk '
    function esc(t,  r, i, c) { r = ""; for (i = 1; i <= length(t); i++) { c = substr(t, i, 1); r = r (index("\\.[]()*+?{}|^$", c) ? "\\" : "") c } return r }
    function alts(t,  n, a, i, r) { n = split(t, a, "|"); r = ""; for (i = 1; i <= n; i++) r = r (i > 1 ? "|" : "") esc(a[i]); return "(" r ")" }
    { s = $0; out = ""
      while (match(s, /<[^<>]+>/)) {
        ph = substr(s, RSTART + 1, RLENGTH - 2)
        out = out esc(substr(s, 1, RSTART - 1)) (ph == "n" ? "[0-9]+" : index(ph, "|") ? alts(ph) : ".+")
        s = substr(s, RSTART + RLENGTH)
      }
      print "^" out esc(s) "$" }'
}

policy_check_pr_title() {
  local title="$1" spec="$2" re key
  case "$title" in ''|*$'\n'*|*$'\r'*) echo "spec-check: --pr-title needs a one-line title" >&2; return 2 ;; esac
  re="$(pr_title_re)"
  [ -n "$re" ] || { echo "spec-check: --pr-title needs pr.title or pr.regex in the company policy" >&2; return 2; }
  if ! printf '%s\n' "$title" | grep -Eq -- "$re"; then
    if [ -n "$(pol pr.regex)" ]; then key="pr.regex $(pol pr.regex)"; else key="$(pol pr.title)"; fi
    echo "PR-TITLE '$title' does not match the policy format: $key"; return 1
  fi
  if [ -n "$spec" ]; then
    [ -n "$(pol ticket.regex)" ] || { echo "spec-check: --pr-title with --spec needs ticket.regex in the company policy" >&2; return 2; }
    key="$(header Ticket "$spec" | sed 's/([^)]*)//g' | grep -oE -- "$(ticket_re)" | head -n 1)"
    [ -n "$key" ] || { echo "PR-TITLE spec has no **Ticket:** key matching ticket.regex, so the title cannot be tied to it"; return 1; }
    if ! printf '%s\n' "$title" |
      grep -Eq -- "(^|[^A-Za-z0-9_-])$(printf '%s' "$key" | sed 's/[][\.*^$(){}+?|/]/\\&/g')([^A-Za-z0-9_-]|\$)"; then
      echo "PR-TITLE '$title' does not name the spec's ticket $key"; return 1
    fi
  fi
  echo "PR-TITLE ok"
}

policy_validate() {
  local r
  [ "$(pol format)" = "nero-spec-policy/v1" ] || { policy_fail "$POLICY_FILE: format must be nero-spec-policy/v1"; return 2; }
  case "$(pol agon.max)" in ''|off|ask|restricted|full) ;; *) policy_fail "$POLICY_FILE: agon.max must be off|ask|restricted|full"; return 2 ;; esac
  case "$(pol critic)" in ''|subagent|agon|any) ;; *) policy_fail "$POLICY_FILE: critic must be subagent|agon|any"; return 2 ;; esac
  [ "$(pol critic)" = agon ] && case "$(pol agon.max)" in off|ask) policy_fail "$POLICY_FILE: critic agon needs agon.max restricted or full"; return 2 ;; esac
  if [ -n "$(pol ticket.regex)" ]; then
    printf '' | grep -E -- "$(ticket_re)" >/dev/null 2>&1
    [ $? -le 1 ] || { policy_fail "$POLICY_FILE: ticket.regex is not a valid extended regex"; return 2; }
  fi
  if [ -n "$(pol pr.regex)$(pol pr.title)" ]; then
    printf '' | grep -E -- "$(pr_title_re)" >/dev/null 2>&1
    [ $? -le 1 ] || { policy_fail "$POLICY_FILE: pr.regex (or the regex built from pr.title) is not a valid extended regex"; return 2; }
  fi
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    repo_rel_path "$r" >/dev/null || { policy_fail "$POLICY_FILE: rules entry '$r' must be repo-relative without . or .. components"; return 2; }
  done <<EOF
$(items "$(pol rules)")
EOF
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    repo_rel_path "$r" >/dev/null || { policy_fail "$POLICY_FILE: skills.path entry '$r' must be repo-relative without . or .. components"; return 2; }
  done <<EOF
$(items "$(pol skills.path)")
EOF
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    case "$r" in *=*) ;; *) policy_fail "$POLICY_FILE: skills entry '$r' must be <step>=<skill>[|<skill>]"; return 2 ;; esac
    case "$POLICY_STEPS" in *" ${r%%=*} "*) ;; *) policy_fail "$POLICY_FILE: skills step '${r%%=*}' must be one of:$POLICY_STEPS"; return 2 ;; esac
    case "|${r#*=}|" in *'||'*|'| |'*) policy_fail "$POLICY_FILE: skills entry '$r' has an empty skill name"; return 2 ;; esac
    skill_names "$r" | grep -qvE '^[A-Za-z0-9_][A-Za-z0-9._-]*$' &&
      { policy_fail "$POLICY_FILE: skills entry '$r' has an invalid skill name"; return 2; }
  done <<EOF
$(items "$(pol skills)")
EOF
  return 0
}

skill_names() { printf '%s' "${1#*=}" | tr '|' '\n' | awk '{ $1 = $1; print }'; }

skill_dirs() {
  if [ -n "$(pol skills.path)" ]; then items "$(pol skills.path)"; else printf '%s\n' $SKILL_DIRS_DEFAULT; fi
}

skill_found() {
  local d c
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    [ -f "$d/$1/SKILL.md" ] && [ ! -L "$d/$1/SKILL.md" ] || continue
    c="$(cd "$d/$1" 2>/dev/null && pwd -P)" || continue
    case "$c" in "$ROOT"/*) return 0 ;; esac
  done <<EOF
$(skill_dirs)
EOF
  return 1
}

policy_check_skills() {
  local r s where
  where="$(skill_dirs | paste -sd ',' - | sed 's/,/, /g')"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    while IFS= read -r s; do
      skill_found "$s" ||
        emit POLICY-SKILL .spec "skill '$s' for step '${r%%=*}' has no SKILL.md under $where inside the repo"
    done <<EOF
$(skill_names "$r")
EOF
  done <<EOF
$(items "$(pol skills)")
EOF
}

policy_load() {
  local p err
  POLICY_KV="$TMP/policy.kv"; : > "$POLICY_KV"
  p="$(cfg policy)"
  if [ -n "$p" ]; then POLICY_FILE="$(policy_repo_path "$p")" || return 2
  elif command -v policy_local_path >/dev/null 2>&1; then POLICY_FILE="$(policy_local_path)" || return 2; fi
  [ -n "$POLICY_FILE" ] || return 0
  err="$(policy_parse "$POLICY_FILE")"
  [ -z "$err" ] || { policy_fail "$POLICY_FILE: $err"; return 2; }
  policy_validate
}

pol() { [ -s "$POLICY_KV" ] && awk -F'\t' -v k="$1" '$1 == k { print $2; exit }' "$POLICY_KV"; }
pol_has() { [ -s "$POLICY_KV" ] && awk -F'\t' -v k="$1" '$1 == k { f = 1 } END { exit !f }' "$POLICY_KV"; }
cfg_has() { [ -f .spec ] && awk -v k="$1" '{ sub(/[ \t]*#.*/, "") } index($0, k ":") == 1 { f = 1 } END { exit !f }' .spec; }

items() { printf '%s' "$1" | tr ',' '\n' | awk '{ $1 = $1 } $0 != ""'; }

agon_rank() { case "$1" in off) echo 0 ;; ask) echo 1 ;; restricted) echo 2 ;; full) echo 3 ;; esac; }

preset_key() {
  local f
  f="$HERE/../presets/$(cfg preset | tr -d ' ').md"
  [ -f "$f" ] && awk -v k="$1" 'NR == 1 { next } $0 == "---" { exit } index($0, k ":") == 1 { sub(/^[^:]*:[ \t]*/, ""); print; exit }' "$f"
}

policy_check_repo() {
  [ -n "$POLICY_FILE" ] || return 0
  local k pv sv max agon a eng r addons
  for k in $POLICY_OWNED; do
    pol_has "$k" && cfg_has "$k" || continue
    pv="$(pol "$k")"; sv="$(cfg "$k")"
    [ "$(printf '%s' "$pv" | tr -d ' ')" != "$(printf '%s' "$sv" | tr -d ' ')" ] &&
      emit POLICY-CONFLICT .spec "$k '$sv' differs from policy '$pv' — the policy owns it"
  done
  agon="$(cfg agon | tr -d ' ')"; [ -n "$agon" ] || agon="$(preset_key agon | tr -d ' ')"
  max="$(pol agon.max)"
  if [ -n "$max" ] && [ -n "$(agon_rank "$agon")" ] && [ "$(agon_rank "$agon")" -gt "$(agon_rank "$max")" ]; then
    emit POLICY-CONFLICT .spec "agon '$agon' exceeds policy agon.max '$max' — set agon: $max or lower"
  fi
  if [ -n "$(pol agon_engines)" ]; then
    [ "$agon" = full ] && emit POLICY-CONFLICT .spec "agon 'full' ignores policy agon_engines — set agon: restricted"
    while IFS= read -r eng; do
      [ -n "$eng" ] || continue
      items "$(pol agon_engines)" | grep -qxF -- "$eng" ||
        emit POLICY-CONFLICT .spec "agon engine '$eng' is not in policy agon_engines"
    done <<EOF
$(items "$(cfg agon_engines)")
EOF
  fi
  addons=",$(cfg addons | tr -d ' '),"
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    case "$addons" in *",-$a,"*) emit POLICY-CONFLICT .spec "addon '$a' is required by the policy but removed in .spec" ;; esac
  done <<EOF
$(items "$(pol addons.require)")
EOF
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    case "$addons" in *",-$a,"*) continue ;; *",$a,"*|*",+$a,"*)
      emit POLICY-CONFLICT .spec "addon '$a' is denied by the policy but enabled in .spec"; continue ;; esac
    case ",$(preset_key addons | tr -d ' ')," in *",$a,"*)
      emit POLICY-CONFLICT .spec "addon '$a' is denied by the policy but on in the preset — add -$a to .spec addons" ;; esac
  done <<EOF
$(items "$(pol addons.deny)")
EOF
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    r="$(repo_rel_path "$r")"
    if [ ! -f "$r" ] || ! inside_root "$r"; then emit POLICY-RULES .spec "rules file '$r' is missing, a symlink or outside the repo"; fi
  done <<EOF
$(items "$(pol rules)")
EOF
  policy_check_skills
}

policy_check_words() {
  local f="$1" w n
  while IFS= read -r w; do
    [ -n "$w" ] || continue
    n="$(grep -niwF -- "$w" "$f" | head -1 | cut -d: -f1)"
    [ -n "$n" ] && emit POLICY-WORD "$f" "line $n uses '$w', denied by the policy"
  done <<EOF
$(items "$(pol words.deny)")
EOF
}

has_section() {
  awk -v s="$2" '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^#+[ \t]/ { l = tolower($0); sub(/^#+[ \t]+/, "", l); sub(/[ \t]+$/, "", l)
      if (l == s || index(l, s " (") == 1 || index(l, s ":") == 1) { found = 1; exit } }
    END { exit !found }' "$1"
}

policy_check_spec() {
  [ -n "$POLICY_FILE" ] || return 0
  local f="$1" status="$2" h re t s
  policy_check_words "$f"
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    [ -n "$(header "$h" "$f")" ] || emit POLICY-HEADER "$f" "missing **$h:** header required by the policy"
  done <<EOF
$(items "$(pol headers)")
EOF
  re="$(ticket_re)"
  t="$(header Ticket "$f" | sed 's/([^)]*)//g')"
  if [ -n "$re" ] && [ -n "$t" ] && ! printf '%s' "$t" | grep -Eq -- "(^|[^A-Za-z0-9_-])($re)([^A-Za-z0-9_-]|$)"; then
    emit POLICY-TICKET "$f" "Ticket '$(printf '%s' "$t" | cut -c1-40)' does not match policy ticket.regex"
  fi
  case "$(status_norm "$status")" in "READY TO BUILD"|"IN PROGRESS"|DONE)
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      has_section "$f" "$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')" ||
        emit POLICY-SECTION "$f" "missing ## $s section required by the policy"
    done <<EOF
$(items "$(pol sections)")
EOF
  ;; esac
}
