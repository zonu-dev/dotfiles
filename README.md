# dotfiles

Personal macOS development environment configuration.

## Scope

Publicly tracked:

- zsh bootstrap files
- mise global tool versions
- rbenv global Ruby version and selected global Ruby CLI gems
- selected npm and pipx global CLI packages
- Git defaults without identity
- global Git ignore
- tmux, yazi, Zed, gh-dash settings
- personal Codex skills that contain no secrets
- Hammerspoon, Ghostty, zsh-abbr settings
- Claude Code user config (CLAUDE.md, settings.json, hooks, skills, statusline) with machine paths replaced by `$HOME`
- Codex AGENTS.md and a curated `codex/config.reference.toml` (not symlinked)
- personal Codex skills (github-pr-review, slack-mrkdwn, opensrc, godot-mobile, hatch-pet, session-harness-auditor, create-goal-prompt, zoochi-icon)
- Claude Code skills (create-goal-prompt, settings-sync, zoochi-icon via symlink to the Codex copy)
- `~/.local/bin` wrappers (`gh` via direnv, `term-bg`), deadbranch config, Xcode key bindings
- `scripts/macos-defaults.sh` for Dock / Finder / screenshot defaults

Not tracked:

- credentials, tokens, SSH keys, SOPS age keys
- Git identity files
- work-specific URL rewrites
- Google Cloud local state

See `docs/private-files.md` for the private overlay policy.

## Install

For a fresh Mac, follow `docs/bootstrap-macos.md`.

Run a dry-run first:

```sh
./scripts/install.sh
```

Apply symlinks:

```sh
./scripts/install.sh --apply
```

Existing files are moved to `*.bak.<timestamp>` before symlinks are created.

## Secrets

Use a separate encrypted private overlay for secrets. See `docs/secrets.md`. Tool-agnostic maintenance workflows live in `agent-workflows/`.

## Tool Management

Global tool baselines and audit policy are documented in `docs/tool-management.md`.

Run the local validation suite before committing changes:

```sh
./scripts/self-check.sh
```

## Manual steps not covered by Brewfile

- `gh extension install dlvhdr/gh-dash`
- `deadbranch` (v0.4.0) is a manually installed binary in `~/.local/bin`; it is not in Homebrew
- Go is managed by gvm (`~/.gvm`), not Homebrew; `.zshrc` sources it only when present
- run `./scripts/macos-defaults.sh` once on a new Mac
- Ghostty: remove `~/Library/Application Support/com.mitchellh.ghostty/config` if it exists; that file overrides the XDG config linked by install.sh
- `~/.claude/settings.json` and Xcode key bindings are copied once (not symlinked) because the apps write them back; re-copy into the repo when you change them
- `~/.config/zsh-abbr/user-abbreviations` and `~/.codex/AGENTS.md` are symlinked and get written back by `abbr add` / codegraph; commit those changes deliberately
- `zonu-plugins` marketplace in `claude/.claude/settings.json` uses the `gh-me` SSH alias; enable it after `~/.ssh/config` is restored
