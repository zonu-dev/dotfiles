#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apply=0

if [[ "${1:-}" == "--apply" ]]; then
  apply=1
fi

timestamp="$(date +%Y%m%d%H%M%S)"

run() {
  if (( apply )); then
    "$@"
  else
    printf '+'
    printf ' %q' "$@"
    printf '\n'
  fi
}

link_file() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'missing source: %s\n' "$source" >&2
    return 1
  fi

  run mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    run rm "$target"
  elif [[ -e "$target" ]]; then
    run mv "$target" "$target.bak.$timestamp"
  fi

  run ln -s "$source" "$target"
}

link_file "$repo_root/zsh/.zshenv" "$HOME/.zshenv"
link_file "$repo_root/zsh/.zprofile" "$HOME/.zprofile"
link_file "$repo_root/zsh/.zshrc" "$HOME/.zshrc"
link_file "$repo_root/mise/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
link_file "$repo_root/rbenv/.rbenv/version" "$HOME/.rbenv/version"
link_file "$repo_root/git/.gitconfig" "$HOME/.gitconfig"
link_file "$repo_root/git/.config/git/ignore" "$HOME/.config/git/ignore"
link_file "$repo_root/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_file "$repo_root/yazi/.config/yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"
link_file "$repo_root/zed/.config/zed/settings.json" "$HOME/.config/zed/settings.json"
link_file "$repo_root/gh-dash/.config/gh-dash/config.yml" "$HOME/.config/gh-dash/config.yml"
link_file "$repo_root/codex/skills/dotfiles-tool-sync" "$HOME/.codex/skills/dotfiles-tool-sync"
link_file "$repo_root/codex/skills/dotfiles-secret-update" "$HOME/.codex/skills/dotfiles-secret-update"
link_file "$repo_root/hammerspoon/.hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
link_file "$repo_root/ghostty/.config/ghostty/config" "$HOME/.config/ghostty/config"
link_file "$repo_root/cmux/.config/cmux/cmux.json" "$HOME/.config/cmux/cmux.json"
link_file "$repo_root/zsh-abbr/.config/zsh-abbr/user-abbreviations" "$HOME/.config/zsh-abbr/user-abbreviations"
link_file "$repo_root/claude/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$repo_root/claude/.claude/RTK.md" "$HOME/.claude/RTK.md"
link_file "$repo_root/claude/.claude/cmux.md" "$HOME/.claude/cmux.md"
link_file "$repo_root/claude/.claude/cmux-reference.md" "$HOME/.claude/cmux-reference.md"
link_file "$repo_root/claude/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
link_file "$repo_root/claude/.claude/settings.json" "$HOME/.claude/settings.json"
link_file "$repo_root/claude/.claude/hooks" "$HOME/.claude/hooks"
link_file "$repo_root/claude/.claude/skills/create-goal-prompt" "$HOME/.claude/skills/create-goal-prompt"
link_file "$repo_root/claude/.claude/skills/zoochi-icon" "$HOME/.claude/skills/zoochi-icon"
link_file "$repo_root/codex/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$repo_root/codex/.codex/RTK.md" "$HOME/.codex/RTK.md"

if (( apply )); then
  printf 'installed dotfiles from %s\n' "$repo_root"
else
  printf 'dry-run only. Re-run with --apply to create symlinks.\n'
fi
