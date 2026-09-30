#!/usr/bin/env bash
# macOS の個人設定（defaults）。新端末で一度実行する。
set -euo pipefail

# Dock: 自動的に隠す、アイコンサイズ 42
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -int 42

# Finder: すべての拡張子を表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# スクリーンショットの保存先
mkdir -p "$HOME/Artifacts/captures/manual"
defaults write com.apple.screencapture location -string "$HOME/Artifacts/captures/manual"

killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
echo "macOS defaults applied"
