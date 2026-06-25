# Secret Management

Do not commit raw secrets to this public repository.

## Recommended Model

Use three layers:

1. Public dotfiles repository
   - shell config
   - package/tool definitions
   - install scripts
   - no secret values

2. Private encrypted secret store
   - separate private repository such as `PRIVATE_OVERLAY_REPO`
   - SOPS-encrypted files only
   - safe to sync through GitHub because decrypted values are not committed

3. Root unlock secret
   - SOPS age private key
   - stored outside Git, preferably in password manager as a Secure Note
   - copied to a new Mac only during bootstrap

## Why Not Commit Private Files Directly?

Files such as these should not be copied into public dotfiles:

- `~/.ssh/*` private keys
- `~/.config/gh/hosts.yml`
- `~/.config/gcloud/*`
- `~/.gitconfig.local`
- `~/.config/zsh/local.zsh`
- `.env` files

Some of them contain tokens directly, and some encode personal/company-specific routing.

## SOPS + age Flow

On the primary machine:

```sh
mkdir -p ~/.config/sops/age
age-keygen -o PRIVATE_ROOT_KEY_PATH
age-keygen -y PRIVATE_ROOT_KEY_PATH
```

Use the public key from `age-keygen -y` in the private repo `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.ya?ml$
    age: age1...
```

Edit encrypted files:

```sh
sops secrets/personal.yaml
```

Decrypt during bootstrap:

```sh
sops --decrypt secrets/personal.yaml
```

## Sharing to a New Mac

The only thing that must be transferred out-of-band is the age private key:

```text
PRIVATE_ROOT_KEY_PATH
```

Recommended storage locations:

- password manager Secure Note
- 1Password or another password manager
- company-approved secret manager
- encrypted offline backup

After restoring the age key on the new Mac, encrypted files in the private repo can be decrypted.

## password manager Setup

Use password manager as the root recovery store, not as the Git-tracked file store.

Recommended item:

- Type: Secure Note
- Name: `PRIVATE_DOTFILES_ROOT_KEY_ITEM`
- Contents: the full contents of `PRIVATE_ROOT_KEY_PATH`
- Notes: include that it unlocks `PRIVATE_OVERLAY_REPO`

Do not store company secrets in the personal password manager item. Company secrets should stay in a company-approved account or vault.

The password manager CLI is installed for convenience, but entering the note through the desktop app is fine. The important part is that the age private key exists outside the Mac before relying on the encrypted private repo for recovery.

## SSH Keys

Prefer generating a new SSH key on each Mac and adding the public key to GitHub.

Avoid syncing SSH private keys unless there is a strong reason. If syncing is required, store them in the encrypted private secret store or a password manager, never in plain Git.

## GitHub and Cloud Auth

Prefer re-authentication over copying local token databases:

```sh
gh auth login
gcloud auth login
gcloud auth application-default login
```

Avoid syncing:

- `~/.config/gh/hosts.yml`
- `~/.config/gcloud/credentials.db`
- `~/.config/gcloud/access_tokens.db`
