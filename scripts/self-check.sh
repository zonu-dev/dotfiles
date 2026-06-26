#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$repo_root"

bash -n scripts/*.sh

python3 - <<'PY'
import py_compile
from pathlib import Path

paths = [
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

if rg -n --hidden --glob '!**/.git/**' --glob '!scripts/self-check.sh' 'SOPS_AGE_KEY_FILE|/Users/s01080|dotfiles-private|Bitwarden|keys\.txt' .; then
  echo "public-private boundary check failed" >&2
  exit 1
fi

echo "self-check passed"
