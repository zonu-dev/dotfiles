#!/bin/bash
# デフォルトのPreToolUseフック（常時稼働）
#
# AUTO_IMPLEMENT=1 時は ask 項目が deny に昇格される。
#
# deny（常時拒否）:
#   システム: sudo, su, chown, dd, diskutil, mount, lsblk
#   DB/ネットワーク: mongod, mysql, psql, nc, scp, ssh
#   GitHub: gh repo delete/archive/edit/sync, gh issue delete,
#           gh label delete/edit, gh release delete,
#           gh secret, gh workflow disable
#   機密ファイル: .env, *.pem, *.key, SSH鍵, Firebase等
#
# guard（通常: ask / AUTO_IMPLEMENT=1 時: deny）:
#   git reset --hard, git push --force, git rebase -i, git clean
#   gh api 書き込み, gh auth login/logout/refresh
#   gh issue/pr/label/release/run/workflow 書き込み系
#   curl/wget 書き込み, rm 再帰削除, chmod 危険パーミッション
#   gh repo fork

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

deny() {
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# AUTO_IMPLEMENT=1 時は guard=deny、通常時は guard=ask
if [[ -n "$AUTO_IMPLEMENT" ]]; then
  guard() { deny "$1"; }
else
  guard() {
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"$1\"}}"
    exit 0
  }
fi

# ============================================================
# Read/Write/Edit: 機密ファイル保護
# ============================================================
if [[ "$TOOL_NAME" == "Read" || "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  BASENAME=$(basename "$FILE_PATH")
  # .env
  if [[ "$BASENAME" == .env || "$BASENAME" == .env.* ]]; then
    deny "$TOOL_NAME on .env file is permanently blocked"
  fi
  # 秘密鍵・証明書
  if [[ "$BASENAME" =~ \.(pem|key|p12|pfx|cer|crt)$ ]]; then
    deny "$TOOL_NAME on certificate/key file is permanently blocked"
  fi
  # SSH鍵
  if [[ "$BASENAME" == "id_rsa" || "$BASENAME" == "id_ed25519" ]]; then
    deny "$TOOL_NAME on SSH key is permanently blocked"
  fi
  # Firebase / GCP認証
  if [[ "$FILE_PATH" == */Firebase/* || "$BASENAME" == "GoogleService-Info.plist" || "$BASENAME" == "google-services.json" ]]; then
    deny "$TOOL_NAME on Firebase/GCP credential is permanently blocked"
  fi
  # token / secret / private
  if [[ "$BASENAME" == "token" || "$BASENAME" == *secret* || "$BASENAME" == *private* || "$BASENAME" == *_key || "$BASENAME" == *_key.* || "$BASENAME" == *_token || "$BASENAME" == *_token.* || "$BASENAME" == *-key || "$BASENAME" == *-key.* || "$BASENAME" == *-token || "$BASENAME" == *-token.* || "$BASENAME" == .key || "$BASENAME" == .token || "$BASENAME" == .token.* || "$BASENAME" == .*key ]]; then
    deny "$TOOL_NAME on sensitive file is permanently blocked"
  fi
  # Write/Edit: 保護ディレクトリ
  if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
    # 高リスク Library サブディレクトリ: 常時拒否
    if [[ "$FILE_PATH" == */Library/Keychains/* || "$FILE_PATH" == */Library/Cookies/* || "$FILE_PATH" == */Library/Mail/* || "$FILE_PATH" == */Library/Accounts/* ]]; then
      deny "$TOOL_NAME on sensitive Library directory is permanently blocked"
    fi
    # Library 配下その他: 確認を求める（AUTO_IMPLEMENT 時は拒否）
    if [[ "$FILE_PATH" == */Library/* ]]; then
      guard "$TOOL_NAME on ~/Library/ path detected"
    fi
    # その他の保護ディレクトリ: 常時拒否
    if [[ "$FILE_PATH" == */ProjectSettings/* || "$FILE_PATH" == */UserSettings/* || "$FILE_PATH" == */certificates/* || "$FILE_PATH" == */keystore/* || "$FILE_PATH" == */secrets/* ]]; then
      deny "$TOOL_NAME on protected directory is permanently blocked"
    fi
  fi
  exit 0
fi

# Bash以外はスキップ
[[ "$TOOL_NAME" != "Bash" ]] && exit 0

CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# ============================================================
# deny（常時拒否）
# ============================================================

# --- 危険なシステムコマンド ---
if [[ "$CMD" =~ ^(sudo|su|chown|dd|diskutil|mount|lsblk)[[:space:]] || "$CMD" =~ ^(sudo|su|chown|dd|diskutil|mount|lsblk)$ ]]; then
  deny "${BASH_REMATCH[1]} is permanently blocked"
fi

# --- DB/ネットワーク ---
if [[ "$CMD" =~ ^(mongod|mysql|psql|nc|scp|ssh)[[:space:]] || "$CMD" =~ ^(mongod|mysql|psql|nc|scp|ssh)$ ]]; then
  deny "${BASH_REMATCH[1]} is permanently blocked"
fi

# --- 破壊的GitHub操作 ---
if [[ "$CMD" =~ ^gh[[:space:]]+issue[[:space:]]+delete ]]; then
  deny "gh issue delete is permanently blocked"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+label[[:space:]]+(delete|edit) ]]; then
  deny "gh label ${BASH_REMATCH[1]} is permanently blocked"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+release[[:space:]]+delete ]]; then
  deny "gh release delete is permanently blocked"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+repo[[:space:]]+(delete|archive|edit|sync) ]]; then
  deny "gh repo ${BASH_REMATCH[1]} is permanently blocked"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+secret ]]; then
  deny "gh secret is permanently blocked"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+workflow[[:space:]]+disable ]]; then
  deny "gh workflow disable is permanently blocked"
fi

# ============================================================
# guard（通常: ask / AUTO_IMPLEMENT: deny）
# ============================================================

# --- Git操作 ---
if [[ "$CMD" =~ ^git[[:space:]]+reset[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '--hard'; then
    guard "git reset --hard detected"
  fi
fi
if [[ "$CMD" =~ ^git[[:space:]]+push[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(--force-with-lease|--force|-f)(\s|$)'; then
    guard "git push --force detected"
  fi
fi
if [[ "$CMD" =~ ^git[[:space:]]+rebase[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(-i|--interactive)(\s|$)'; then
    guard "git rebase --interactive detected"
  fi
fi
if [[ "$CMD" =~ ^git[[:space:]]+clean ]]; then
  guard "git clean detected"
fi

# --- GitHub操作 ---
if [[ "$CMD" =~ ^gh[[:space:]]+api[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(-X[[:space:]]*|--method[=[:space:]]+)(POST|PUT|DELETE|PATCH)'; then
    guard "gh api write operation detected"
  fi
fi
if [[ "$CMD" =~ ^gh[[:space:]]+auth[[:space:]]+(login|logout|refresh) ]]; then
  guard "gh auth ${BASH_REMATCH[1]} detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(issue|pr)[[:space:]]+(close|comment|create|edit|reopen|merge|ready|review)[[:space:]] ]]; then
  guard "gh write operation: ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(label)[[:space:]]+(create)[[:space:]] ]]; then
  guard "gh label create detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(release)[[:space:]]+(create|edit|upload)[[:space:]] ]]; then
  guard "gh release write operation detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(repo)[[:space:]]+(fork)[[:space:]] ]]; then
  guard "gh repo fork detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(run)[[:space:]]+(cancel|rerun)[[:space:]] ]]; then
  guard "gh run operation detected"
fi
if [[ "$CMD" =~ ^gh[[:space:]]+(workflow)[[:space:]]+(run)[[:space:]] ]]; then
  guard "gh workflow run detected"
fi

# --- curl/wget ---
if [[ "$CMD" =~ ^curl[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(-X[[:space:]]*|--request[=[:space:]]+)(POST|PUT|DELETE|PATCH)'; then
    guard "curl write operation detected"
  fi
  if echo "$CMD" | grep -qE -- '(\s|^)(-d|--data|--data-raw|--data-binary|--data-urlencode|-F|--form)(\s|=)'; then
    guard "curl with data/form upload detected"
  fi
fi
if [[ "$CMD" =~ ^wget[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '--post-data|--post-file|--method'; then
    guard "wget write operation detected"
  fi
fi

# --- rm/chmod ---
if [[ "$CMD" =~ ^rm[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(\s|^)-[a-zA-Z]*[rR][a-zA-Z]*(\s|$)'; then
    guard "rm recursive deletion detected"
  fi
fi
if [[ "$CMD" =~ ^chmod[[:space:]] ]]; then
  if echo "$CMD" | grep -qE -- '(777|[ugo]*\+s)'; then
    guard "chmod dangerous permission detected"
  fi
fi
