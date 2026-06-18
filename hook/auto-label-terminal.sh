#!/usr/bin/env bash
# Auto Label Terminals — Claude Code UserPromptSubmit hook.
#
# On the FIRST prompt of a Claude Code session, reads what you typed and labels
# the terminal tab with a random color, a task icon, and a short summary, e.g.:
#
#     🟣 🚀 valuation-lab — Deploy the fly app and verify it boots
#
# How it works:
#   - Reads the hook JSON on stdin ({prompt, session_id, cwd}).
#   - Random color dot per session (so tabs are visually distinct at a glance).
#   - Task icon chosen from keywords in the prompt.
#   - Writes an OSC title escape to the controlling terminal (/dev/tty) — NOT
#     stdout, which Claude Code captures into the model's context.
#   - Fires once per session via a /tmp marker keyed by session_id.
#   - On iTerm2 only, also emits the proprietary OSC 6 escape to tint the real
#     tab/title-bar color. VS Code / Antigravity ignore tab-color escapes
#     entirely (a hard platform limit) — there the colored emoji dot is the
#     signal, and the companion extension provides true native coloring.
#
# Env overrides:
#   ALT_ICONS=0     disable the task icon
#   ALT_PROJECT=0   omit the project (cwd basename) from the label
#   ALT_MAXLEN=N    max characters of the prompt summary (default 48)
set -euo pipefail

input="$(cat)"
prompt="$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)"
session="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"

[ -z "$prompt" ] && exit 0

# Fire only on the first prompt of a session.
marker="/tmp/auto-label-terminal-${session:-nosession}.done"
[ -e "$marker" ] && exit 0
: > "$marker" 2>/dev/null || true

proj="$(basename "${cwd:-$PWD}")"

# --- Random color (per session) -------------------------------------------
# Index shared by the emoji dot and the iTerm2 true-color RGB so they agree.
circles=( "🔴" "🟠" "🟡" "🟢" "🔵" "🟣" "🟤" )
#         red    orange  yellow  green   blue    purple  brown
reds=(    222    230     224     74      88      155     140 )
greens=(  72     126     185     180     130     89      94   )
blues=(   67     34      45      86      222     182     62   )
n=${#circles[@]}
# $RANDOM is plenty for "sort of random"; fall back to PID if unset.
idx=$(( ${RANDOM:-$$} % n ))
circle="${circles[$idx]}"

# --- Task icon from prompt keywords (first match wins) --------------------
icon=""
if [ "${ALT_ICONS:-1}" != "0" ]; then
  lc="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"
  icon="💬"
  case "$lc" in
    *deploy*|*ship*|*release*|*publish*)              icon="🚀" ;;
    *bug*|*broken*|*crash*|*error*|*fail*)            icon="🐛" ;;
    *fix*|*patch*|*repair*)                           icon="🔧" ;;
    *test*|*spec*|*qa*)                               icon="🧪" ;;
    *refactor*|*cleanup*|*clean\ up*)                 icon="🧹" ;;
    *doc*|*readme*|*write*|*draft*|*blog*)            icon="📝" ;;
    *design*|*brand*|*logo*|*\ ui*|*css*|*style*)     icon="🎨" ;;
    *ad*|*ads*|*campaign*|*marketing*|*meta*)         icon="📣" ;;
    *trade*|*stock*|*ticker*|*valuation*|*portfolio*) icon="📈" ;;
    *sql*|*database*|*supabase*|*migration*)          icon="🗄️" ;;
    *security*|*auth*|*vuln*)                          icon="🔒" ;;
    *seo*|*rank*)                                     icon="🔎" ;;
    *email*|*gmail*|*mail*)                           icon="📧" ;;
  esac
fi

# --- Short name from the prompt -------------------------------------------
maxlen="${ALT_MAXLEN:-48}"
name="$(printf '%s' "$prompt" | tr '\n\r\t' '   ' | tr -s ' ' | sed -E 's/^ +//; s/ +$//')"
[ "${#name}" -gt "$maxlen" ] && name="${name:0:$((maxlen-3))}..."

# --- Compose label --------------------------------------------------------
label="$circle"
[ -n "$icon" ] && label="$label $icon"
if [ "${ALT_PROJECT:-1}" != "0" ] && [ -n "$proj" ]; then
  label="$label $proj — $name"
else
  label="$label $name"
fi

# --- Emit to the terminal (NOT stdout) ------------------------------------
if { exec 9>/dev/tty; } 2>/dev/null; then
  # OSC 0/2: tab title. Works everywhere, including VS Code / Antigravity.
  printf '\033]0;%s\007' "$label" >&9
  printf '\033]2;%s\007' "$label" >&9

  # iTerm2 only: real tab/title-bar color via the proprietary OSC 6 escape.
  if [ "${TERM_PROGRAM:-}" = "iTerm.app" ]; then
    printf '\033]6;1;bg;red;brightness;%s\007'   "${reds[$idx]}"   >&9
    printf '\033]6;1;bg;green;brightness;%s\007' "${greens[$idx]}" >&9
    printf '\033]6;1;bg;blue;brightness;%s\007'  "${blues[$idx]}"  >&9
  fi

  exec 9>&-
fi

exit 0
