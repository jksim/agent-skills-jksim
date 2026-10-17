#!/usr/bin/env bash
# Warn when a git commit message breaks rule 4. Never blocks.
set -euo pipefail

command -v jq >/dev/null || exit 0

cmd=$(jq -r '.tool_input.command // empty') || exit 0
cmd=${cmd//$'\r'/}
[[ -z "$cmd" || ${#cmd} -gt 16384 ]] && exit 0

re_dq='^"((\\.|[^"\\])*)"'
re_sq="^'([^']*)'"
re_cat='^"\$\([[:space:]]*cat[[:space:]]+<<(-?)[[:space:]]*['"'"'"]?([A-Za-z_][A-Za-z0-9_]*)['"'"'"]?'
re_flag='(^|[[:space:]])(-[a-zA-Z]*m|--message)([[:space:]]+|=)'
re_git='(^|[[:space:];&|(])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)'

# Remove quoted strings, so separators and flags inside them do not count.
unquote() {
  local s=$1 re1='"((\\.|[^"\\])*)"' re2="'([^']*)'"
  while [[ "$s" =~ $re1 ]]; do s=${s/"${BASH_REMATCH[0]}"/Q}; done
  while [[ "$s" =~ $re2 ]]; do s=${s/"${BASH_REMATCH[0]}"/Q}; done
  printf '%s' "$s"
}

[[ "$cmd" =~ $re_git ]] || exit 0
rest=${cmd#*"${BASH_REMATCH[0]}"}

re_skip='(^|[[:space:]])(--no-edit|--fixup|--squash|-F|--file|-C|-c|--reuse-message|--reedit-message)([[:space:]=]|$)'

msg=""
while [[ "$rest" =~ $re_flag ]]; do
  flag=${BASH_REMATCH[0]}
  gap=$(unquote "${rest%%"$flag"*}")
  [[ "$gap" == *[\;\&\|]* ]] && break
  [[ "$gap" =~ $re_skip ]] && exit 0
  rest=${rest#*"$flag"}

  if [[ "$rest" =~ $re_cat ]]; then
    tabs=${BASH_REMATCH[1]}
    delim=${BASH_REMATCH[2]}
    part=""
    body=${rest#*$'\n'}
    rest=""
    while IFS= read -r line; do
      [[ -n "$tabs" ]] && line=${line#"${line%%[!$'\t']*}"}
      if [[ "${line//[[:space:]]/}" == "$delim" ]]; then
        rest=${body#*$'\n'"$line"}
        break
      fi
      part+="$line"$'\n'
    done <<<"$body"
  elif [[ "$rest" =~ $re_dq ]]; then
    part=${BASH_REMATCH[1]}
    rest=${rest#"${BASH_REMATCH[0]}"}
    part=${part//\\\"/\"}
    part=${part//\\\\/\\}
  elif [[ "$rest" =~ $re_sq ]]; then
    part=${BASH_REMATCH[1]}
    rest=${rest#"${BASH_REMATCH[0]}"}
  elif [[ "$rest" =~ ^([^[:space:]\;\&\|\"\']+) ]]; then
    part=${BASH_REMATCH[1]}
    rest=${rest#"${BASH_REMATCH[0]}"}
  else
    break
  fi
  [[ -n "$msg" ]] && msg+=$'\n\n'
  msg+=$part
done

[[ -z "${msg//[[:space:]]/}" ]] && exit 0

subject=$(awk '/[^[:space:]]/ {print; exit}' <<<"$msg")
len=$(jq -rn --arg s "$subject" '$s | length')
body_lines=$(awk 'f && /[^[:space:]]/ {n++} /[^[:space:]]/ {f = 1} END {print n + 0}' <<<"$msg")

warn=()
((len > 72)) && warn+=("The commit subject has $len characters. The team limit is 72.")
((body_lines > 5)) && warn+=("The commit body has $body_lines lines. The team limit is 5.")
shopt -s nocasematch
re_whole='^(wip|oops|tmp|temp|fix tests?|more fixes)[[:punct:][:space:]]*$'
re_prefix='^(fix(ed)? typos?|minor fix|address review)([^[:alnum:]]|$)'
[[ "$subject" =~ $re_whole || "$subject" =~ $re_prefix ]] && warn+=("The commit subject \"$subject\" looks like a fix-up commit. The team squashes fix-up commits into the commit they fix.")
shopt -u nocasematch

((${#warn[@]} == 0)) && exit 0

text="commit-check (rule 4): ${warn[*]} The team amends or squashes such commits before push. See the commit-hygiene skill."
jq -cn --arg t "$text" '{
  systemMessage: "commit-check: this commit breaks rule 4. See the agent reply.",
  hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $t }
}'
