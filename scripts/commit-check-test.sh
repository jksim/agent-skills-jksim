#!/usr/bin/env bash
# Tests for commit-check.sh (C1–C6).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/commit-check.sh"
CLAUDE_PLUGIN_ROOT="$(dirname "$here")"
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
trap 'rm -rf "$CLAUDE_PROJECT_DIR"' EXIT

fails=0
run() { jq -cn --arg c "$1" '{hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}}' | "$script"; }
quiet() {
  local out
  out=$(run "$2")
  if [[ -z "$out" ]]; then echo "  ok   $1"; else echo "  FAIL $1: $out"; fails=$((fails + 1)); fi
}
warns() {
  local out
  out=$(run "$2")
  if jq -e --arg w "$3" '(.hookSpecificOutput.additionalContext | contains($w)) and (.hookSpecificOutput.permissionDecision == null) and (.hookSpecificOutput.hookEventName == "PreToolUse") and (.systemMessage | contains("rule 4"))' <<<"$out" >/dev/null 2>&1; then
    echo "  ok   $1"
  else
    echo "  FAIL $1: $out"; fails=$((fails + 1))
  fi
}

long=$(printf 'Add %.0s' {1..20})
heredoc_good=$'git commit -m "$(cat <<\'EOF\'\nAdd commit check hook\n\nWarns on long messages.\nEOF\n)"'
heredoc_long=$'git commit -m "$(cat <<\'EOF\'\nAdd commit check hook\n\n1\n2\n3\n4\n5\n6\nEOF\n)"'

quiet "C1 good -m" 'git commit -m "Add commit check hook"'
quiet "C1 good -am single quotes" "git commit -am 'Add commit check hook'"
warns "C2 long subject" "git commit -m \"$long\"" "The team limit is 72"
warns "C3 long body -m" 'git commit -m "Add hook" -m "1
2
3
4
5
6"' "The commit body has 6 lines"
warns "C3 long body heredoc" "$heredoc_long" "The commit body has 6 lines"
warns "C4 wip" 'git commit -m "wip"' "looks like a fix-up"
warns "C4 fix typo" 'git commit -m "fix typo in README"' "looks like a fix-up"
warns "C4 Oops" 'git commit -m "Oops"' "looks like a fix-up"
quiet "C4 not a fix-up" 'git commit -m "Fix hook path on Windows"'
warns "C4 Oops!" 'git commit -m "Oops!"' "looks like a fix-up"
warns "C4 fix tests" 'git commit -m "fix tests"' "looks like a fix-up"
warns "C4 fix typos" 'git commit -m "fix typos in README"' "looks like a fix-up"
warns "C4 address review" 'git commit -m "Address review comments"' "looks like a fix-up"
quiet "C4 real fix tests" 'git commit -m "Fix tests for Windows paths"'
quiet "C4 real temp" 'git commit -m "Temp file cleanup in hook"'
quiet "C4 real tmp" 'git commit -m "Tmp dir is created per test"'
quiet "C5 amend no-edit" 'git commit --amend --no-edit'
quiet "C5 fixup" 'git commit --fixup abc123'
quiet "C5 file" 'git commit -F msg.txt'
quiet "C6 good heredoc" "$heredoc_good"
quiet "C escaped quote" 'git commit -m "Add \"quoted\" word"'

s72=$(printf 'a%.0s' {1..72})
s73=$(printf 'a%.0s' {1..73})
e40=$(printf 'é%.0s' {1..40})
b77=$(printf 'b%.0s' {1..77})
mixed=$'git commit -m "Add hook" -m "$(cat <<\'EOF\'\n'"$b77"$'\nEOF\n)"'
dash_tab=$'git commit -m "$(cat <<-EOF\n\t'"$s72"$'\n\tEOF\n)"'
delim_word=$'git commit -m "$(cat <<\'EOF\'\nwip\n\nEOFs end here\n1\n2\n3\n4\n5\nEOF\n)"'

quiet "B 72-char subject" "git commit -m \"$s72\""
warns "B 73-char subject" "git commit -m \"$s73\"" "has 73 characters"
quiet "B 5-line body" 'git commit -m "Add hook" -m "1
2
3
4
5"'
quiet "C5 squash" 'git commit --squash abc123'
quiet "X mixed -m and heredoc" "$mixed"
quiet "X CRLF 72" "git commit -m \"$s72"$'\r'"\""
quiet "X 40 x é in C locale" "$(printf 'git commit -m "%s"' "$e40")"
quiet "X escaped quotes 72" "git commit -m \"$(printf 'a%.0s' {1..66})\\\"xy\\\"\""
warns "X skip flag inside message" 'git commit -m "wip" -m "Do not use --no-edit here"' "looks like a fix-up"
warns "X chained command" 'git add . && git commit -m "wip"' "looks like a fix-up"
quiet "X make -C after commit" 'git commit -m "Add hook" && make -C build'
quiet "X <<- strips tabs" "$dash_tab"
warns "X delimiter prefix line" "$delim_word" "The commit body has 6 lines"
quiet "X heredoc text in -m" 'git commit -m "Explain <<EOF use"'

quoted_heredoc=$'git commit -m "$(cat <<\'EOF\'\nAdd "x" hook\n\n1\n2\n3\n4\n5\n6\nEOF\n)"'
warns "R heredoc with quotes" "$quoted_heredoc" "The commit body has 6 lines"
warns "R separator after bad message" 'git add . && git commit -m "wip" && make -C build' "looks like a fix-up"
quiet "R tag message after commit" 'git commit -m "Add hook" && git tag -a v1 -m "1
2
3
4
5
6"'
warns "R --message=" 'git commit --message="wip"' "looks like a fix-up"
warns "R unquoted -m" 'git commit -m wip' "looks like a fix-up"
warns "R more fixes" 'git commit -m "more fixes"' "looks like a fix-up"
warns "R Minor fix" 'git commit -m "Minor fix in x"' "looks like a fix-up"
quiet "R reuse message" 'git commit -c HEAD'
quiet "R reuse long form" 'git commit --reuse-message=HEAD'
quiet "R -F inside quotes" "git commit -m 'note -F'"
quiet "R not a commit" 'git status && echo "git commit -m wip"'
quiet "R over 16 KB" "git commit -m \"wip $(printf 'x%.0s' {1..17000})\""

((fails == 0))
