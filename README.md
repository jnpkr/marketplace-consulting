# marketplace-consulting

A public Claude plugin marketplace with skills for consulting work. You can use it in Cowork, in chat on claude.ai and the desktop app, and in Claude Code. Each skill is a separate plugin, so you can install only the skills a client has approved.

The marketplace is named `consulting`, and each plugin has the same name as its skill. Each plugin entry points to the skill's own upstream repository and is pinned to a reviewed commit.

## Skills

| Skill | What it does | Upstream | Licence |
| --- | --- | --- | --- |
| `plain-writing` | Writes and edits prose in a plain style, with simple everyday words and complete sentences | [`docwriter-org/plain-writing-skill`](https://github.com/docwriter-org/plain-writing-skill), folder `skills/plain-writing` | MIT, Shreya Shankar |
| `writing-for-agents` | Gives guidance for writing documents that agents read, e.g., skills, `AGENTS.md` and `CLAUDE.md` | [`mattpocock/skills`](https://github.com/mattpocock/skills), folder `skills/productivity/writing-for-agents` | MIT, Matt Pocock |
| `dictation-fixes` | Flags words that were probably transcribed wrong and suggests adding the fix to the dictation app's dictionary | [`jnpkr/skill-dictation-fixes`](https://github.com/jnpkr/skill-dictation-fixes) | None |

Each upstream folder has `SKILL.md` at its root, so each plugin loads as a single skill. An install fetches only the skill folder, so each marketplace entry names the author and licence.

## Install in Cowork or chat

Cowork and chat read plugins from your claude.ai account, so you add the marketplace once for each account you sign in with.

1. In the desktop app or on claude.ai, open Customize, then Plugins, and select Add marketplace.
2. Enter `jnpkr/marketplace-consulting`.
3. Install each skill the client has approved.

A plugin you install this way is saved to your account, so it also loads in chat and in Claude Code sessions where you sign in with the same account.

To take updates, select Check for updates on the `consulting` marketplace, or turn on Sync automatically.

In a client's Team or Enterprise organization, the Add marketplace option appears when the client's Owner has turned on User-created skills in Organization settings, under Plugins & skills, then Policy.

Not yet tested: whether a marketplace added in Cowork installs `git-subdir` entries, and whether it installs the commit named by `sha`.

## Install in Claude Code

Claude Code reads plugins from the machine it runs on. The marketplace and every skill source are public repositories on github.com, so any machine with `git` and access to github.com can install them.

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

To take updates automatically, open `/plugin`, go to Marketplaces, select `consulting`, and select Enable auto-update. To update by hand, run `/plugin marketplace update consulting`.

If the client sets `strictKnownMarketplaces` in Claude Code managed settings, the client's admin adds this entry to the list.

```json
{ "source": "github", "repo": "jnpkr/marketplace-consulting" }
```

## Distribute to a whole client organization

A client's Owner can give the skills to every member through Organization settings on claude.ai. Members then get them in chat, in Cowork, and in Claude Code sessions that sign in with their account.

Organization sync reads a private or internal repository that the client's organization owns, so the client keeps a private copy of this repository in its own GitHub organization and syncs that copy.

1. The client creates a private repository in its GitHub organization with the contents of this repository.
2. A client Owner opens Organization settings, then Plugins & skills, selects Add, then Sync from GitHub, and chooses the private copy.
3. The Owner sets each skill's availability, e.g., Available to install or Installed by default.
4. To take new pins, the client pulls changes from `jnpkr/marketplace-consulting` into the copy. With Sync automatically on, each push to the copy's default branch starts a sync.

Every skill source is a public repository on github.com, so organization sync fetches each one directly from GitHub.

Not yet tested: whether organization sync installs the commit named by `sha` or the head of `ref`.

## Maintain the marketplace

A GitHub Actions workflow, `.github/workflows/upstream-bump.yml`, checks each upstream every Monday at 07:00 UTC. You can also run it by hand from the Actions tab.

For each entry, the workflow reads the current head of the entry's `ref`. When the head differs from the pinned `sha`, the workflow opens a pull request on a `bump/<skill>` branch that moves the pin. The pull request links the upstream compare view and lists the files that changed inside the pinned folder.

To release an update, review the upstream changes in the pull request and merge it. Each install then picks up the new pin on its next update.

To add a skill, add an entry to `.claude-plugin/marketplace.json` and copy the shape of the existing entries.

- Source: use a `github` source when the skill is a whole repository, or a `git-subdir` source when it's a folder inside a larger repository. Write a `git-subdir` URL in full, e.g., `https://github.com/owner/repo.git`, because claude.ai accepts only `https://` URLs.
- Pin: set `ref` to the branch and `sha` to the full 40 character commit.
- Manifest: set `"strict": false` and `"skills": ["./"]`, so the entry acts as the plugin's manifest and the skill folder's `SKILL.md` loads as the plugin's one skill.
- Executables: keep any in a `scripts/` folder, because Cowork, chat and organization sync refuse a plugin with a top-level `bin/` folder.

Then run `claude plugin validate .`, install the skill in Claude Code, and add the marketplace in Customize, then Plugins, to check claude.ai accepts every entry.

GitHub turns off scheduled workflows in a public repository after 60 days without activity. Merging a bump pull request counts as activity, and you can turn the workflow back on from the Actions tab.
