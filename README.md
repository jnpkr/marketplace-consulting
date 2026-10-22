# marketplace-consulting

A public Claude Code plugin marketplace with skills for consulting work. Each skill is a separate plugin, so you can install only the skills a client has approved.

The marketplace is named `consulting`, and you install a skill as `<skill>@consulting`. Each plugin entry points to the skill's own upstream repository and is pinned to a reviewed commit.

## Skills

| Skill | What it does | Upstream | Licence |
| --- | --- | --- | --- |
| `plain-writing` | Writes and edits prose in a plain style, with simple everyday words and complete sentences | [`docwriter-org/plain-writing-skill`](https://github.com/docwriter-org/plain-writing-skill), folder `skills/plain-writing` | MIT, Shreya Shankar |
| `writing-for-agents` | Gives guidance for writing documents that agents read, e.g., skills, `AGENTS.md` and `CLAUDE.md` | [`mattpocock/skills`](https://github.com/mattpocock/skills), folder `skills/productivity/writing-for-agents` | MIT, Matt Pocock |
| `dictation-fixes` | Flags words that were probably transcribed wrong and suggests adding the fix to the dictation app's dictionary | [`jnpkr/skill-dictation-fixes`](https://github.com/jnpkr/skill-dictation-fixes) | None |

Each upstream folder has `SKILL.md` at its root, so Claude Code loads each plugin as a single skill. An install fetches only the skill folder, so each marketplace entry names the author and licence.

## Install on a client machine

The marketplace and every skill source are public repositories on github.com, so any machine with `git` and access to github.com can install them.

First, set `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1` in the shell environment on any machine that has no GitHub SSH key. Claude Code then clones over HTTPS, and installs and updates from inside a session work.

Second, add the marketplace in a Claude Code session.

```text
/plugin marketplace add jnpkr/marketplace-consulting
```

Third, install each skill the client has approved, one command per skill.

```text
/plugin install plain-writing@consulting
```

From a shell, use `claude plugin marketplace add jnpkr/marketplace-consulting` and `claude plugin install <skill>@consulting` instead.

## Updates

Turn on auto-update so the machine picks up new pins after each session starts. In `/plugin`, open Marketplaces, select `consulting`, and select Enable auto-update. To update by hand, run `/plugin marketplace update consulting`.

## Client allowlists

If the client sets `strictKnownMarketplaces` in managed settings, the client's admin adds this entry to the list.

```json
{ "source": "github", "repo": "jnpkr/marketplace-consulting" }
```

The machine also needs network access to github.com, where every skill source is hosted.

## Distribute through claude.ai organization settings

Organization sync reads a private or internal repository that the client's organization owns. To use it, the client keeps a private copy of this repository in its own GitHub organization and syncs that copy.

1. The client creates a private repository in its GitHub organization with the contents of this repository.
2. A client Owner opens Organization settings, then Plugins & skills, selects Add, then Sync from GitHub, and chooses the private copy.
3. To take new pins, the client pulls changes from `jnpkr/marketplace-consulting` into the copy. With automatic sync on, each push to the copy's default branch starts a sync.

Every skill source is a public repository on github.com, so organization sync fetches each one directly from GitHub.

Not yet tested: whether organization sync installs the commit named by `sha` or the head of `ref`.

## Maintain the marketplace

A GitHub Actions workflow, `.github/workflows/upstream-bump.yml`, checks each upstream every Monday at 07:00 UTC. You can also run it by hand from the Actions tab.

For each entry, the workflow reads the current head of the entry's `ref`. When the head differs from the pinned `sha`, the workflow opens a pull request on a `bump/<skill>` branch that moves the pin. The pull request links the upstream compare view and lists the files that changed inside the pinned folder.

To release an update, review the upstream changes in the pull request and merge it. Machines with auto-update on install the new pin on their next update.

To add a skill, add an entry to `.claude-plugin/marketplace.json` with a `github` or `git-subdir` source, a `ref`, and a full 40 character `sha`. Keep any executables in a `scripts/` folder, because organization sync rejects a plugin with a top-level `bin/` folder. Then run `claude plugin validate .` and install the skill locally to check it loads.

GitHub turns off scheduled workflows in a public repository after 60 days without activity. Merging a bump pull request counts as activity, and you can turn the workflow back on from the Actions tab.
