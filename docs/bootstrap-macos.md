# Fresh Mac Bootstrap

This is the expected public bootstrap order for recreating the non-secret parts of the development environment on a new Mac. Private overlay recovery details intentionally live outside this public repo.

## 1. Install Apple Command Line Tools

```sh
xcode-select --install
```

Finish the installer before continuing.

## 2. Install Homebrew

Install Homebrew from https://brew.sh/.

After installation, make sure `brew` works:

```sh
brew --version
```

## 3. Clone dotfiles

For the first clone, HTTPS is fine because this repository is public:

```sh
mkdir -p ~/src/gh-me/zonu-dev
git clone https://github.com/zonu-dev/dotfiles.git ~/src/gh-me/zonu-dev/dotfiles
cd ~/src/gh-me/zonu-dev/dotfiles
```

After SSH is configured, the remote can be changed to the preferred SSH remote for this public repo.

## 4. Run bootstrap

Dry-run symlink changes if desired:

```sh
./scripts/install.sh
```

Install Homebrew packages, apply dotfile symlinks, and install mise tools:

```sh
./scripts/bootstrap-macos.sh
```

Then restart the shell:

```sh
exec zsh -l
```

## 5. Authenticate GitHub

Authenticate GitHub before cloning any private overlay. HTTPS or `gh repo clone` is the least fragile first-clone path on a fresh Mac because SSH keys may not exist yet.

```sh
gh auth login
gh auth setup-git
```

Generate and register an SSH key before private SSH clones only if you want SSH to be the first clone method.

## 6. Restore Private Overlay

Restore private state from your password manager and private encrypted overlay. Exact repository names, item names, and root-key paths are intentionally not documented here.

Expected high-level order:

1. Install and log in to the password manager.
2. Restore root unlock material for the encrypted overlay.
3. Authenticate GitHub if it was not done in the previous step.
4. Clone or otherwise access the private encrypted overlay.
5. Run that overlay's restore script.
6. Confirm restored files have restrictive permissions.

See `docs/private-files.md` for examples of private file categories, not concrete recovery locations.

## 7. Authenticate Additional Services

At minimum, confirm GitHub auth is still healthy:

```sh
gh auth status
```

For Google Cloud, run the appropriate login commands for the project:

```sh
gcloud auth login
gcloud auth application-default login
```

## 8. Generate Machine-Specific SSH Keys

Prefer one SSH key per machine instead of copying private keys between Macs.

```sh
ssh-keygen -t ed25519 -C "new-mac"
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get ComputerName)"
```

After SSH is configured, private and public remotes can be changed to the preferred SSH remote.

If an existing SSH key must be reused, keep it in a password manager or encrypted private overlay, not in this public repository.

## 9. Public History Metadata

Treat any private recovery names or paths that ever appeared in this public repository's history as public metadata. Prefer renaming external password-manager items or recovery labels if the names should not remain recognizable.

Do not rewrite public Git history unless an actual secret value, private key, or token was committed. History rewrites require coordinated force-pushes and fresh clones.
