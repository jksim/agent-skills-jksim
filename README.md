# agent-skills-jksim

A Claude Code plugin for the team. It gives every project the same engineering process (spec, plan, build, test, review, ship) and the same working rules.

The process skills come from [agent-skills](https://github.com/addyosmani/agent-skills) by Addy Osmani. This plugin installs them for you and adapts them to the team rules.

> This is a personal team setup, shared as is. It comes with no warranty and no support. See the MIT [LICENSE](LICENSE).

## Before you start

You need these on your machine:

| Need | Check | Fix |
|---|---|---|
| Claude Code (tested with 2.1.302) | `claude --version` | `claude update` |
| `jq` | `jq --version` | `sudo apt install jq` or `brew install jq` |
| `git` | `git --version` | `sudo apt install git` or `brew install git` |

## Add the plugin to a project

One person does this once for each project. Start Claude Code in the project's root folder (`claude`) and do these steps in the session.

1. Add the marketplace for the project:

   ```text
   ! claude plugin marketplace add jksim/agent-skills-jksim --scope project
   ```

   The `!` runs the command in your shell. Use the shell form: `/plugin marketplace add` adds the marketplace only for you, not for the project.
2. Install the plugin:

   ```text
   /plugin install agent-skills-jksim@jksim
   ```

   Choose **Install for all collaborators on this repository**. Claude Code also installs the dependency `agent-skills@jksim`.
3. Ask Claude to make two edits in `.claude/settings.json`. The `/plugin` panel cannot set them for the project. For example, type:

   > In .claude/settings.json, add "autoUpdate": true to the jksim marketplace entry, and add "agent-skills@addy-agent-skills": false to enabledPlugins.

   Claude Code asks you to approve the edit, because `.claude/` is a protected folder.
   - `autoUpdate` gives each teammate updates without a manual step.
   - The `false` entry turns off Addy's own copy of `agent-skills` in this project only. Without it, teammates who have Addy's plugin installed see every skill twice. Do not disable Addy's plugin in the `/plugin` panel: that turns it off in all your projects.

   The result:

   ```json
   {
     "enabledPlugins": {
       "agent-skills-jksim@jksim": true,
       "agent-skills@jksim": true,
       "agent-skills@addy-agent-skills": false
     },
     "extraKnownMarketplaces": {
       "jksim": {
         "source": { "source": "github", "repo": "jksim/agent-skills-jksim" },
         "autoUpdate": true
       }
     }
   }
   ```

   Other keys in the file stay as they are. The same settings are in [`templates/consumer-settings.json`](templates/consumer-settings.json).
4. Run `/reload-plugins`. Then commit `.claude/settings.json` and push.

If you run `claude plugin marketplace add` again later, check that `"autoUpdate": true` is still there. The command rewrites the `jksim` entry.

## Start using it

Each team member does this once for each project.

1. Pull the project and start Claude Code in its root folder: `claude`.
2. Accept the folder trust dialog. There is no other install prompt.
3. Wait a few seconds, then run `/reload-plugins`. Claude Code installs the plugins in the background the first time. A new session also works.
4. Run `/plugin` and check:
   - `agent-skills-jksim@jksim` is enabled.
   - `agent-skills@jksim` is enabled.
   - `agent-skills@addy-agent-skills` is disabled (only if you have it installed elsewhere).
   - The **Errors** tab is empty.

## Daily use

Start each piece of work at the spec stage and follow the stages in order:

| Stage | Command |
|---|---|
| Spec | `/agent-skills:spec` |
| Plan | `/agent-skills:plan` |
| Build | `/agent-skills:build` |
| Test | `/agent-skills:test` |
| Review | `/agent-skills:review` |
| Ship | `/agent-skills:ship` |

The plugin works in the background:

- Every session and subagent gets Jarrett's rules ([`rules/JARRETTS-RULES.md`](rules/JARRETTS-RULES.md)). They load again after `/clear` and compaction.
- Working files go in `.claude-work/`: specs in `spec/`, plans and task lists in `tasks/`, the vocabulary and ADRs in `docs/`. Commit this folder, so that teammates can continue the work.
- When the agent tries to create `SPEC.md`, `tasks/plan.md` or `CONSTRAINTS.md` at the project root, the plugin stops it and gives the `.claude-work/` path. Root files that already exist are not affected.
- When a commit message is too long or looks like a fix-up (`wip`, `fix typo`), the agent gets a warning. The commit is not blocked.

Two extra skills: `/agent-skills-jksim:simplified-english` (writing style, rule 1) and `/agent-skills-jksim:commit-hygiene` (commits, rule 4).

Do not put working files in `.claude/`. Claude Code protects that folder and asks before writes there.

## Updates

Updates install in the background. A new version loads at your next session, or after `/reload-plugins`.

To update now, run `claude plugin update agent-skills-jksim@jksim` in a shell.

If you turn off auto-update in `/plugin`, Claude Code writes that to `.claude/settings.json`. Do not commit that change.

## Troubleshooting

| Problem | Fix |
|---|---|
| `/plugin` does not show the plugins | Check that you trusted the folder and started Claude Code in the project root. Run `/reload-plugins`. |
| `agent-skills-jksim` failed to load | It needs `agent-skills@jksim`. Run `claude plugin install agent-skills-jksim@jksim` in the project folder, then `/reload-plugins`. |
| `Plugin "agent-skills-jksim" not cached at <path>` | Run `claude plugin install agent-skills-jksim@jksim` in the project folder, then `/reload-plugins`. |
| Each `/agent-skills:` skill shows twice | `.claude/settings.json` is missing `"agent-skills@addy-agent-skills": false`. Add it and commit the change. Do not disable Addy's plugin in `/plugin`: that turns it off in all your projects. If the file still lists an `addy-agent-skills` marketplace, remove that entry. |
| `jq not found. Rules not loaded.` | Install `jq`, then start a new session. |
| Adding the marketplace or an update fails with an SSH error | Claude Code uses SSH when your GitHub SSH key works. Set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` in your shell profile to use HTTPS, then start a new session. |

## Maintainers

See [MAINTAINING.md](MAINTAINING.md) to change the plugin, run the tests, release a version or update the upstream pin.

## License

MIT. See [`LICENSE`](LICENSE) and [`NOTICE.md`](NOTICE.md).
