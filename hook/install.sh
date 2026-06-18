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
# Claude Code actively manages the terminal title (it writes the conversation
# topic / version), so for Claude we also set CLAUDE_CODE_DISABLE_TERMINAL_TITLE
# so our label isn't immediately overwritten. Gemini CLI does not touch the
# title, so no such switch is needed there — and Gemini's hook schema is
# Claude-compatible, so the same script works as-is.
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
  if [ "$tool" = "claude" ]; then
    jq '.env = (.env // {}) | .env.CLAUDE_CODE_DISABLE_TERMINAL_TITLE = "1"' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
  fi
  jq empty "$tmp"
  mv "$tmp" "$settings"
  echo "✓ registered UserPromptSubmit hook in $settings"
  [ "$tool" = "claude" ] && echo "✓ set CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1 (so Claude won't overwrite the label)"
}

case "$target" in
  claude) register "$HOME/.claude/settings.json" claude ;;
  gemini) register "$HOME/.gemini/settings.json" gemini ;;
  both)   register "$HOME/.claude/settings.json" claude
          register "$HOME/.gemini/settings.json" gemini ;;
  *) echo "usage: install.sh [claude|gemini|both]"; exit 2 ;;
esac

echo
if [ "$target" = "claude" ] || [ "$target" = "both" ]; then
  echo "Claude: for reliability, also add to your shell rc (var is read at startup):"
  echo "    export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1"
fi
echo "Done. The hook fires on the FIRST prompt of a NEW session. Start a fresh"
echo "session to test."
