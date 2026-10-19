# Sourced by ../setup.sh, which defines CONFIG, WORK, OS and die.
VAULT_REMOTE="git@github.com:TheBoyRoy05/ObsidianVault.git"
[ -d "$WORK/Vault" ] || git clone "$VAULT_REMOTE" "$WORK/Vault"

# The Web Clipper export reads Arc's store under ~/Library, so it only runs on macOS.
if [ "$OS" = macos ]; then
  command -v mise >/dev/null || die "mise missing, macos/Brewfile installs it"
  mise exec node@22 -- npm ci --prefix "$CONFIG/obsidian" --no-fund --no-audit
fi
