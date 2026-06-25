# Fresh Mac Bootstrap

This is the expected order for recreating the development environment on a new Mac.

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

For the first clone, HTTPS is fine because the repository is public:

```sh
mkdir -p ~/src/gh-me/zonu-dev
git clone https://github.com/zonu-dev/dotfiles.git ~/src/gh-me/zonu-dev/dotfiles
cd ~/src/gh-me/zonu-dev/dotfiles
```

After SSH is configured, the remote can be changed to:

```sh
git remote set-url origin git@gh-me:zonu-dev/dotfiles.git
```

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

## 5. Restore private state

Create or restore the private files listed in `docs/private-files.md`, especially:

- `~/.gitconfig.local`
- `~/.gitconfig-gh-me`
- `~/.config/zsh/local.zsh`
- SOPS/age key material if encrypted private files are used

## 6. Authenticate services

At minimum:

```sh
gh auth login
gh auth setup-git
```

For Google Cloud, run the appropriate login commands for the project:

```sh
gcloud auth login
gcloud auth application-default login
```

## 7. Generate machine-specific SSH keys

Prefer one SSH key per machine instead of copying private keys between Macs.

```sh
ssh-keygen -t ed25519 -C "new-mac"
gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get ComputerName)"
```

If an existing SSH key must be reused, keep it in a password manager or encrypted private repo, not in this public repository.
