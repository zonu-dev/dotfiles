---
name: dotfiles-tool-sync
description: Compare local global developer tools with the `zonu-dev/dotfiles` repository and propose repository updates. Use when the user asks to synchronize, audit, add, remove, or review globally installed tools managed by Homebrew, mise, npm, pipx, gem, or related developer package managers against the dotfiles repo.
---

# Dotfiles Tool Sync

Use this skill to keep the current Mac's global tool state and `zonu-dev/dotfiles` reproducible configuration aligned.

## Defaults

- Public dotfiles repo: `/Users/s01080/src/gh-me/zonu-dev/dotfiles`
- Main tracked tool files:
  - `Brewfile`
  - `mise/.config/mise/config.toml`
- Treat the repo as the desired reproducible state.
- Treat local-only installed tools as candidates, not automatic additions.

## Workflow

1. Inspect the repo and local environment.
   ```bash
   python3 <skill>/scripts/collect_tool_diff.py
   ```
   Use `--dotfiles-repo <path>` if the repo is elsewhere.

2. Report findings before editing.
   Include:
   - Brewfile formulas/casks missing from Homebrew.
   - Top-level Homebrew formulas/casks installed locally but absent from `Brewfile`.
   - mise tools installed locally but absent from repo config.
   - repo-configured mise tools missing locally.
   - unmanaged global inventories from npm, pipx, and gem when available.

3. Ask the user which changes should be reflected in the repo before patching.
   Do not silently add every local tool; many are experiments or transitive helpers.

4. Apply approved repo changes.
   - Edit `Brewfile` for Homebrew tools.
   - Edit `mise/.config/mise/config.toml` for mise-managed runtimes.
   - Prefer existing repo style and ordering.
   - Do not add secrets, tokens, local machine paths, or company-private values.

5. Verify.
   ```bash
   git diff --check
   brew bundle check --file Brewfile --no-upgrade
   ```
   If `brew bundle check` fails because other existing tools are missing or outdated, explain that separately from the new change.

6. Commit and push only when the user asked for repository updates or approved the proposed changes.

## Guidance

- Prefer Homebrew for GUI apps and native CLI tools already tracked in `Brewfile`.
- Prefer mise for language runtimes and versioned toolchains that should be reproducible per machine.
- Record npm/pipx/gem globals only when there is a clear reason; many should move to project-level dependencies or mise installs instead.
- If a tool is installed by Homebrew only as a dependency, do not add it unless the user directly uses it.

## Resources

- `scripts/collect_tool_diff.py`: generate a Markdown report comparing local global tools with the dotfiles repo.
