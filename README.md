# agent-skills-jksim

A Claude Code plugin for the team. It gives each project the same engineering process: spec, plan, build, test, review, ship.

The process skills come from the upstream plugin [agent-skills](https://github.com/addyosmani/agent-skills) by Addy Osmani. The `jksim` marketplace lists it as `agent-skills@jksim`, pinned to one upstream commit. This plugin depends on it and changes its defaults to the team rules. Use the upstream commands: `/agent-skills:spec`, `/agent-skills:plan`, `/agent-skills:build` and the others.

## What it does

- Loads Jarrett's rules (`rules/JARRETTS-RULES.md`) into each session and subagent. The rules load again after `/clear` and compaction.
- Warns when a `git commit` message is too long or looks like a fix-up. It does not block.
- Skills: `simplified-english` (rule 1 guide), `commit-hygiene` (rule 4 guide).
- Loads the team overrides (`rules/PROCESS-OVERRIDES.md`) for the upstream skills: working-file paths in `.claude-work/`, the vocabulary step, send-back, squashing fix-up commits, and the handoff note.
- Repeats the relevant override when an upstream skill or command starts.
- Blocks the creation of upstream root working files (`SPEC.md`, `tasks/plan.md`, `CONSTRAINTS.md`, `docs/decisions/`, …) and gives the team path. Existing root files are not blocked.

## Install in a project

1. Merge `templates/consumer-settings.json` into the project's `.claude/settings.json`.
2. Commit `.claude/settings.json`.
3. Each team member opens the project in Claude Code and accepts the folder trust dialog. Claude Code then adds the `jksim` marketplace and installs `agent-skills-jksim` and its dependency `agent-skills@jksim`. There is no separate install prompt. Check with `/plugin`.

The template turns off `agent-skills@addy-agent-skills` in the project. If a project merged an older template, remove its `addy-agent-skills` entry from `extraKnownMarketplaces`. Two copies of `agent-skills` would load every skill twice. In other projects, an `addy-agent-skills` install still works as before.

### If agent-skills-jksim fails to load

The plugin needs `agent-skills@jksim`. When the dependency is missing or disabled, Jarrett's rules and the hooks do not load.

1. Run `/plugin`. Open the **Errors** tab.
2. If `agent-skills@jksim` is missing, run `claude plugin install agent-skills-jksim@jksim` in the project folder.
3. If `agent-skills` is disabled, enable it.
4. Run `/reload-plugins`.

If the Errors tab shows `Plugin "agent-skills-jksim" not cached at <path>`, run `claude plugin install agent-skills-jksim@jksim` in the project folder. Then run `/reload-plugins`.

Do not run `claude plugin marketplace add --scope project` in a consumer project. It rewrites `.claude/settings.json` and removes `autoUpdate`.

Working files (specs, tasks, vocabulary, ADRs) go in `.claude-work/`. Commit them, so that teammates can continue the work. Do not put them in `.claude/`. Claude Code protects `.claude/`. Allow rules cannot override this. Writes there can be denied or need approval.

## Update the upstream pin

The team gets upstream changes only when the pin changes.

1. Compare the pinned commit with upstream: `https://github.com/addyosmani/agent-skills/compare/<pinned-sha>...main`.
2. Read the diff. Look closely at new or changed `hooks/`, `.mcp.json`, `bin/`, `agents/` and `skills/**/scripts`. These run code on each machine.
3. Check out upstream at the new SHA in `../agent-skills`, or set `UPSTREAM_DIR` to that checkout. Then `./scripts/test.sh` checks that the names in `scripts/skill-overrides.sh` still exist. Without that checkout, the check prints "skip".
4. Put the new SHA in the `agent-skills` entry of `.claude-plugin/marketplace.json`.
5. Bump `version` in `.claude-plugin/plugin.json`. Run `./scripts/test.sh` and `./scripts/e2e-smoke.sh`. Push.
6. In a consumer project, check with `/plugin` that `agent-skills@jksim` shows the new commit. If upstream did not change its own `version`, Claude Code may keep the old copy. Then run `claude plugin update agent-skills@jksim`.

## Private repo access

The repo is private. Claude Code uses the git credentials on your machine. It cannot prompt for them. Use one of these:

- HTTPS: run `gh auth login`, then `gh auth setup-git`. Set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` if you have no GitHub SSH key.
- SSH: load your key in `ssh-agent`. Add `github.com` to `known_hosts`.

## Update

The template turns on background auto-update. To update now, in a session: `/plugin marketplace update jksim`. Or in a shell: `claude plugin update agent-skills-jksim@jksim`.

You get a new copy only when `version` in `.claude-plugin/plugin.json` changes. An update that arrives during a session applies after `/reload-plugins` or at the next start.

Background update cannot prompt for credentials. If your credential helper needs to prompt, the update fails with no message. Store a credential first (see Private repo access).

If you turn off auto-update in `/plugin`, Claude Code writes that to the project's `.claude/settings.json`. Do not commit that change.

## Develop

```bash
./scripts/test.sh                          # validate, shellcheck, hooks, manifests, hook tests
./scripts/e2e-smoke.sh                     # opt-in: 5 real sessions; run before each release
claude --plugin-dir <path-to-this-repo>    # load this copy over the installed one
```

`e2e-smoke.sh` loads upstream from `../agent-skills` or `UPSTREAM_DIR` when it exists, else the installed copy.

After an edit, run `/reload-plugins` in the session.

Do not add this repo as a local marketplace. Its name `jksim` collides with the GitHub marketplace.

## License

MIT. See `LICENSE` and `NOTICE.md`.
