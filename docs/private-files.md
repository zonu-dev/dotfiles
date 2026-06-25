# Private Files

These files are intentionally not tracked in the public dotfiles repository.

- `~/.config/zsh/local.zsh`: local shell helpers, Git identities, SSH key helpers.
- `~/.gitconfig.local`: default Git user name/email and machine-specific Git settings.
- `~/.gitconfig-gh-me`: personal GitHub identity for `~/src/gh-me`.
- `~/.ssh/`: SSH private keys and config.
- `~/.config/gh/hosts.yml`: GitHub auth token state.
- `~/.config/gcloud/`: Google Cloud credentials and local config.
- `PRIVATE_ROOT_KEY_PATH`: SOPS age private key.
- `~/.bash_profile`: old shell profile containing deprecated paths and local secrets; do not publish as-is.

The public files should only define reusable defaults and optional hooks that source these local files when they exist.
