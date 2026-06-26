---
name: dotfiles-tool-sync
description: Compare local global developer tools with the public dotfiles repository and propose repository updates. Use when the user asks to synchronize, audit, add, remove, or review globally installed tools managed by Homebrew, mise, npm, pipx, gem, or related developer package managers against the dotfiles repo.
---

# Dotfiles Tool Sync

Use this Codex wrapper for the tool-agnostic workflow in `../../../agent-workflows/tool-sync.md`. Read that workflow before acting.

## Workflow

1. Run the audit script:
   ```bash
   python3 <repo>/scripts/agent/collect_tool_diff.py
   ```
2. Summarize drift between local global tools and repo config.
3. Ask the user which local-only tools should be reflected in the repo.
4. Patch only approved files.
5. Validate with `git diff --check` and, when useful, `brew bundle check --file Brewfile --no-upgrade`.
6. Commit and push only after the user approves repo updates.

## Resource

- `<repo>/scripts/agent/collect_tool_diff.py`: read-only Markdown report for Homebrew, mise, npm, pipx, and gem global state.
