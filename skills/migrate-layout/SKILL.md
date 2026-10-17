---
name: migrate-layout
description: Moves an in-flight project's agent-skills working files (SPEC.md, tasks/plan.md, tasks/todo.md, CONSTRAINTS.md, …) from the upstream root paths to the team paths in .claude-work/. Use when a project started before agent-skills-jksim was installed, or when root working files and .claude-work/ both exist.
disable-model-invocation: true
argument-hint: "[id]"
---

# Migrate Layout

## Overview

Upstream agent-skills keeps working files at the project root. The team keeps them in `.claude-work/` (see the Paths table in the team overrides). This skill moves an in-flight project to the team layout in one commit. Each file keeps its git history. Task checkboxes move with the files, so the work continues where it stopped.

The argument is the `<id>` for the plan and task files, for example `/agent-skills-jksim:migrate-layout fl-debug`.

## When to Use

- A project has `SPEC.md`, `tasks/plan.md`, `tasks/todo.md` or `CONSTRAINTS.md` at its root.
- A project has both root working files and `.claude-work/`.

Do not use it for a new project. The spec stage writes to `.claude-work/` from the start.

## Process

### 1. Check the start state

Stop and tell the user when one of these is true:
- The folder is not a git repository.
- `git status --porcelain --untracked-files=all` shows changes. Ask the user to commit or stash them first.
- `git check-ignore -q .claude-work/spec/SPEC.md` succeeds. Check a file path: a pattern such as `.claude-work/` does not match the folder before it exists. Consumer projects commit `.claude-work/`.

### 2. Find the old files

Look only at these paths, relative to the project root:

| Old path | Team path |
|---|---|
| `SPEC.md`, `docs/SPEC.md` | `.claude-work/spec/SPEC.md` |
| `SPEC-<module>.md` | `.claude-work/spec/SPEC-<module>.md` |
| `CAPABILITY-MAP.md` | `.claude-work/spec/CAPABILITY-MAP.md` |
| `tasks/plan.md` | `.claude-work/tasks/plan-<id>.md` |
| `tasks/todo.md` | `.claude-work/tasks/todo-<id>.md` |
| `CONSTRAINTS.md` | `.claude-work/docs/CONSTRAINTS.md` |
| `docs/ideas/<name>.md` | `.claude-work/docs/ideas/<name>.md` |
| `docs/intent/<topic>.md` | `.claude-work/docs/intent/<topic>.md` |
| `docs/decisions/` | Stays. Ask (see step 4) |

Do not touch `spec/`. RSpec and other test layouts use it.

Use only files that git tracks (`git ls-files`). `git mv` fails on other files. Name any untracked or ignored old file and ask the user.

When no old file exists, tell the user that there is nothing to migrate. Stop.

### 3. Get the `<id>`

Use the argument. With no argument, suggest a short kebab-case id from the project name and ask the user. Skip this step when there is no `tasks/plan.md` or `tasks/todo.md`.

### 4. Show the plan and wait for approval

Show one table: old path, new path. Then list each conflict and ask about it:
- **Target exists:** a file is already at the team path. Do not move that file. Ask what to do.
- **Two specs:** both `SPEC.md` and `docs/SPEC.md` exist. Ask which one is the spec.
- **Other files in `tasks/`:** move only `plan.md` and `todo.md`. Name the other files.
- **`docs/decisions/` exists:** the default is to keep it, because a project keeps its own ADR folder. Move it to `.claude-work/docs/adr/` only when the user says so.

Do not move anything until the user approves the table.

### 5. Move with `git mv`

Run `git mv <old> <new>` for each file. Make the target folders first (`mkdir -p`). Never copy and delete: `git mv` keeps the history. If `tasks/` is now empty, run `rmdir tasks`.

### 6. Fix live references

Search the project for the old paths: `git grep -n -E 'SPEC(-[A-Za-z0-9_-]+)?\.md|CAPABILITY-MAP\.md|CONSTRAINTS\.md|tasks/(plan|todo)\.md|docs/(ideas|intent|decisions)/'`.

A **live reference** tells a reader or the agent where the file is now. Change it:
- `CLAUDE.md`: "`SPEC.md`: approved spec" becomes "`.claude-work/spec/SPEC.md`: approved spec".
- `README.md`: `[SPEC.md](SPEC.md)` becomes `[SPEC.md](.claude-work/spec/SPEC.md)`.
- A relative link in a moved file: `../SPEC.md` in the old `tasks/plan.md` becomes `../spec/SPEC.md` in `.claude-work/tasks/plan-<id>.md`.
- The constraints pointer line in `CLAUDE.md`.
- Other relative links in each moved file. A moved file is at a new depth, so a link to a file that did not move also breaks. Example: `[x](src/a.kt)` in the root `SPEC-foo.md` becomes `[x](../../src/a.kt)` in `.claude-work/spec/SPEC-foo.md`.

A **record** tells what happened at a past time. Leave it as it is:
- A finished task entry: "**Files:** README.md, SPEC.md".
- A change log, a review note or a commit message.

When you are not sure, leave the text and list it in step 7.

### 7. Show the result

Show `git status`, the diff of the changed references, and a list of the old-path references that you did not change, with the reason for each.

### 8. Commit once

`git mv` already staged the moves. Stage the edited references with `git add -u`. Do not use `git add -A`: it can add unrelated files. Commit with the message `Move working files to .claude-work`. Do not push.

If a hook rejects the commit, stop and report it. Do not use `--no-verify`.

### 9. Report the next step

Tell the user which files moved and which stayed. If `.claude-work/docs/VOCABULARY.md` does not exist, say that the next spec stage makes it (rule 2). Do not make it now.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Copying is simpler than `git mv`." | A copy loses the file history. Reviewers and `git log --follow` need it. |
| "I will update every mention of `SPEC.md`." | Records describe the past. Changing them rewrites history. |
| "The tree is only a little dirty." | Uncommitted work ends up in the migration commit. Ask the user first. |
| "The plan is obvious, so I will skip the approval." | The user decides the `<id>` and each conflict. Wait. |

## Red Flags

- `git log --follow` shows no history before the migration commit.
- A finished task entry or a change log names a team path that did not exist then.
- `spec/` or `docs/decisions/` moved without the user's approval.
- More than one commit, or a push.

## Verification

- [ ] Each old file is at its team path. No old file is left at the root, except those the user chose to keep.
- [ ] `git log --follow <new path>` shows the old history.
- [ ] Live references point to the team paths. Records are unchanged.
- [ ] Task checkboxes are unchanged.
- [ ] One commit, `Move working files to .claude-work`. `git status` is clean. Nothing pushed.
