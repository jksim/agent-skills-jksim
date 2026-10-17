# Team overrides for agent-skills

This team uses the agent-skills plugin (`agent-skills:` skills and commands). Where an agent-skills default conflicts with Jarrett's rules or with this list, Jarrett's rules and this list apply.

## Paths
Working files go in `.claude-work/`. The upstream paths change as follows:

| agent-skills default | Team path |
|---|---|
| `SPEC.md`, `docs/SPEC.md`, `spec/` | `.claude-work/spec/SPEC.md` |
| `SPEC-<module>.md` | `.claude-work/spec/SPEC-<module>.md` |
| Capability map | `.claude-work/spec/CAPABILITY-MAP.md` |
| `tasks/plan.md` | `.claude-work/tasks/plan-<id>.md` |
| `tasks/todo.md` | `.claude-work/tasks/todo-<id>.md` |
| `CONSTRAINTS.md` | `.claude-work/docs/CONSTRAINTS.md` |
| `docs/decisions/` (ADRs) | `.claude-work/docs/adr/` |
| `docs/ideas/<name>.md` | `.claude-work/docs/ideas/<name>.md` |
| `docs/intent/<topic>.md` | `.claude-work/docs/intent/<topic>.md` |

`<id>` is the module id from the capability map. With no map, `<id>` is a short kebab-case feature id.
A project that already has its own ADR folder keeps it.
Consumer projects commit `.claude-work/`.
`/agent-skills:build` finds the spec and plan at the team paths. It counts changes in `.claude-work/` as planning files, the same as upstream `SPEC.md` and `tasks/`.
The constraints pointer line in `CLAUDE.md` names `.claude-work/docs/CONSTRAINTS.md`.
When a request has several modules, the spec stage makes the capability map at `.claude-work/spec/CAPABILITY-MAP.md` before any module spec.

## Spec stage: vocabulary
The spec stage makes or updates `.claude-work/docs/VOCABULARY.md`. Each term has one meaning.
When a request is ambiguous, the agent asks questions first. Then it adds the term to the vocabulary.

## Send back (rule 0)
When a later stage finds that an earlier stage is wrong, the agent stops. It tells the user which stage is wrong and why. It updates that stage's file with the user. Then it continues.
Examples: a test shows that the spec is wrong. A review finds a missing task.

## Commits (rule 4)
Rule 4 applies over the `git-workflow-and-versioning` advice against squashing. The team squashes fix-up commits into the commit they fix before push. Each logical change keeps its own commit.

## Handoff
The todo file shows the current state: checked tasks and a short "Next" note. A teammate continues from the spec, the plan, the todo file and `git log`.
