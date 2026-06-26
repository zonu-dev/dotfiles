# === 環境変数 ===
export POD_EXECUTABLE="$HOME/.rbenv/shims/pod"
export BUN_INSTALL="$HOME/.bun"

case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Codex launches non-interactive shells that may skip ~/.zprofile, so expose
# Homebrew binaries here as well.
if [ -d /opt/homebrew/bin ]; then
  case ":$PATH:" in
    *:/opt/homebrew/bin:*) ;;
    *) export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" ;;
  esac
fi
