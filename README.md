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
