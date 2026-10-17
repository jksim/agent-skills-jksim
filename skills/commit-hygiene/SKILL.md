---
name: commit-hygiene
description: Keeps commits few and messages short. Use before a commit, before a push, when commits pile up during a fix, or when the commit-check hook warns.
---

# Commit Hygiene

## Overview

Rule 4 of Jarrett's rules: comments are short. A change has only the commits that it logically needs. A reviewer reads one clean commit for each change, not a history of attempts.

The `commit-check` hook warns when a `git commit` message breaks the limits. It does not block. You fix the commit.

## When to Use

- Before each commit.
- Before each push.
- When you made more than one commit to fix one issue.
- When the `commit-check` hook warns.

## Process

### 1. Write the message

- Subject: 72 characters or fewer. Use the imperative: "Add rules hook", not "Added rules hook".
- Body: 5 lines or fewer. Leave it out when the subject is enough.
- Say what changed and why. Do not describe each file.
- Use simplified English. See the `simplified-english` skill.

### 2. Make one commit for each logical change

- One logical change: a feature slice, a fix or a refactor that a reviewer can accept or reject as one unit.
- Do not mix a refactor and a behavior change in one commit.
- Do not commit each attempt. Commit when the change works and the tests pass.

### 3. Squash fix-up commits before push

A fix-up commit corrects an earlier commit in the same change. Examples: "fix typo", "wip", "address review".

1. Make the fix-up commit with `git commit --fixup <sha>`.
2. Squash it without an editor: `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`.
3. If the rebase stops on a conflict, fix the files and run `git add <files>`. Then run `GIT_EDITOR=true git rebase --continue`. To stop, run `git rebase --abort`.
4. Run the tests again.
5. Check the result: `git log --oneline <base>..HEAD`.

If the last commit is the one to fix, use `git commit --amend --no-edit`.

Warning: do not rewrite commits that are already on a shared branch. Ask the user first. A rewrite forces each teammate to reset.

### 4. Keep comments short

- Write a comment only when the code is not clear.
- One line is usually enough. Say why, not what.
- Do not write change history in comments. Git keeps the history.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Small commits show my progress." | The reviewer needs the result, not the path. Squash the attempts. |
| "A long message gives more context." | Long messages are not read. Put the context in the spec or the PR. |
| "I will squash later." | Later is after push. Squash before push. |
| "The hook only warns, so the limit is optional." | The limit is a team rule. The hook warns so that you can fix it. |

## Red Flags

- `git log` shows "wip", "fix", "oops" or "try again" before push.
- More than one commit for one bug fix.
- A commit body that lists each changed file.
- Comments that repeat what the code says.

## Verification

- [ ] Each subject is 72 characters or fewer and uses the imperative.
- [ ] Each body is 5 lines or fewer.
- [ ] `git log --oneline <base>..HEAD` shows one commit for each logical change.
- [ ] No fix-up commits are left before push.
- [ ] Tests pass after any rebase.

Known limit: the hook does not check `git -C <dir> commit` or `git -c <key>=<value> commit`. It also skips some messages it cannot read, for example `-F <file>`.
