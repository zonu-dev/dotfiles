typeset -U path

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Drop stale or broken entries inherited from older shell settings.
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
unset entry
unset __MISE_ORIG_PATH __MISE_DIFF __MISE_SESSION

# === PATH ===
# .NET Core SDK tools
export PATH="$PATH:$HOME/.dotnet/tools"

# Added by Toolbox App
path+=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts")

# Homebrew packages
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Android SDK
export PATH="$PATH:$HOME/Library/Android/sdk/platform-tools"

# bun
export PATH="$BUN_INSTALL/bin:$PATH"

# maestro
export PATH="$HOME/.maestro/bin:$PATH"

# Godot
export GODOT_BIN="/opt/homebrew/bin/godot"
