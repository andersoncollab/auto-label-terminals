# Auto Label Terminals (extension)

Open terminals with a **random native color + icon** and auto-launch your AI CLI.

This is the VS Code / Antigravity extension half of
[Auto Label Terminals](https://github.com/andersoncollab/auto-label-terminals).
The shell-hook half labels tabs from your prompt text; this half gives you the
**true native tab color/icon** that escape sequences can't reach.

## Why an extension is required for native colors

VS Code (and Antigravity, a VS Code fork) only expose a terminal tab's color and
icon through `TerminalOptions` at **creation time**. There is no API setter for
an open terminal and no escape sequence the integrated terminal honors for tab
color. So the only way to get the real native color/icon (the right-click
*Change Color* / *Change Icon* you see in the UI) is to let an extension create
the terminal — which is exactly what this does.

## Commands

- **Auto Label Terminals: New AI Session** — opens a randomly colored + iconed
  terminal and launches an AI CLI (prompts you to choose if more than one is
  configured).
- **Auto Label Terminals: New Colored Terminal** — opens a randomly colored +
  iconed plain shell.

## Settings

| Setting | Default | Description |
| --- | --- | --- |
| `autoLabelTerminals.commands` | `["claude", "gemini"]` | AI CLIs offered by *New AI Session*. >1 ⇒ you pick. |
| `autoLabelTerminals.randomColor` | `true` | Assign a random native tab color. |
| `autoLabelTerminals.randomIcon` | `true` | Assign a random native tab icon. |

## Install (from VSIX)

```bash
code --install-extension auto-label-terminals-0.1.0.vsix
# Antigravity ships its own CLI; if `code` isn't it, use the GUI:
# Extensions panel ▸ "..." ▸ Install from VSIX...
```

## Suggested keybinding

Add to your `keybindings.json` (no default is shipped, to avoid conflicts):

```json
{ "key": "cmd+alt+a", "command": "autoLabelTerminals.newAiSession" }
```

MIT licensed.
