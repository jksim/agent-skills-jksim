#!/usr/bin/env bash
# Tests for skill-overrides.sh (U2, U3).
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/skill-overrides.sh"
CLAUDE_PLUGIN_ROOT="$(dirname "$here")"
CLAUDE_PROJECT_DIR="$(mktemp -d)"
export CLAUDE_PLUGIN_ROOT CLAUDE_PROJECT_DIR
trap 'rm -rf "$CLAUDE_PROJECT_DIR"' EXIT

fails=0
skill() { jq -cn --arg s "$1" '{hook_event_name: "PreToolUse", tool_name: "Skill", tool_input: {skill: $s}}' | "$script"; }
cmd() { jq -cn --arg c "$1" '{hook_event_name: "UserPromptExpansion", expansion_type: "slash_command", command_name: $c}' | "$script"; }
has() {
  if jq -e --arg w "$3" '.hookSpecificOutput.additionalContext | contains($w)' <<<"$2" >/dev/null 2>&1; then
    echo "  ok   $1"
  else
    echo "  FAIL $1: $2"; fails=$((fails + 1))
  fi
}
lacks() {
  if ! jq -e --arg w "$3" '.hookSpecificOutput.additionalContext | contains($w)' <<<"$2" >/dev/null 2>&1; then
    echo "  ok   $1"
  else
    echo "  FAIL $1"; fails=$((fails + 1))
  fi
}
quiet() { if [[ -z "$2" ]]; then echo "  ok   $1"; else echo "  FAIL $1: $2"; fails=$((fails + 1)); fi; }

out=$(skill agent-skills:spec-driven-development)
has "U2 spec skill paths" "$out" ".claude-work/spec/SPEC.md"
has "U2 spec skill vocabulary" "$out" "## Spec stage: vocabulary"
lacks "U2 spec skill no commits" "$out" "## Commits"
has "U2 plan paths" "$(skill agent-skills:planning-and-task-breakdown)" ".claude-work/tasks/plan-<id>.md"
has "U2 constraints path" "$(skill agent-skills:constraint-driven-development)" ".claude-work/docs/CONSTRAINTS.md"
has "U2 adr path" "$(skill agent-skills:documentation-and-adrs)" ".claude-work/docs/adr/"
has "U2 build send back" "$(skill agent-skills:incremental-implementation)" "## Send back (rule 0)"
has "U2 tdd send back" "$(skill agent-skills:test-driven-development)" "## Send back (rule 0)"
has "U2 git rule 4" "$(skill agent-skills:git-workflow-and-versioning)" "## Commits (rule 4)"
quiet "U2 other upstream skill" "$(skill agent-skills:frontend-ui-engineering)"
quiet "U2 own plugin skill" "$(skill agent-skills-jksim:commit-hygiene)"
quiet "U2 unrelated skill" "$(skill dataviz)"

out=$(cmd agent-skills:spec)
has "U3 command event" "$out" ".claude-work/spec/SPEC.md"
if [[ $(jq -r .hookSpecificOutput.hookEventName <<<"$out") == UserPromptExpansion ]]; then echo "  ok   U3 command hookEventName"; else echo "  FAIL U3 command hookEventName"; fails=$((fails + 1)); fi
if [[ $(skill agent-skills:spec | jq -r .hookSpecificOutput.hookEventName) == PreToolUse ]]; then echo "  ok   U3 skill hookEventName"; else echo "  FAIL U3 skill hookEventName"; fails=$((fails + 1)); fi
quiet "U3 command other" "$(cmd agent-skills:webperf)"

has "U2 build rule 4" "$(skill agent-skills:incremental-implementation)" "## Commits (rule 4)"
has "U2 interview-me paths" "$(skill agent-skills:interview-me)" ".claude-work/docs/intent/"

# Each section the script names must be a heading in the overrides file.
while IFS= read -r s; do
  if grep -qxF "## $s" "$CLAUDE_PLUGIN_ROOT/rules/PROCESS-OVERRIDES.md"; then echo "  ok   U2 heading: $s"; else echo "  FAIL U2 heading missing: $s"; fails=$((fails + 1)); fi
