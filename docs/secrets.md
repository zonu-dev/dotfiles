# Secret Management

Do not commit raw secrets to this public repository. This document describes policy only; concrete private store names, password-manager item names, and local root-key paths belong outside this repo.

## Recommended Model

Use three layers:

1. Public dotfiles repository
   - shell config
   - package/tool definitions
   - install scripts
   - public agent workflows
   - no secret values or private recovery details

2. Private encrypted overlay
   - encrypted personal machine-specific files
   - explicit restore/encrypt scripts
   - access-controlled outside this public repo

3. Root unlock material
   - stored outside Git in a password manager or approved secret manager
   - restored only during bootstrap or disaster recovery

## What Must Stay Out

Do not copy these into public dotfiles:

- SSH private keys
- GitHub, cloud, package-registry, or browser token databases
- Git identity files with personal or company-specific routing
- local shell files containing tokens, emails, hostnames, or private paths
- `.env` files
- recovery codes
- root unlock keys for encrypted stores

Some files contain tokens directly, and others reveal useful targeting information even without token values.

## Public Documentation Boundary

It is fine for public docs to say:

- keep secrets out of this repo
- use a private encrypted overlay
- use SOPS/age or an approved password manager
- use company-approved storage for company secrets

Avoid writing:

- exact private repository names or URLs
- exact password-manager item names
- exact local root-key paths
- decrypted file contents or screenshots

## SOPS + age Pattern

SOPS with age is an acceptable implementation for a private encrypted overlay. Keep the specific recipient, key file path, and restore commands in the private overlay or password manager, not in this public repo.

General flow:

1. Generate or restore age key material outside Git.
2. Encrypt private files in the private overlay.
3. Commit only encrypted files and restore scripts to the private overlay.
4. On a new Mac, restore root unlock material from the password manager, then run the private overlay restore script.

## SSH Keys and Auth

Prefer generating new machine-specific SSH keys and re-authenticating services on each Mac.

Prefer re-authentication over copying local token databases:

```sh
gh auth login
gcloud auth login
gcloud auth application-default login
```

If an existing private key or token must be migrated, store it in an approved encrypted location and keep the public repo unaware of the exact item name or path.
