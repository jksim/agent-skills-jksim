#!/usr/bin/env bash
# Run plugin validation, shellcheck, hook and manifest checks, and all *-test.sh files. Stop at the first failure.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

step() { printf '%-12s %s\n' "$1" "$2"; }
fail() { step "$1" FAIL; [[ -n "${2:-}" ]] && printf '%s\n' "$2"; exit 1; }

for t in jq shellcheck claude; do
  command -v "$t" >/dev/null || fail tools "$t not found. Install it."
done
step tools ok

out=$(claude plugin validate --strict . 2>&1) || fail validate "$out"
step validate ok

scripts=()
while IFS= read -r f; do scripts+=("$f"); done < <(find . -path ./.git -prune -o -name '*.sh' -type f -print | sort)
shellcheck -x "${scripts[@]}" || fail shellcheck
step shellcheck "ok (${#scripts[@]} files)"

cmds=$(jq -r '.hooks[][]?.hooks[]?.command' hooks/hooks.json)
n=0
while IFS= read -r c; do
  [[ -z "$c" ]] && continue
  rel=${c#*\${CLAUDE_PLUGIN_ROOT\}}
  rel=${rel#\"}
  rel=${rel%%[[:space:]]*}
  [[ -x "$root$rel" ]] || fail hooks "not executable: $c"
  [[ -f "$root${rel%.sh}-test.sh" ]] || fail hooks "no test file for $rel"
  n=$((n + 1))
done <<<"$cmds"
step hooks "ok ($n commands)"

m=.claude-plugin/marketplace.json
mk=$(jq -r .name "$m")
bad=$(jq -r --arg mk "$mk" --slurpfile m "$m" --slurpfile p .claude-plugin/plugin.json '
  ($m[0].plugins | map(.name)) as $names
  | [ (.enabledPlugins | to_entries[] | select(.value) | .key | split("@") | select(.[1] != $mk or (.[0] | IN($names[]) | not)) | join("@")),
      (.extraKnownMarketplaces | keys[] | select(. != $mk)),
      ($p[0].dependencies[]? | (if type == "string" then . else .name end) | select(IN($names[]) | not)) ]
  | .[]' templates/consumer-settings.json)
[[ -z "$bad" ]] || fail manifests "template or dependency names not in $m: $bad"
step manifests ok

tests=()
while IFS= read -r f; do tests+=("$f"); done < <(find . -path ./.git -prune -o -name '*-test.sh' -type f -print | sort)
((${#tests[@]})) || fail tests "no *-test.sh files found"
for t in "${tests[@]-}"; do
  bash "$t" || fail test "$t"
done
step tests "ok (${#tests[@]} files)"
