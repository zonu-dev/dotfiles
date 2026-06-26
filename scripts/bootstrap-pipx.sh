#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
global_packages_file="$repo_root/pipx/global-packages.txt"

if [[ ! -f "$global_packages_file" ]]; then
  exit 0
fi

if ! command -v pipx >/dev/null 2>&1; then
  echo "pipx is not installed; skipping pipx packages"
  exit 0
fi

while read -r package_name package_version _; do
  [[ -z "${package_name:-}" || "$package_name" == \#* ]] && continue

  pipx_json="$(pipx list --json)"
  installed_version="$(python3 -c 'import json,sys; data=json.load(sys.stdin); name=sys.argv[1]; meta=data.get("venvs", {}).get(name, {}).get("metadata", {}).get("main_package", {}); print(meta.get("package_version", ""))' "$package_name" <<< "$pipx_json")"

  if [[ "$installed_version" == "$package_version" ]]; then
    echo "pipx package already installed: $package_name==$package_version"
  elif [[ -n "$installed_version" ]]; then
    pipx install --force "$package_name==$package_version"
  else
    pipx install "$package_name==$package_version"
  fi
done < "$global_packages_file"
