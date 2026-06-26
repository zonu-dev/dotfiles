# AGENTS.md

This is a public dotfiles repository. Keep it reproducible, machine-portable, and free of secrets.

## Security Rules

- Do not commit credentials, tokens, private keys, auth databases, recovery codes, or decrypted secret material.
- Do not document exact private store names, password-manager item names, root-key names, or machine-specific recovery paths in this public repo.
- Use generic terms such as private encrypted overlay, password manager, or approved company secret store in public files.
- Keep company secrets out of any personal repository. If classification is unclear, stop and ask.
- Prefer re-authentication for GitHub, cloud CLIs, browsers, and package registries instead of syncing token databases.

## Repository Roles

- Public repo: non-secret shell config, package/tool definitions, install scripts, editor defaults, and public agent workflows.
- Private overlay: encrypted personal machine-specific files and restore scripts. Exact location and recovery details belong outside this repo.
- Password manager: root unlock material and recovery notes that must not be committed.

## Agent Workflows

Use `agent-workflows/` as the tool-agnostic source of truth:

- `agent-workflows/tool-sync.md` for global tool drift audits and repo updates.
- `agent-workflows/secret-update.md` for personal secret overlay updates without exposing values.

Codex-specific wrappers live under `codex/skills/` and should stay thin. Other tools can read the workflow markdown directly and run the same scripts.

## Change Rules

- For Homebrew changes, update `Brewfile`.
- For mise-managed runtimes, update `mise/.config/mise/config.toml`.
- For shell/Git/editor defaults, preserve existing style and avoid machine-only paths.
- For secret-bearing changes, update only the private encrypted overlay after user confirmation. Do not add private values here.
- Keep commits scoped. Do not mix cleanup, tool sync, and secret workflow changes unless the user asked for it.

## Validation

Before finishing relevant changes, run what applies:

```sh
./scripts/self-check.sh
```

For narrow changes where the full self-check is not appropriate, run the relevant subset. When Codex skills change:

```sh
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py codex/skills/dotfiles-tool-sync
python3 ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py codex/skills/dotfiles-secret-update
```

For tool sync checks:

```sh
python3 scripts/agent/collect_tool_diff.py
```

For private overlay checks, only run the inventory script after the user provides or confirms the private overlay path. Never print decrypted contents.
