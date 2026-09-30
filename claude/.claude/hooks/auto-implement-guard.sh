#!/bin/bash
# auto-implement用の追加PreToolUseフック
# AUTO_IMPLEMENT=1 環境変数が設定されている場合のみ動作
#
# Bash/Read/Write/Edit の制御は default-guard.sh が担当。
# このファイルは default-guard.sh がカバーしないツールのみ処理する。

# AUTO_IMPLEMENT未設定時は何もしない
[[ -z "$AUTO_IMPLEMENT" ]] && exit 0

TOOL_NAME=$(cat | jq -r '.tool_name // empty')

# AskUserQuestion: 完全自動のため拒否
if [[ "$TOOL_NAME" == "AskUserQuestion" ]]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"AskUserQuestion denied in auto-implement mode\"}}"
  exit 0
fi
