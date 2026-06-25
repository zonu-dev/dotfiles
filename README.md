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

Use a separate encrypted private store for secrets. See `docs/secrets.md`.
