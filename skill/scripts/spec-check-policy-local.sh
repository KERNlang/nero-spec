# shellcheck shell=bash
# Optional, sourced by spec-check.sh when present; vendored copies leave it out.
# policy_local_path: the policy from the machine file's `policy_paths: <dir>=<abs .md>, ...` (longest dir match).
# SPEC_MACHINE overrides the machine file location.

policy_local_path() {
  local machine="${SPEC_MACHINE:-$HOME/.config/spec/machine}" line pair dir file best="" bestlen=0
  [ -r "$machine" ] || return 0
  line="$(awk '{ sub(/[ \t]*#.*/, "") } index($0, "policy_paths:") == 1 { sub(/^[^:]*:[ \t]*/, ""); print; exit }' "$machine")"
  [ -n "$line" ] || return 0
  local IFS=','
  for pair in $line; do
    pair="$(printf '%s' "$pair" | awk '{ $1 = $1; print }')"
    dir="${pair%%=*}"; file="${pair#*=}"
    [ "$dir" != "$pair" ] || continue
    case "$dir" in "~"/*) dir="$HOME/${dir#\~/}" ;; esac
    case "$file" in "~"/*) file="$HOME/${file#\~/}" ;; esac
    dir="$(cd "$dir" 2>/dev/null && pwd -P)" || continue
    case "$ROOT/" in "$dir"/*) [ "${#dir}" -gt "$bestlen" ] && { best="$file"; bestlen="${#dir}"; } ;; esac
  done
  [ -n "$best" ] || return 0
  case "$best" in /*.md) ;; *) policy_fail "$best (policy_paths needs an absolute .md path)"; return 2 ;; esac
  [ -f "$best" ] || { policy_fail "$best (file not found)"; return 2; }
  printf '%s\n' "$best"
}
