# Sourced by ../setup.sh, which defines CONFIG, OS and link.
case $OS in
  macos) EDITOR_SETTINGS="$HOME/Library/Application Support" ;;
esac

for editor in Kiro Cursor Code; do
  if [ -d "$EDITOR_SETTINGS/$editor/User" ]; then
    link "$CONFIG/vscode/settings.json" "$EDITOR_SETTINGS/$editor/User/settings.json"
  fi
done

for cli in kiro cursor code; do
  command -v "$cli" >/dev/null || continue
  installed=$("$cli" --list-extensions)
  while read -r extension; do
    echo "$installed" | grep -qixF "$extension" || "$cli" --install-extension "$extension"
  done <"$CONFIG/vscode/extensions.txt"
done
