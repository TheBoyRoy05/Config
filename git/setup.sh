# Sourced by ../setup.sh, which defines CONFIG, OS, MACHINE_NAME and die.
SSH_KEY="$HOME/.ssh/id_ed25519"

github_accepts_ssh() {
  ssh "$@" -T git@github.com 2>&1 | grep -q "successfully authenticated"
}

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/config" "$HOME/.ssh/known_hosts"

# Trust GitHub's host keys from its API over HTTPS rather than whatever answers the first connection.
if ! ssh-keygen -F github.com >/dev/null; then
  curl -fsSL https://api.github.com/meta |
    grep -oE '"(ssh|ecdsa)-[a-z0-9-]+ [A-Za-z0-9+/=]+"' | tr -d '"' | sed 's/^/github.com /' >>"$HOME/.ssh/known_hosts"
fi

if [ "$OS" = macos ]; then
  SSH_INCLUDE="Include $CONFIG/macos/ssh_config"
  # An Include below a Host line would only apply to that host, so it goes first.
  if ! grep -qxF "$SSH_INCLUDE" "$HOME/.ssh/config"; then
    { echo "$SSH_INCLUDE"; echo; cat "$HOME/.ssh/config"; } >"$HOME/.ssh/config.new"
    mv "$HOME/.ssh/config.new" "$HOME/.ssh/config"
  fi
fi

if ! github_accepts_ssh -o BatchMode=yes; then
  [ -e "$SSH_KEY" ] || ssh-keygen -t ed25519 -C "$MACHINE_NAME" -f "$SSH_KEY"
  [ "$OS" = macos ] && ssh-add --apple-use-keychain "$SSH_KEY"
  command -v pbcopy >/dev/null && pbcopy <"$SSH_KEY.pub" && echo "(copied to clipboard)"
  echo "Add this key at https://github.com/settings/ssh/new"
  cat "$SSH_KEY.pub"
  until github_accepts_ssh; do
    printf 'Press Enter once the key is added: '
    read -r _ </dev/tty
  done
fi
echo "GitHub accepts this machine's SSH key"

CONFIG_REMOTE=$(git -C "$CONFIG" remote get-url origin)
case $CONFIG_REMOTE in
  https://github.com/*) git -C "$CONFIG" remote set-url origin "git@github.com:${CONFIG_REMOTE#https://github.com/}" ;;
esac

GIT_INCLUDE="$CONFIG/git/.gitconfig"
git config --global --get-all include.path | sed "s|^~|$HOME|" | grep -qxF "$GIT_INCLUDE" ||
  git config --global --add include.path "$GIT_INCLUDE"
