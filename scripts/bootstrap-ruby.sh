#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ruby_version_file="$repo_root/rbenv/.rbenv/version"
global_gems_file="$repo_root/ruby/global-gems.txt"

if ! command -v rbenv >/dev/null 2>&1; then
  echo "rbenv is not installed; skipping Ruby bootstrap"
  exit 0
fi

if [[ ! -f "$ruby_version_file" ]]; then
  echo "Ruby version file not found: $ruby_version_file" >&2
  exit 1
fi

ruby_version="$(tr -d '[:space:]' < "$ruby_version_file")"

if [[ -z "$ruby_version" ]]; then
  echo "Ruby version file is empty: $ruby_version_file" >&2
  exit 1
fi

rbenv install -s "$ruby_version"

if [[ -f "$global_gems_file" ]]; then
  while read -r gem_name gem_version _; do
    [[ -z "${gem_name:-}" || "$gem_name" == \#* ]] && continue

    if RBENV_VERSION="$ruby_version" rbenv exec gem list "$gem_name" -i -v "$gem_version" >/dev/null 2>&1; then
      echo "gem already installed: $gem_name $gem_version"
    else
      RBENV_VERSION="$ruby_version" rbenv exec gem install "$gem_name" -v "$gem_version" --no-document
    fi
  done < "$global_gems_file"
fi

stale_shim="$HOME/.rbenv/shims/.rbenv-shim"
if [[ -f "$stale_shim" ]]; then
  echo "removing stale rbenv shim temp file: $stale_shim"
  rm -f "$stale_shim"
fi

rbenv rehash
