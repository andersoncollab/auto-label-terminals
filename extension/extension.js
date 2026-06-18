// Auto Label Terminals — VS Code / Antigravity extension.
//
// VS Code only lets you set a terminal tab's color/icon at creation time, via
// the extension API (TerminalOptions.color / .iconPath). There is no setter for
// an already-open terminal, and no escape sequence the integrated terminal
// honors for tab color. So the only way to get a TRUE native colored+iconed
// tab (the right-click "Change Color" / "Change Icon" menus) is to have an
// extension create the terminal. That's what this does: it opens a terminal
// with a random native color + icon, then launches your chosen AI CLI in it.
//
// Harness-agnostic: works the same whether you launch `claude`, `gemini`, or
// anything else.

const vscode = require('vscode');

// Native terminal tab colors are referenced by ThemeColor id; only the
// terminal.ansi* ids are valid for tab coloring.
const COLORS = [
  'terminal.ansiRed',
  'terminal.ansiGreen',
  'terminal.ansiYellow',
  'terminal.ansiBlue',
  'terminal.ansiMagenta',
  'terminal.ansiCyan',
  'terminal.ansiBrightRed',
  'terminal.ansiBrightGreen',
  'terminal.ansiBrightYellow',
  'terminal.ansiBrightBlue',
  'terminal.ansiBrightMagenta',
  'terminal.ansiBrightCyan',
];

// Codicon ids (https://microsoft.github.io/vscode-codicons/).
const ICONS = [
  'rocket', 'bug', 'beaker', 'paintcan', 'megaphone', 'graph-line',
  'database', 'lock', 'search', 'mail', 'comment-discussion', 'flame',
  'star-full', 'zap', 'sparkle', 'globe', 'heart', 'terminal',
];

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function makeTerminal(name, launchCmd) {
  const cfg = vscode.workspace.getConfiguration('autoLabelTerminals');
  const opts = { name };
  if (cfg.get('randomColor', true)) {
    opts.color = new vscode.ThemeColor(pick(COLORS));
  }
  if (cfg.get('randomIcon', true)) {
    opts.iconPath = new vscode.ThemeIcon(pick(ICONS));
  }
  const term = vscode.window.createTerminal(opts);
  term.show();
  if (launchCmd) {
    term.sendText(launchCmd, true);
  }
  return term;
}

async function newAiSession() {
  const cfg = vscode.workspace.getConfiguration('autoLabelTerminals');
  const commands = cfg.get('commands', ['claude', 'gemini']);
  let cmd = commands[0];
  if (commands.length > 1) {
    const choice = await vscode.window.showQuickPick(commands, {
      placeHolder: 'Launch which AI CLI?',
    });
    if (!choice) {
      return; // user dismissed the picker
    }
    cmd = choice;
  }
  if (!cmd) {
    vscode.window.showWarningMessage(
      'Auto Label Terminals: no command configured (autoLabelTerminals.commands).'
    );
    return;
  }
  // Friendly tab name from the command's first token (e.g. "claude").
  const name = String(cmd).trim().split(/\s+/)[0] || 'ai';
  makeTerminal(name, cmd);
}

function newColoredTerminal() {
  makeTerminal('shell', undefined);
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('autoLabelTerminals.newAiSession', newAiSession),
    vscode.commands.registerCommand('autoLabelTerminals.newColoredTerminal', newColoredTerminal)
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
