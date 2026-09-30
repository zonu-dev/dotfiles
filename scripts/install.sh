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

copy_file() {
  # アプリ側が書き戻すファイルは symlink せず、無いときだけコピーする
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    printf 'missing source: %s\n' "$source" >&2
    return 1
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -f "$target" ]] && ! cmp -s "$source" "$target"; then
      printf 'keep existing (differs from repo): %s\n' "$target"
    else
      printf 'keep existing: %s\n' "$target"
    fi
    return 0
  fi

  run mkdir -p "$(dirname "$target")"
  run cp "$source" "$target"
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
link_file "$repo_root/zsh-abbr/.config/zsh-abbr/user-abbreviations" "$HOME/.config/zsh-abbr/user-abbreviations"
link_file "$repo_root/claude/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$repo_root/claude/.claude/RTK.md" "$HOME/.claude/RTK.md"
link_file "$repo_root/claude/.claude/cmux.md" "$HOME/.claude/cmux.md"
link_file "$repo_root/claude/.claude/cmux-reference.md" "$HOME/.claude/cmux-reference.md"
link_file "$repo_root/claude/.claude/statusline.py" "$HOME/.claude/statusline.py"
copy_file "$repo_root/claude/.claude/settings.json" "$HOME/.claude/settings.json"
# 旧版 install.sh は ~/.claude/hooks をディレクトリ symlink にしていた。残っていると
# ファイル単位 link がリポ内へ迷い込むので先に外す。
if [[ -L "$HOME/.claude/hooks" ]]; then
  printf 'warning: %s is a symlink (legacy layout). Removing it before linking hook files.\n' "$HOME/.claude/hooks" >&2
  run rm "$HOME/.claude/hooks"
fi
link_file "$repo_root/claude/.claude/hooks/auto-implement-guard.sh" "$HOME/.claude/hooks/auto-implement-guard.sh"
link_file "$repo_root/claude/.claude/hooks/default-guard.sh" "$HOME/.claude/hooks/default-guard.sh"
link_file "$repo_root/claude/.claude/hooks/rtk-rewrite.sh" "$HOME/.claude/hooks/rtk-rewrite.sh"
link_file "$repo_root/claude/.claude/hooks/term-bg-permission.sh" "$HOME/.claude/hooks/term-bg-permission.sh"
link_file "$repo_root/claude/.claude/hooks/term-bg-running.sh" "$HOME/.claude/hooks/term-bg-running.sh"
link_file "$repo_root/claude/.claude/hooks/term-bg-stop.sh" "$HOME/.claude/hooks/term-bg-stop.sh"
link_file "$repo_root/claude/.claude/skills/create-goal-prompt" "$HOME/.claude/skills/create-goal-prompt"
link_file "$repo_root/claude/.claude/skills/zoochi-icon" "$HOME/.claude/skills/zoochi-icon"
link_file "$repo_root/codex/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$repo_root/codex/.codex/RTK.md" "$HOME/.codex/RTK.md"
link_file "$repo_root/local-bin/bin/gh" "$HOME/.local/bin/gh"
link_file "$repo_root/local-bin/bin/term-bg" "$HOME/.local/bin/term-bg"
link_file "$repo_root/deadbranch/.deadbranch/config.toml" "$HOME/.deadbranch/config.toml"
copy_file "$repo_root/xcode/Library/Developer/Xcode/UserData/KeyBindings/Default.idekeybindings" "$HOME/Library/Developer/Xcode/UserData/KeyBindings/Default.idekeybindings"
link_file "$repo_root/codex/skills/create-goal-prompt" "$HOME/.codex/skills/create-goal-prompt"
link_file "$repo_root/codex/skills/github-pr-review" "$HOME/.codex/skills/github-pr-review"
link_file "$repo_root/codex/skills/godot-mobile" "$HOME/.codex/skills/godot-mobile"
link_file "$repo_root/codex/skills/hatch-pet" "$HOME/.codex/skills/hatch-pet"
link_file "$repo_root/codex/skills/opensrc" "$HOME/.codex/skills/opensrc"
link_file "$repo_root/codex/skills/session-harness-auditor" "$HOME/.codex/skills/session-harness-auditor"
link_file "$repo_root/codex/skills/slack-mrkdwn" "$HOME/.codex/skills/slack-mrkdwn"
link_file "$repo_root/codex/skills/zoochi-icon" "$HOME/.codex/skills/zoochi-icon"
link_file "$repo_root/claude/.claude/skills/settings-sync" "$HOME/.claude/skills/settings-sync"

if (( apply )); then
  printf 'installed dotfiles from %s\n' "$repo_root"
else
  printf 'dry-run only. Re-run with --apply to create symlinks.\n'
fi
