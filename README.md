# marketplace-consulting

A private Claude Code plugin marketplace with the skills Jon uses for client work. Each skill is a separate plugin, so a client machine installs only the skills that client has approved.

## Setup

| Item | Value |
| --- | --- |
| Host | Private GitHub repository `jnpkr/marketplace-consulting` |
| Marketplace name | `consulting` |
| Local checkout | `~/Dev/personal/agents/marketplace-consulting` |
| Distributed through claude.ai organization sync | Yes, for at least one client |
| Claude Code version at build time | 2.1.287 |

### Organization sync rules

At least one client will sync this marketplace through claude.ai **Organization settings → Plugins & skills**, so the repository follows the [organization sync rules](https://claude.com/docs/plugins/org-sync):

- The repository stays private.
- Every plugin source is `github`, `url`, `git-subdir`, or a relative path that starts with `./`.
- No plugin has a top-level `bin/` directory. Executables go in `scripts/`.
- A private plugin source must have the same owner as this repository (`jnpkr`). Any other plugin source must be a public repository on github.com, gitlab.com or bitbucket.org. Organization sync fetches public sources without credentials.
- Organization sync reads the default branch (`main`). With automatic sync on, each push to `main` starts a sync.

## Skills

Each skill is a separate plugin with the same name, installed as `<skill>@consulting`. Every entry points to its upstream repository and is pinned to a reviewed commit. This repository copies no skill files.

| Skill | Type | Source | Upstream repo / path | Licence | Notes |
| --- | --- | --- | --- | --- | --- |
| `plain-writing` | upstream-bare-skill | `git-subdir` | [`docwriter-org/plain-writing-skill`](https://github.com/docwriter-org/plain-writing-skill) / `skills/plain-writing` | MIT (Shreya Shankar) | The upstream repo's `evals/` folder is not fetched |
| `writing-for-agents` | upstream-bare-skill | `git-subdir` | [`mattpocock/skills`](https://github.com/mattpocock/skills) / `skills/productivity/writing-for-agents` | MIT (Matt Pocock) | The repo root is the `mattpocock-skills` plugin with 27 skills. Pointing at the one skill folder installs only this skill |
| `dictation-fixes` | upstream-bare-skill | `github` | [`jnpkr/skill-dictation-fixes`](https://github.com/jnpkr/skill-dictation-fixes) | None | Jon's own skill, published as a public repo on 2026-10-22. Formerly `dictation-fix-prompt` in claude.ai |

Each skill folder has `SKILL.md` at its root and no `plugin.json`, so Claude Code loads it as a single-skill plugin and the marketplace entry acts as its manifest.

The MIT licences require the copyright notice to travel with copies. A `git-subdir` install fetches only the skill folder, not the upstream `LICENSE` file, so each entry records `license` and `author`.
