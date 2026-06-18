# Auto Label Terminals

Stop manually renaming terminal tabs. **Auto Label Terminals** gives every
AI-coding terminal a distinct **color, icon, and name** so you can tell at a
glance which tab is doing what.

It comes in two complementary halves — use either or both:

| | What it does | Works with |
| --- | --- | --- |
| **Hook** (`hook/`) | Reads your **first prompt** and labels the tab `🟣 🚀 project — your prompt` (random color dot + task icon + summary). | **Claude Code** and **Gemini CLI** (Gemini's hook schema is Claude-compatible). |
| **Extension** (`extension/`) | Opens a terminal with a **true native random color + icon**, then launches your AI CLI. | Any VS Code fork (Antigravity / Cursor / VS Code) + **any CLI** (Claude, Gemini, Codex, ...). |

### "Fire it for Gemini, Codex, etc.?"

- **Gemini CLI** — yes. Its hooks are Claude-Code-compatible (it even ships
  `gemini hooks migrate --from-claude`). Run `bash hook/install.sh gemini`. Bonus:
  Gemini doesn't manage the terminal title, so the label sticks with no extra config.
- **Codex CLI** — Codex has a (trust-gated) hook system; a prompt-submit wiring is
  on the roadmap. In the meantime the **extension** covers Codex: launch `codex`
  through *New AI Session* for a native colored+iconed tab.
- **Any other tool** — the extension is universal; add the command to
  `autoLabelTerminals.commands`.

## The honest limitation (why there are two halves)

VS Code — and Antigravity, which is a fork of it — **do not let any script or
escape sequence set a terminal tab's native color or icon.** Those are only
settable by an extension at terminal-creation time. A hook running *inside* your
terminal therefore can't drive the native *Change Color* / *Change Icon* menus.

So:

- The **hook** conveys color with a colored-circle emoji in the tab title
  (`🟣`), which renders in every terminal including Antigravity. On **iTerm2** it
  *also* tints the real tab via iTerm2's proprietary escape.
- The **extension** is the only way to get a real native colored+iconed tab in
  Antigravity — and as a bonus it's harness-agnostic, so it works for Gemini,
  Claude, or any CLI you point it at.

## Quick start

### Hook (Claude Code and/or Gemini CLI)

```bash
git clone https://github.com/andersoncollab/auto-label-terminals.git
cd auto-label-terminals
bash hook/install.sh both      # or: claude  |  gemini
```

Fires on the **first prompt** of a new session. Start a fresh session to test.

**Claude Code overwrites the tab title** with its own topic/version string, so the
installer sets `CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1` (in `~/.claude/settings.json`
and you should also `export` it in your shell rc, since Claude reads it at
startup). Gemini doesn't touch the title, so no switch is needed there.

If the hook doesn't fire, open `/hooks` once (reloads config) or restart. To
uninstall, remove the `UserPromptSubmit` entry pointing at `auto-label-terminal.sh`
from the relevant `settings.json`.

Hook env overrides: `ALT_ICONS=0` (no icon), `ALT_PROJECT=0` (no project name),
`ALT_MAXLEN=N` (summary length).

### Extension (Antigravity / VS Code / Cursor)

```bash
cd extension
npx @vscode/vsce package          # produces auto-label-terminals-0.1.0.vsix
code --install-extension auto-label-terminals-0.1.0.vsix
```

(In Antigravity's GUI: Extensions panel ▸ `...` ▸ *Install from VSIX...*.)

Then run **Auto Label Terminals: New AI Session** from the command palette and
pick `claude` or `gemini`. Configure the CLI list under
`autoLabelTerminals.commands`.

## How the hook labels tabs

- **Color** — random per session (a fixed 7-color palette), so adjacent tabs
  look different.
- **Icon** — chosen from keywords in the prompt: deploy 🚀 · bug 🐛 · fix 🔧 ·
  test 🧪 · refactor 🧹 · docs 📝 · design 🎨 · ads 📣 · trade 📈 · sql 🗄️ ·
  security 🔒 · seo 🔎 · email 📧 · else 💬.
- **Name** — a trimmed summary of your prompt.

## Other terminals

iTerm2, kitty, and WezTerm support real tab colors via escape sequences; the
hook currently emits iTerm2's. PRs adding kitty/WezTerm/Konsole are welcome.

## License

MIT © 2026 Trevor Anderson
