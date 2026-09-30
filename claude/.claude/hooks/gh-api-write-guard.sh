#!/bin/bash
# 危険なフラグを含むコマンドを検出し、確認を要求するPreToolUseフック
#
# 対象:
#   gh api  - 書き込み系 (-X POST/PUT/DELETE/PATCH, --method)
#   git reset - --hard
#   git push  - --force / -f
#   git rebase - -i (interactive)
#   curl    - 書き込み系 (-X POST/PUT/DELETE/PATCH, -d, --data, -F, --form)
#   rm      - 再帰削除 (-r, -rf, -fr, -R)
#   chmod   - 危険なパーミッション (777, +s, u+s, g+s)
#   gh issue/pr/label/release/run/workflow - 書き込み系サブコマンド
#   gh repo fork

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

ask() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# gh api: 書き込み系フラグ
if [[ "$CMD" =~ ^gh[[:space:]]+api[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(-X[[:space:]]*|--method[=[:space:]]+)(POST|PUT|DELETE|PATCH)'; then
    ask "gh api write operation detected"
  fi
fi

# git reset --hard
if [[ "$CMD" =~ ^git[[:space:]]+reset[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '--hard'; then
    ask "git reset --hard detected"
  fi
fi

# git push --force / -f
if [[ "$CMD" =~ ^git[[:space:]]+push[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(--force-with-lease|--force|-f)(\s|$)'; then
    ask "git push --force detected"
  fi
fi

# git rebase -i (interactive)
if [[ "$CMD" =~ ^git[[:space:]]+rebase[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(-i|--interactive)(\s|$)'; then
    ask "git rebase --interactive detected"
  fi
fi

# curl: 書き込み系フラグ
if [[ "$CMD" =~ ^curl[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(-X[[:space:]]*|--request[=[:space:]]+)(POST|PUT|DELETE|PATCH)'; then
    ask "curl write operation detected"
  fi
  if echo "$CMD" | grep -qE -- '(\s|^)(-d|--data|--data-raw|--data-binary|--data-urlencode|-F|--form)(\s|=)'; then
    ask "curl with data/form upload detected"
  fi
fi

# rm: 再帰削除
if [[ "$CMD" =~ ^rm[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(\s|^)-[a-zA-Z]*[rR][a-zA-Z]*(\s|$)'; then
    ask "rm recursive deletion detected"
  fi
fi

# chmod: 危険なパーミッション
if [[ "$CMD" =~ ^chmod[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(777|[ugo]*\+s)'; then
    ask "chmod dangerous permission detected"
  fi
fi

# gh: GitHub書き込み系サブコマンド
if [[ "$CMD" =~ ^gh[[:space:]]+(issue|pr)[[:space:]]+(close|comment|create|edit|reopen|merge|ready|review)[[:space:]] ]]; then
  ask "gh write operation: ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(label)[[:space:]]+(create)[[:space:]] ]]; then
  ask "gh label create detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(release)[[:space:]]+(create|edit|upload)[[:space:]] ]]; then
  ask "gh release write operation detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(repo)[[:space:]]+(fork)[[:space:]] ]]; then
  ask "gh repo fork detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(run)[[:space:]]+(cancel|rerun)[[:space:]] ]]; then
  ask "gh run operation detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(workflow)[[:space:]]+(run)[[:space:]] ]]; then
  ask "gh workflow run detected"
fi
