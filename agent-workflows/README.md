# Agent Workflows

These workflows are tool-agnostic instructions for maintaining this dotfiles setup. They are intended for Codex, Claude Code, Cursor, or any other coding agent that can read repository files and run local scripts.

The workflow markdown files are the source of truth. Tool-specific integrations, such as Codex skills, should be thin wrappers around these files.

## Workflows

- `tool-sync.md`: compare global tools installed on the Mac with reproducible repo config and propose updates.
- `secret-update.md`: update a private encrypted overlay without leaking secret values into public files or chat.

## Public Repo Boundary

This directory may describe secret-handling policy, but must not name exact private repositories, password-manager item names, or local root-key paths. Put concrete recovery details in the private overlay or password manager.
