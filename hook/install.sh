#!/usr/bin/env bash
# Auto Label Terminals — installer for the Claude Code hook.
#
# Copies the hook script into ~/.claude/scripts/ and registers a
# UserPromptSubmit hook in ~/.claude/settings.json, merging with any existing
# hooks (it never clobbers your other hooks). Idempotent: re-running updates
# the script and leaves a single hook entry.
#
# Requires: jq
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/auto-label-terminal.sh"

claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
scripts_dir="$claude_dir/scripts"
settings="$claude_dir/settings.json"
dest="$scripts_dir/auto-label-terminal.sh"

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)"; exit 1; }
[ -f "$src" ] || { echo "error: cannot find $src"; exit 1; }

mkdir -p "$scripts_dir"
cp "$src" "$dest"
chmod +x "$dest"
echo "✓ installed hook script → $dest"

# Settings.json: create if missing, then merge the UserPromptSubmit hook.
[ -f "$settings" ] || echo '{}' > "$settings"

cmd="$dest"
tmp="$(mktemp)"
jq --arg cmd "$cmd" '
  .hooks = (.hooks // {})
  | .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // [])
  # Drop any prior auto-label entry so re-running stays idempotent.
  | .hooks.UserPromptSubmit = (
      [ .hooks.UserPromptSubmit[]
        | select( ([ .hooks[]?.command ] | any(. == $cmd)) | not )
      ]
    )
  | .hooks.UserPromptSubmit += [
      { "hooks": [ { "type": "command", "command": $cmd, "async": true, "timeout": 5 } ] }
    ]
' "$settings" > "$tmp"

# Validate before replacing.
jq empty "$tmp"
mv "$tmp" "$settings"
echo "✓ registered UserPromptSubmit hook in $settings"
echo
echo "Done. The hook fires on your NEXT prompt in a new Claude Code session."
echo "If it doesn't, open /hooks once (reloads config) or restart Claude Code."
