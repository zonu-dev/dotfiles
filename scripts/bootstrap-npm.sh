#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
global_packages_file="$repo_root/npm/global-packages.txt"

if [[ ! -f "$global_packages_file" ]]; then
  exit 0
fi

npm_cache="${NPM_CONFIG_CACHE:-${TMPDIR:-/tmp}/dotfiles-npm-cache}"
mkdir -p "$npm_cache"
export NPM_CONFIG_CACHE="$npm_cache"

if command -v mise >/dev/null 2>&1 && mise exec -- npm --version >/dev/null 2>&1; then
  npm_cmd=(mise exec -- npm)
elif command -v npm >/dev/null 2>&1; then
  npm_cmd=(npm)
else
  echo "npm is not installed; skipping npm global packages"
  exit 0
fi

while read -r package_name package_version _; do
  [[ -z "${package_name:-}" || "$package_name" == \#* ]] && continue

  installed_version="$("${npm_cmd[@]}" list -g --depth=0 --json 2>/dev/null \
    | python3 -c 'import json,sys; data=json.load(sys.stdin); name=sys.argv[1]; print(data.get("dependencies", {}).get(name, {}).get("version", ""))' "$package_name")"

  if [[ "$installed_version" == "$package_version" ]]; then
    echo "npm global already installed: $package_name@$package_version"
  else
    "${npm_cmd[@]}" install -g "$package_name@$package_version"
  fi
done < "$global_packages_file"
