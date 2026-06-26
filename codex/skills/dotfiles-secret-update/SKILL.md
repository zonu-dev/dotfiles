---
name: dotfiles-secret-update
description: Safely add, update, audit, encrypt, decrypt, and restore personal secrets managed by the private `PRIVATE_OVERLAY_REPO` repository with SOPS and age. Use when the user asks to add or update personal dotfiles secrets, re-encrypt current secret files, verify private secret sync, or restore private dotfiles without exposing secret values.
---

# Dotfiles Secret Update

Use this skill to update personal secret-bearing dotfiles without leaking values into chat, logs, public repos, or shell output.

## Defaults

- Private repo: `/Users/s01080/src/gh-me/PRIVATE_OVERLAY_REPO`
- Age key: `PRIVATE_ROOT_KEY_PATH`
- Public companion repo: `/Users/s01080/src/gh-me/zonu-dev/dotfiles`
- Root unlock key backup: password manager Secure Note `PRIVATE_DOTFILES_ROOT_KEY_ITEM`

## Safety Rules

- Never print secret values.
- Never add company secrets to the personal `PRIVATE_OVERLAY_REPO` repo.
- Apply any user-provided personal/company classification markers from the current task or private local classification notes.
- If classification markers are unavailable, inspect context without printing values and ask before storing ambiguous material.
- Do not commit decrypted files.
- Do not copy `~/.ssh` private keys, GitHub/GCP token databases, or browser credential stores into the repo unless the user gives a specific exception.

## Workflow

1. Confirm classification and target.
   - Personal secret: may be managed here.
   - Company secret: leave out of this repo and suggest company-approved storage.
   - Unknown: inspect metadata/content carefully without printing sensitive values; ask when ambiguous.
   - For `~/Documents/DeveloperSecrets`, read `CLASSIFICATION.md` if present before moving or encrypting anything.

2. Inspect current managed secret state.
   ```bash
   python3 <skill>/scripts/private_secret_inventory.py
   ```

3. Add or update the live file.
   - Prefer editing the live target such as `~/.config/zsh/local.zsh` or `~/.gitconfig.local`.
   - If only an encrypted file exists, decrypt to a private temp file, edit it, then re-encrypt. Remove the temp file before finishing.

4. If adding a new managed file, update both scripts in `private-overlay`:
   - `scripts/encrypt-current.sh`: add one `encrypt_file "$HOME/..." "secrets/home/...enc"` line.
   - `scripts/restore.sh`: add the matching `restore_file "secrets/home/...enc" "$HOME/..."` line.
   Keep mappings explicit; do not add broad directory encryption unless the user asks.

5. Re-encrypt.
   ```bash
   cd /Users/s01080/src/gh-me/PRIVATE_OVERLAY_REPO
   ./scripts/encrypt-current.sh
   ```

6. Verify without revealing contents.
   ```bash
   python3 <skill>/scripts/private_secret_inventory.py
   git status --short
   git diff --stat
   ```
   Use `sops --decrypt ... >/dev/null` for decryptability checks. Do not show decrypted output.

7. Commit and push only after the user asked for it or approved the exact scope.

## Restore Workflow

1. Confirm the age key exists at `PRIVATE_ROOT_KEY_PATH`.
2. Run:
   ```bash
   cd /Users/s01080/src/gh-me/PRIVATE_OVERLAY_REPO
   ./scripts/restore.sh
   ```
3. Verify restored files exist and have restrictive permissions.

## Resources

- `scripts/private_secret_inventory.py`: list managed mappings and compare live files against encrypted repo files by hash without printing secret contents.