done < <(grep -o 'sections=([^)]*)' "$script" | grep -o '"[^"]*"' | tr -d '"' | sort -u)

# Every name in the case table gives a reminder, as a skill and as a command.
names=$(sed -n '/^case /,/^esac/p' "$script" | grep -E '^ +[a-z|[:space:]-]+\)' | sed 's/).*//' | tr '|' '\n' | tr -d ' ')
while IFS= read -r n; do
  [[ -z "$n" ]] && continue
  for form in skill cmd; do
    out=$("$form" "agent-skills:$n") && rc=0 || rc=$?
    if ((rc == 0)) && jq -e '.hookSpecificOutput.additionalContext | contains("\n## ")' <<<"$out" >/dev/null 2>&1; then
      echo "  ok   T $form agent-skills:$n"
    else
      echo "  FAIL T $form agent-skills:$n: rc=$rc"; fails=$((fails + 1))
    fi
  done
done <<<"$names"
quiet "T own plugin prefix" "$(skill agent-skills-jksim:spec)"

# CRLF line ends in the overrides file give the same reminder.
tmp=$(mktemp -d)
mkdir -p "$tmp/rules" && sed 's/$/\r/' "$CLAUDE_PLUGIN_ROOT/rules/PROCESS-OVERRIDES.md" >"$tmp/rules/PROCESS-OVERRIDES.md"
out=$(jq -cn '{hook_event_name: "PreToolUse", tool_input: {skill: "agent-skills:plan"}}' | CLAUDE_PLUGIN_ROOT="$tmp" "$script")
has "T CRLF overrides file" "$out" ".claude-work/tasks/plan-<id>.md"
out=$(jq -cn '{hook_event_name: "PreToolUse", tool_input: {skill: "agent-skills:plan"}}' | CLAUDE_PLUGIN_ROOT="$tmp/none" "$script") && rc=0 || rc=$?
if ((rc == 0)) && [[ -z "$out" ]]; then echo "  ok   T missing overrides file"; else echo "  FAIL T missing overrides file"; fails=$((fails + 1)); fi
rm -rf "$tmp"

# Upstream drift: each name must exist in upstream at the pinned commit.
sha=$(jq -r '.plugins[] | select(.name == "agent-skills") | .source.sha' "$CLAUDE_PLUGIN_ROOT/.claude-plugin/marketplace.json")
up=""
for d in "${UPSTREAM_DIR:-}" "$CLAUDE_PLUGIN_ROOT/../agent-skills"; do
  if [[ -n "$d" && -d "$d/skills" && "$(git -C "$d" rev-parse HEAD 2>/dev/null)" == "$sha" ]]; then up=$d; break; fi
done
if [[ -z "$up" ]]; then
  echo "  skip T upstream drift (no upstream checkout at $sha; set UPSTREAM_DIR)"
else
  while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    if [[ -d "$up/skills/$n" || -f "$up/.claude/commands/$n.md" ]]; then echo "  ok   T upstream has $n"; else echo "  FAIL T upstream has no $n"; fails=$((fails + 1)); fi
  done <<<"$names"
fi

# migrate-layout copies the Paths table. Each team path in it must also be in the overrides.
mig="$CLAUDE_PLUGIN_ROOT/skills/migrate-layout/SKILL.md"
while IFS= read -r path; do
  if grep -qF "$path" "$CLAUDE_PLUGIN_ROOT/rules/PROCESS-OVERRIDES.md"; then echo "  ok   P overrides has $path"; else echo "  FAIL P overrides has no $path"; fails=$((fails + 1)); fi
done < <(grep '^| ' "$mig" | grep -oE '\.claude-work/[^`]+' | sort -u)
while IFS= read -r path; do
  if grep -qF "$path" "$mig"; then echo "  ok   P skill has $path"; else echo "  FAIL P migrate-layout has no $path"; fails=$((fails + 1)); fi
done < <(grep '^| ' "$CLAUDE_PLUGIN_ROOT/rules/PROCESS-OVERRIDES.md" | grep -oE '\.claude-work/[^`]+' | grep -v '^\.claude-work/docs/adr/' | sort -u)

((fails == 0))
