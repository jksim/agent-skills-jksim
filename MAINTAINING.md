# Maintaining agent-skills-jksim

For people who change, test or release the plugin. Users read [README.md](README.md).

## Layout

| Path | Content |
|---|---|
| `.claude-plugin/plugin.json` | Plugin manifest: version, dependency on `agent-skills` |
| `.claude-plugin/marketplace.json` | The `jksim` marketplace: this plugin, and upstream `agent-skills` pinned by SHA |
| `rules/JARRETTS-RULES.md` | The rules text. Loaded into each session and subagent |
| `rules/PROCESS-OVERRIDES.md` | Team overrides for the upstream skills |
| `hooks/hooks.json` | Hook registrations |
| `scripts/*.sh` | Hook scripts, each with a `*-test.sh` |
| `skills/` | `simplified-english`, `commit-hygiene` |
| `templates/consumer-settings.json` | The settings users add to a project |

## Develop

```bash
./scripts/test.sh                          # validate, shellcheck, hooks, manifests, hook tests
./scripts/e2e-smoke.sh                     # opt-in: real sessions; run before each release
claude --plugin-dir <path-to-this-repo>    # load this copy over the installed one
```

After an edit, run `/reload-plugins` in the session.

`e2e-smoke.sh` loads upstream from `../agent-skills` or `UPSTREAM_DIR` when it exists, else the installed copy.

Do not add this repo as a local marketplace. Its name `jksim` collides with the GitHub marketplace.

## Release

1. Bump `version` in `.claude-plugin/plugin.json`. Users get a new copy only when the version changes.
2. Run `./scripts/test.sh` and `./scripts/e2e-smoke.sh`.
3. Push, then tag: `claude plugin tag --push`.

A README-only change needs no version bump.

To roll back: `git revert` the bad commit, set a version **higher** than the bad one, and push. Users get it at their next session.

## Update the upstream pin

The team gets upstream changes only when the pin changes.

1. Compare the pinned commit with upstream: `https://github.com/addyosmani/agent-skills/compare/<pinned-sha>...main`.
2. Read the diff. Look closely at new or changed `hooks/`, `.mcp.json`, `bin/`, `agents/` and `skills/**/scripts`. These run code on each machine.
   Also check `commands/` and `.claude/commands/`: a `` !` `` line runs shell when the command loads. In all frontmatter, look for `allowed-tools`, `hooks`, `mcpServers` and `permissionMode`.
3. Check out upstream at the new SHA in `../agent-skills`, or set `UPSTREAM_DIR` to that checkout. Then `./scripts/test.sh` checks that the names in `scripts/skill-overrides.sh` still exist. Without that checkout, the check prints "skip".
4. Put the new SHA in the `agent-skills` entry of `.claude-plugin/marketplace.json`.
5. Release as above.
6. In a consumer project, check with `/plugin` that `agent-skills@jksim` shows the new commit. If upstream did not change its own `version`, Claude Code may keep the old copy. Then run `claude plugin update agent-skills@jksim`.
