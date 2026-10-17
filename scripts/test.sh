#!/usr/bin/env bash
# Run plugin validation, shellcheck, hook command checks and all *-test.sh files. Stop at the first failure.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

step() { printf '%-12s %s\n' "$1" "$2"; }
fail() { step "$1" FAIL; [[ -n "${2:-}" ]] && printf '%s\n' "$2"; exit 1; }

out=$(claude plugin validate --strict . 2>&1) || fail validate "$out"
step validate ok

list=$(find . -path ./.git -prune -o -name '*.sh' -type f -print | sort)
mapfile -t scripts <<<"$list"
shellcheck -x "${scripts[@]}" || fail shellcheck
step shellcheck "ok (${#scripts[@]} files)"

cmds=$(jq -r '.hooks[][]?.hooks[]?.command' hooks/hooks.json)
n=0
while IFS= read -r c; do
  [[ -z "$c" ]] && continue
  path=${c//\"/}
  path=${path//\$\{CLAUDE_PLUGIN_ROOT\}/$root}
  path=${path%% *}
  [[ -x "$path" ]] || fail hooks "not executable: $c"
  n=$((n + 1))
done <<<"$cmds"
step hooks "ok ($n commands)"

list=$(find . -path ./.git -prune -o -name '*-test.sh' -type f -print | sort)
tests=()
[[ -n "$list" ]] && mapfile -t tests <<<"$list"
for t in "${tests[@]}"; do
  bash "$t" || fail test "$t"
done
step tests "ok (${#tests[@]} files)"
