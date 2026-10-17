#!/usr/bin/env bash
# Warn when a git commit message breaks rule 4. Never blocks.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')
cmd=${cmd//$'\r'/}
[[ -z "$cmd" ]] && exit 0

re_dq='"((\\.|[^"\\])*)"'
re_sq="'([^']*)'"

# Command text with quoted strings removed, from "commit" to the next separator.
bare=$cmd
while [[ "$bare" =~ $re_dq ]]; do bare=${bare/"${BASH_REMATCH[0]}"/Q}; done
while [[ "$bare" =~ $re_sq ]]; do bare=${bare/"${BASH_REMATCH[0]}"/Q}; done
seg=${bare#*commit}
seg=${seg%%[;&|]*}
re_skip='(^|[[:space:]])(--no-edit|--fixup|--squash|-F|--file|-C|-c|--reuse-message|--reedit-message)([[:space:]=]|$)'
[[ "$seg" =~ $re_skip ]] && exit 0

# Text of a heredoc inside one -m argument.
heredoc_text() {
  local re="<<(-?)[[:space:]]*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?" line out="" inside=0 tabs="" delim=""
  [[ "$1" =~ $re ]] || return 0
  tabs=${BASH_REMATCH[1]}
  delim=${BASH_REMATCH[2]}
  while IFS= read -r line; do
    if ((inside)); then
      [[ -n "$tabs" ]] && line=${line#"${line%%[!$'\t']*}"}
      [[ "${line//[[:space:]]/}" == "$delim" ]] && break
      out+="$line"$'\n'
    elif [[ "$line" =~ $re ]]; then
      inside=1
    fi
  done <<<"$1"
  printf '%s' "$out"
}

msg=""
re_m="(^|[[:space:]])(-[a-zA-Z]*m|--message)[[:space:]=]*($re_dq|$re_sq)"
re_cat='^[[:space:]]*\$\([[:space:]]*cat[[:space:]]+<<'
rest=$cmd
while [[ "$rest" =~ $re_m ]]; do
  whole=${BASH_REMATCH[0]}
  if [[ -n "${BASH_REMATCH[4]}" ]]; then
    part=${BASH_REMATCH[4]}
    if [[ "$part" =~ $re_cat ]]; then
      part=$(heredoc_text "$part")
    else
      part=${part//\\\"/\"}
      part=${part//\\\\/\\}
    fi
  else
    part=${BASH_REMATCH[6]}
  fi
  [[ -n "$msg" ]] && msg+=$'\n\n'
  msg+=$part
  rest=${rest#*"$whole"}
done

[[ -z "${msg//[[:space:]]/}" ]] && exit 0

subject=$(sed -n '/[^[:space:]]/{p;q}' <<<"$msg")
len=$(jq -rn --arg s "$subject" '$s | length')
body_lines=$(sed '0,/[^[:space:]]/d' <<<"$msg" | grep -c '[^[:space:]]' || true)

warn=()
((len > 72)) && warn+=("The commit subject has $len characters. The team limit is 72.")
((body_lines > 5)) && warn+=("The commit body has $body_lines lines. The team limit is 5.")
shopt -s nocasematch
re_whole='^(wip|oops|tmp|temp|fix tests?|more fixes)[[:punct:][:space:]]*$'
re_prefix='^(fix(ed)? typos?|minor fix|address review)([^[:alnum:]]|$)'
[[ "$subject" =~ $re_whole || "$subject" =~ $re_prefix ]] && warn+=("The commit subject \"$subject\" looks like a fix-up commit. The team squashes fix-up commits into the commit they fix.")
shopt -u nocasematch

((${#warn[@]} == 0)) && exit 0

text="commit-check (rule 4): ${warn[*]} Amend or squash before push. See the commit-hygiene skill."
jq -cn --arg t "$text" '{
  systemMessage: "commit-check: this commit breaks rule 4. See the agent reply.",
  hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $t }
}'
