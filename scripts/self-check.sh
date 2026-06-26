#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$repo_root"

bash -n scripts/*.sh

if command -v zsh >/dev/null 2>&1; then
  zsh -n zsh/.zshenv zsh/.zprofile zsh/.zshrc
fi

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
HOME="$tmp_home" ./scripts/install.sh >/dev/null

python3 - <<'PY'
import py_compile
from pathlib import Path

paths = [
    Path("scripts/agent/collect_tool_diff.py"),
    Path("scripts/agent/private_secret_inventory.py"),
    Path("codex/skills/dotfiles-tool-sync/scripts/collect_tool_diff.py"),
    Path("codex/skills/dotfiles-secret-update/scripts/private_secret_inventory.py"),
]

for index, path in enumerate(paths):
    py_compile.compile(str(path), cfile=f"/tmp/dotfiles-self-check-{index}.pyc", doraise=True)
PY

if [[ -x "$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py" ]]; then
  python3 "$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py" codex/skills/dotfiles-tool-sync
  python3 "$HOME/.codex/skills/.system/skill-creator/scripts/quick_validate.py" codex/skills/dotfiles-secret-update
fi

git diff --check
if git rev-parse --verify HEAD^ >/dev/null 2>&1; then
  git diff --check HEAD^..HEAD
fi

if rg -n --hidden --glob '!**/.git/**' --glob '!scripts/self-check.sh' --glob '!**/*.enc' 'BEGIN (OPENSSH|RSA|DSA|EC|AGE) PRIVATE KEY|age-secret-key-1[0-9a-z]+|github_pat_[A-Za-z0-9_]+|gh[pousr]_[A-Za-z0-9_]{36,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]+|/Users/[A-Za-z0-9._-]+' .; then
  echo "public-private boundary check failed" >&2
  exit 1
fi

echo "self-check passed"
