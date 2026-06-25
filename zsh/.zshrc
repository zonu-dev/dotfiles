# === 基本設定 ===
typeset -U path

function _clean_stale_path_entries() {
  local entry
  for entry in \
    "$HOME/Library/Application" \
    "Support/JetBrains/Toolbox/scripts" \
    "$HOME/.rbenv/bin" \
    "$HOME/.nodebrew/current/bin" \
    "/opt/homebrew/opt/node@20/bin" \
    "/Library/Frameworks/Python.framework/Versions/3.10/bin" \
    "/Applications/Unity/Hub/Editor/2022.2.20f1/PlaybackEngines/AndroidPlayer/OpenJDK/bin" \
    "$HOME/Library/Android/sdk/ndk-bundle" \
    "$HOME/Documents/Shell/cmd" \
    "$HOME/Documents/octov2-cli_v0.15.3"
  do
    path=("${(@)path:#$entry}")
  done
}

function _reset_stale_mise_path_state() {
  case "${__MISE_ORIG_PATH:-}" in
    *"$HOME/Library/Application:Support/JetBrains/Toolbox/scripts"*|*"$HOME/.rbenv/bin"*|*"$HOME/.nodebrew/current/bin"*|*"/opt/homebrew/opt/node@20/bin"*|*"/Library/Frameworks/Python.framework/Versions/3.10/bin"*|*"/Applications/Unity/Hub/Editor/2022.2.20f1/PlaybackEngines/AndroidPlayer/OpenJDK/bin"*|*"$HOME/Library/Android/sdk/ndk-bundle"*|*"$HOME/Documents/Shell/cmd"*|*"$HOME/Documents/octov2-cli_v0.15.3"*)
      unset __MISE_ORIG_PATH __MISE_DIFF __MISE_SESSION
      ;;
  esac
}

_clean_stale_path_entries
_reset_stale_mise_path_state

if [ -z "$INTELLIJ_ENVIRONMENT_READER" ]; then
  export ZSH_TMUX_AUTOSTART=true
fi

# === ツール初期化 ===
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# gvm
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
_clean_stale_path_entries

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# zsh-abbr
if command -v brew >/dev/null 2>&1 && [ -f "$(brew --prefix)/share/zsh-abbr/zsh-abbr.zsh" ]; then
  source "$(brew --prefix)/share/zsh-abbr/zsh-abbr.zsh"
fi

# fzf
if [[ -t 0 && -t 1 ]]; then
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
elif [[ -d /opt/homebrew/opt/fzf/bin ]]; then
  path+=("/opt/homebrew/opt/fzf/bin")
fi

# direnv
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# mise
_reset_stale_mise_path_state
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi
_clean_stale_path_entries

# jenv
if command -v jenv >/dev/null 2>&1; then
  eval "$(jenv init -)"
fi
_clean_stale_path_entries

# bun completions
[ -s "/Users/s01080/.bun/_bun" ] && source "/Users/s01080/.bun/_bun"

# === キーバインド (fzf連携) ===
if [[ -t 0 && -t 1 ]]; then
  # cdr: 過去のディレクトリ移動履歴から選択。Ctrl+Gにバインド。
  if [[ -n $(echo ${^fpath}/chpwd_recent_dirs(N)) && -n $(echo ${^fpath}/cdr(N)) ]]; then
      autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
      add-zsh-hook chpwd chpwd_recent_dirs
      zstyle ':completion:*' recent-dirs-insert both
      zstyle ':chpwd:*' recent-dirs-default true
      zstyle ':chpwd:*' recent-dirs-max 1000
      zstyle ':chpwd:*' recent-dirs-file "$HOME/.cache/chpwd-recent-dirs"
  fi

  function fzf-cdr () {
    local selected_dir="$(cdr -l | sed 's/^[0-9]\+ \+//' | fzf --prompt="cdr > " --query "$LBUFFER")"
    if [ -n "$selected_dir" ]; then
      BUFFER="cd $(echo $selected_dir | awk '{print $2}')"
      CURSOR=$#BUFFER
      zle reset-prompt
    fi
  }
  zle -N fzf-cdr
  bindkey '^G' fzf-cdr

  # ghq: 管理下のリポジトリを一覧表示して選択。Ctrl+]にバインド。
  function fzf-ghq () {
    local selected_dir=$(ghq list -p | fzf --prompt="repositories > " --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
      BUFFER="cd ${selected_dir}"
      zle accept-line
    fi
    zle clear-screen
  }
  zle -N fzf-ghq
  bindkey '^]' fzf-ghq
  fi

# === カスタム関数 ===
function ghq() {
  if [[ "$1" == "rm" ]]; then
    local -a args
    args=("${@:2}")

    local i
    for i in {1..${#args}}; do
      case "${args[$i]}" in
        gh-work/*|gh-me/*)
          args[$i]="${args[$i]/\//:}"
          ;;
      esac
    done

    command ghq rm "${args[@]}"
  else
    command ghq "$@"
  fi
}

if [ -f "$HOME/.config/zsh/local.zsh" ]; then
  source "$HOME/.config/zsh/local.zsh"
fi
