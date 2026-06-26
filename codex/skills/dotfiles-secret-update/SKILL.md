---
name: dotfiles-secret-update
description: Safely add, update, audit, encrypt, decrypt, and restore personal secrets managed by a private encrypted overlay with SOPS and age. Use when the user asks to add or update personal dotfiles secrets, re-encrypt current secret files, verify private secret sync, or restore private dotfiles without exposing secret values.
---

# Dotfiles Secret Update

Use this Codex wrapper for the tool-agnostic workflow in `../../../agent-workflows/secret-update.md`. Read that workflow before acting.

## Safety

- Never print secret values.
- Never commit decrypted files.
- Do not add company secrets to a personal private overlay.
- Do not record exact private store names, password-manager item names, or root-key paths in this public repo.

## Workflow

1. Obtain or confirm the private encrypted overlay path from the user or `DOTFILES_PRIVATE_REPO`.
2. Inspect state without printing values:
   ```bash
   python3 <repo>/scripts/agent/private_secret_inventory.py --private-repo "$DOTFILES_PRIVATE_REPO"
   ```
3. Classify the requested material as personal, company-owned, or unknown.
4. Update the live file or private overlay as approved by the user.
5. Re-encrypt in the private overlay and verify by hash/decrypt-to-`/dev/null` only.
6. Commit and push only after the user approves the exact scope.

## Resource

- `<repo>/scripts/agent/private_secret_inventory.py`: compare live files against encrypted overlay mappings by hash without printing secret contents.
