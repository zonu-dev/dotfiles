# Tool Management

This repo tracks the global tools that should be reproducible on a personal Mac.

## Baselines

- `Brewfile`: Homebrew CLI tools, apps, fonts, and system packages.
- `mise/.config/mise/config.toml`: global version-managed runtimes. Keep project-specific tools in each project.
- `rbenv/.rbenv/version` and `ruby/global-gems.txt`: global Ruby and selected Ruby CLI gems.
- `npm/global-packages.txt`: npm global CLIs that are independent tools. Node-provided packages such as `npm` and `corepack` are inventory only.
- `pipx/global-packages.txt`: Python CLIs installed with pipx.

## Inventory Only

Some tools are intentionally not part of the baseline yet because their install source or ownership is still machine-specific:

- Google Cloud SDK under `~/google-cloud-sdk`
- Maestro under `~/.maestro`
- Bun under `~/.bun`
- Go managed by gvm under `~/.gvm`
- Android SDK and device tooling under `~/Library/Android`

Decide case by case before moving these into Homebrew, mise, or another reproducible source.

## Audit

Run the tool sync audit after changing global tools:

```sh
python3 codex/skills/dotfiles-tool-sync/scripts/collect_tool_diff.py
```

Do not add every local-only tool automatically. Add only tools that should be part of the fresh-Mac baseline.
