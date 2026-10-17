# agent-skills-jksim

A Claude Code plugin for the team. It gives each project the same engineering process: spec, plan, build, test, review, ship.

The process skills come from the upstream plugin [`agent-skills@addy-agent-skills`](https://github.com/addyosmani/agent-skills). This plugin depends on it and changes its defaults to the team rules. Use the upstream commands: `/agent-skills:spec`, `/agent-skills:plan`, `/agent-skills:build` and the others.

## What it does

- Loads Jarrett's rules (`rules/JARRETTS-RULES.md`) into each session and subagent. The rules load again after `/clear` and compaction.
- Warns when a `git commit` message is too long or looks like a fix-up. It does not block.
- Skills: `simplified-english` (rule 1 guide), `commit-hygiene` (rule 4 guide).
- Loads the team overrides (`rules/PROCESS-OVERRIDES.md`) for the upstream skills: working-file paths in `.claude-work/`, the vocabulary step, send-back, and squashing fix-up commits.
- Repeats the relevant override when an upstream skill or command starts.
- Blocks the creation of upstream root working files (`SPEC.md`, `tasks/plan.md`, `CONSTRAINTS.md`, `docs/decisions/`, …) and gives the team path. Existing root files are not blocked.

## Install in a project

1. Merge `templates/consumer-settings.json` into the project's `.claude/settings.json`.
2. Commit `.claude/settings.json`.
3. Each team member opens the project in Claude Code and accepts the folder trust dialog. Claude Code then adds the `jksim` and `addy-agent-skills` marketplaces and enables both plugins. There is no separate install prompt. Check with `/plugin`.

Both marketplaces must be registered. If `addy-agent-skills` is missing, the dependency does not install, and `agent-skills-jksim` fails to load. The template registers both.

### If agent-skills-jksim fails to load

The plugin needs `agent-skills@addy-agent-skills`. When the dependency is missing or disabled, Jarrett's rules and the hooks do not load.

1. Run `/plugin`. Open the **Errors** tab.
2. If the `addy-agent-skills` marketplace is missing, merge the template again and restart the session.
3. If `agent-skills` is disabled, enable it.
4. Run `/reload-plugins`.

If the Errors tab shows `Plugin "agent-skills-jksim" not cached at <path>`, run `claude plugin install agent-skills-jksim@jksim` in the project folder. Then run `/reload-plugins`.

Do not run `claude plugin marketplace add --scope project` in a consumer project. It rewrites `.claude/settings.json` and removes `autoUpdate`.

Working files (specs, tasks, vocabulary, ADRs) go in `.claude-work/`. Do not put them in `.claude/`. Claude Code protects `.claude/`. Allow rules cannot override this. Writes there can be denied or need approval.

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
./scripts/test.sh                          # validate, shellcheck, hook commands, hook tests
claude --plugin-dir <path-to-this-repo>    # load this copy over the installed one
```

After an edit, run `/reload-plugins` in the session.

Do not add this repo as a local marketplace. Its name `jksim` collides with the GitHub marketplace.

## License

MIT. See `LICENSE` and `NOTICE.md`.
