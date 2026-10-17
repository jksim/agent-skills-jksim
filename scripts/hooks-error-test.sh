#!/usr/bin/env bash
# Error paths for every hook: no jq, bad JSON, empty input. A hook must never block (exit 2) on them.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_PLUGIN_ROOT="$(dirname "$here")"
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
trap 'rm -rf "$CLAUDE_PROJECT_DIR"' EXIT

fails=0
bash_bin=$(command -v bash)
check() {
  local name=$1 out=$2 rc=$3
  if ((rc != 2)) && { [[ -z "$out" ]] || jq -e . <<<"$out" >/dev/null 2>&1; }; then
    echo "  ok   $name"
  else
    echo "  FAIL $name: rc=$rc out=$out"; fails=$((fails + 1))
  fi
}

for s in inject-rules commit-check skill-overrides path-guard; do
  script="$here/$s.sh"
  out=$(echo '{"hook_event_name":"SessionStart"}' | PATH=/nonexistent "$bash_bin" "$script" 2>/dev/null) && rc=0 || rc=$?
  check "E $s no jq" "$out" "$rc"
  out=$(echo 'not json' | "$script" 2>/dev/null) && rc=0 || rc=$?
  check "E $s bad JSON" "$out" "$rc"
  if ((rc == 0)); then echo "  ok   E $s bad JSON exit 0"; else echo "  FAIL E $s bad JSON exit $rc"; fails=$((fails + 1)); fi
  out=$("$script" </dev/null 2>/dev/null) && rc=0 || rc=$?
  check "E $s empty input" "$out" "$rc"
done

out=$(echo '{"hook_event_name":"SessionStart"}' | PATH=/nonexistent "$bash_bin" "$here/inject-rules.sh" 2>/dev/null)
if [[ "$out" == *"jq not found"* ]]; then echo "  ok   E inject-rules no jq message"; else echo "  FAIL E inject-rules no jq message: $out"; fails=$((fails + 1)); fi

((fails == 0))
