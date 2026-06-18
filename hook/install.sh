#!/usr/bin/env bash
# Auto Label Terminals — installer for the prompt-aware hook.
#
# Usage:
#   bash hook/install.sh [claude|gemini|both]   (default: claude)
#
# Installs the hook script into ~/.claude/scripts/ and registers a
# UserPromptSubmit hook in the target tool's settings.json, merging with any
# existing hooks (never clobbers them). Idempotent.
#
# NOTE on Claude: Claude Code manages its own tab title (the conversation topic)
# and reclaims it after each turn. There is no documented switch to disable that
# (CLAUDE_CODE_DISABLE_TERMINAL_TITLE only affects the title RESET on shutdown,
# not the in-session title), so the hook label is only transient on Claude — use
# the extension for a sticky native color+icon there. Gemini CLI does NOT manage
# the title and its hook schema is Claude-compatible, so the label sticks on
# Gemini with the same script.
#
# Requires: jq
set -euo pipefail

target="${1:-claude}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/auto-label-terminal.sh"
dest="$HOME/.claude/scripts/auto-label-terminal.sh"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)"; exit 1; }
[ -f "$src" ] || { echo "error: cannot find $src"; exit 1; }

# Always install the script under ~/.claude/scripts (shared by both tools).
mkdir -p "$HOME/.claude/scripts"
cp "$src" "$dest"
chmod +x "$dest"
echo "✓ installed hook script → $dest"

register() { # $1 = settings.json path, $2 = "claude"|"gemini"
  local settings="$1" tool="$2" tmp
  mkdir -p "$(dirname "$settings")"
  [ -f "$settings" ] || echo '{}' > "$settings"
  tmp="$(mktemp)"
  jq --arg cmd "$dest" '
    .hooks = (.hooks // {})
    | .hooks.UserPromptSubmit = ([ (.hooks.UserPromptSubmit // [])[]
        | select( ([.hooks[]?.command] | any(. == $cmd)) | not ) ])
      + [ { "hooks": [ { "type":"command", "command":$cmd, "async":true, "timeout":5 } ] } ]
  ' "$settings" > "$tmp"
  jq empty "$tmp"
  mv "$tmp" "$settings"
  echo "✓ registered UserPromptSubmit hook in $settings"
  if [ "$tool" = "claude" ]; then
    echo "  NOTE: Claude Code manages its own tab title (the conversation topic),"
    echo "  and reclaims it after each turn — there is no switch to disable this, so"
    echo "  the hook label is only transient on Claude. For a STICKY color+icon on"
    echo "  Claude tabs, use the extension (extension/). The hook fully sticks on"
    echo "  Gemini, which does not manage the title."
  fi
}

case "$target" in
  claude) register "$HOME/.claude/settings.json" claude ;;
  gemini) register "$HOME/.gemini/settings.json" gemini ;;
  both)   register "$HOME/.claude/settings.json" claude
          register "$HOME/.gemini/settings.json" gemini ;;
  *) echo "usage: install.sh [claude|gemini|both]"; exit 2 ;;
esac

echo
echo "Done. The hook fires on the FIRST prompt of a NEW session. Start a fresh"
echo "session to test. On Claude the label is transient (Claude owns the title);"
echo "use the extension for a sticky native color+icon on Claude tabs."
