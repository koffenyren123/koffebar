#!/bin/bash
# Installerar koffebar som statusrad i Claude Code.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude/statusline.sh"
SETTINGS="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq saknas. Installera med: brew install jq  (macOS)  eller  sudo apt install jq  (Linux)" >&2
  exit 1
fi

mkdir -p "$HOME/.claude"
cp "$DIR/statusline.sh" "$TARGET"
chmod +x "$TARGET"

# Linux: GNU date använder -d @epoch i stället för -r epoch
if [ "$(uname)" = "Linux" ]; then
  sed -i 's/date -r "\$reset"/date -d @"$reset"/' "$TARGET"
fi

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
tmp=$(mktemp)
jq '.statusLine = {"type":"command","command":"~/.claude/statusline.sh","padding":0}' "$SETTINGS" > "$tmp"
mv "$tmp" "$SETTINGS"

echo "Klart. Starta om Claude Code så visas statusraden."
echo
echo "Förhandsvisning:"
echo '{"model":{"display_name":"Opus"},"effort":{"level":"high"},"workspace":{"current_dir":"/tmp/demo"},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":18,"resets_at":1790000000},"seven_day":{"used_percentage":55,"resets_at":1790300000}}}' | "$TARGET"
echo
