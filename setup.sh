#!/bin/sh
# Sets up this machine from this repo. Safe to rerun.
set -eu

CONFIG=$(cd "$(dirname "$0")" && pwd)
WORK=$(dirname "$CONFIG")
MACHINE_ENV="$HOME/.config/machine.env"

die() {
  echo "setup: $1" >&2
  exit 1
}

# Replaces an existing symlink, but never a real file: that may hold work not in this repo.
link() {
  source=$1 target=$2
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    die "$target is a real file, move it aside and rerun"
  fi
  mkdir -p "$(dirname "$target")"
  ln -sfn "$source" "$target"
  echo "linked $target"
}

case $(uname -s) in
  Darwin) OS=macos ;;
  *) die "no setup for $(uname -s) yet" ;;
esac

PREVIOUS_NAME=""
[ -r "$MACHINE_ENV" ] && PREVIOUS_NAME=$(. "$MACHINE_ENV" && echo "$MACHINE_NAME")
MACHINE_NAME=""
until [ -n "$MACHINE_NAME" ]; do
  printf 'Machine name for commit messages [%s]: ' "$PREVIOUS_NAME"
  read -r answer || die "no machine name given"
  MACHINE_NAME=${answer:-$PREVIOUS_NAME}
done

mkdir -p "$(dirname "$MACHINE_ENV")"
printf 'WORK=%s\nMACHINE_NAME=%s\n' "'$WORK'" "'$MACHINE_NAME'" >"$MACHINE_ENV"
echo "wrote $MACHINE_ENV"

# OS setup installs tools, so it runs before folders that need them.
. "$CONFIG/$OS/setup.sh"
. "$CONFIG/git/setup.sh"
. "$CONFIG/vscode/setup.sh"
. "$CONFIG/obsidian/setup.sh"
echo "setup done"
