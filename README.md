# agent-skills-jksim

A Claude Code plugin for the team. It gives each project the same engineering process: spec, plan, build, test, review, ship.

## What it does

- Loads Jarrett's rules (`rules/JARRETTS-RULES.md`) into each session and subagent. The rules load again after `/clear` and compaction.
- Warns when a `git commit` message is too long or looks like a fix-up. It does not block.
- Skills: `simplified-english` (rule 1 guide), `commit-hygiene` (rule 4 guide).

## Install in a project

1. Merge `templates/consumer-settings.json` into the project's `.claude/settings.json`.
2. Commit `.claude/settings.json`.
3. Each team member opens the project in Claude Code and accepts the folder trust dialog. Claude Code then adds the `jksim` marketplace and enables the plugin. There is no separate install prompt. Check with `/plugin`.

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
