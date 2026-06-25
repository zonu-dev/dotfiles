# dotfiles

Personal macOS development environment configuration.

## Scope

Publicly tracked:

- zsh bootstrap files
- mise global tool versions
- Git defaults without identity
- global Git ignore
- tmux, yazi, Zed, gh-dash settings

Not tracked:

- credentials, tokens, SSH keys, SOPS age keys
- Git identity files
- work-specific URL rewrites
- Google Cloud local state

See `docs/private-files.md` for the private overlay policy.

## Install

Run a dry-run first:

```sh
./scripts/install.sh
```

Apply symlinks:

```sh
./scripts/install.sh --apply
```

Existing files are moved to `*.bak.<timestamp>` before symlinks are created.
