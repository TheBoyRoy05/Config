# Sourced by ../setup.sh, which defines CONFIG, link and die.
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # The installer does not add brew to this shell's PATH.
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew bundle --no-upgrade --file "$CONFIG/macos/Brewfile"

link "$CONFIG/macos/sleep" "$HOME/.sleep"
link "$CONFIG/macos/wakeup" "$HOME/.wakeup"
brew services restart sleepwatcher
