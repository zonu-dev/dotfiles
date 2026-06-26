#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! xcode-select -p >/dev/null 2>&1; then
  cat <<'MSG'
Xcode Command Line Tools are not installed.
Run this first, finish the installer, then rerun bootstrap:

  xcode-select --install
MSG
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  cat <<'MSG'
Homebrew is not installed.
Install Homebrew from https://brew.sh/, then rerun bootstrap.
MSG
  exit 1
fi

brew bundle --file "$repo_root/Brewfile"
"$repo_root/scripts/install.sh" --apply
"$repo_root/scripts/bootstrap-ruby.sh"

if command -v mise >/dev/null 2>&1; then
  mise install
fi

cat <<'MSG'
Bootstrap complete.

Next steps:
  1. Restart the shell or run: exec zsh -l
  2. Restore private files described in docs/private-files.md
  3. Authenticate tools such as gh, gcloud, and any password manager you use
MSG
