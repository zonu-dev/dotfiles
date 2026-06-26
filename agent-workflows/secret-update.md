# Secret Update Workflow

Use this workflow to update personal secret-bearing dotfiles through a private encrypted overlay while keeping this public repo free of sensitive details.

## Goal

Safely add, update, verify, and commit encrypted personal secret material without exposing decrypted values in public files, terminal output, chat, or logs.

## Required Inputs

Before acting, obtain or confirm:

- the private encrypted overlay path, provided by the user or `DOTFILES_PRIVATE_REPO`
- whether the material is personal, company-owned, or unknown
- the live source file path, when updating from the current machine

Do not infer the private overlay location from public documentation. This public repo intentionally does not record exact private store names or recovery item names.

## Safety Rules

- Never print decrypted secret values.
- Never commit decrypted files.
- Never add company secrets to a personal private overlay.
- If classification is ambiguous, inspect only what is necessary and ask before storing anything.
- Do not sync SSH private keys, GitHub/cloud token databases, browser credential stores, or recovery codes unless the user explicitly approves that exact item.

## Workflow

1. Resolve the private overlay path.

   ```sh
   export DOTFILES_PRIVATE_REPO=/path/to/private-overlay
   ```

   Or pass `--private-repo /path/to/private-overlay` to scripts.

2. Inspect current encrypted overlay state without printing values.

   ```sh
   python3 codex/skills/dotfiles-secret-update/scripts/private_secret_inventory.py --private-repo "$DOTFILES_PRIVATE_REPO"
   ```

3. Classify the requested material.

   - Personal: may be managed in the private overlay.
   - Company-owned: keep in the approved company storage, not in the personal overlay.
   - Unknown: ask the user before proceeding.

4. Update the live file or prepare a private temporary decrypted file.

   - Prefer editing the live target file when it already exists.
   - If editing decrypted content from the overlay, use a private temporary file and remove it before finishing.
   - Do not paste secret values into the conversation.

5. If adding a new managed file, update the private overlay restore/encrypt scripts with explicit one-file mappings.

   - Add an encrypt mapping from live file to encrypted file.
   - Add a restore mapping from encrypted file to live file.
   - Avoid broad directory encryption unless the user asks for it.

6. Re-encrypt from the private overlay.

   ```sh
   cd "$DOTFILES_PRIVATE_REPO"
   ./scripts/encrypt-current.sh
   ```

7. Verify without revealing contents.

   ```sh
   python3 /path/to/public-dotfiles/codex/skills/dotfiles-secret-update/scripts/private_secret_inventory.py --private-repo "$DOTFILES_PRIVATE_REPO"
   git status --short
   git diff --stat
   ```

   For decryptability checks, redirect decrypted output to `/dev/null`.

8. Commit and push the private overlay only after the user approves the exact scope.

## Public Repo Updates

Update this public repo only for generic workflow improvements. Keep private overlay names, password-manager item names, and root-key locations out of public files.
