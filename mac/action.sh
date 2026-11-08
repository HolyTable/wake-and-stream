#!/bin/bash
# wake-and-stream – runs one action after a click in the menu bar or the widget:
#   action.sh <on|work|play|stop|release|off|sleep>
# Asks for confirmation where needed, runs "pc <action>" and shows the result as a notification.
# Installed to ~/.config/wake-and-stream/action.sh (used by the SwiftBar plugin and the widget app).
# WAS_CONFIRMED=1 skips the dialogs (the widget already asked "really …?" itself).

# SwiftBar and the widget app start this with a minimal PATH – add the usual folders (after your own ones)
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# shellcheck source=/dev/null
. "$HOME/.config/wake-and-stream/lib.sh" 2>/dev/null || { echo "wake-and-stream is not installed"; exit 1; }

notify() { osascript -e "display notification \"$1\" with title \"PC\"" >/dev/null 2>&1; }

# Confirmation dialog: $1 = question, $2 = confirm button, $3 = icon name (power-on/power-off/sleep).
# "Cancel" is the default button, so an accidental Enter does nothing. Returns 0 if confirmed.
confirm() {
  local icon="caution" file="$WAS_ICONS/$3.icns" cancel
  cancel=$(t d_cancel)
  [ -f "$file" ] && icon="(POSIX file \"$file\" as alias)"
  osascript -e "display dialog \"$1\" with title \"PC\" buttons {\"$cancel\", \"$2\"} default button \"$cancel\" cancel button \"$cancel\" with icon $icon" >/dev/null 2>&1
}

[ -n "$1" ] || { echo "usage: action.sh <on|work|play|stop|release|off|sleep>"; exit 1; }

[ "$WAS_CONFIRMED" = 1 ] || case "$1" in
  on|work|play)
    port_open 3389 || confirm "$(t d_turn_on)" "$(t m_turn_on)" power-on || exit 0 ;;
  off)   confirm "$(t d_shutdown)" "$(t m_shutdown)" power-off || exit 0 ;;
  sleep) confirm "$(t d_sleep)" "$(t m_sleep)" sleep || exit 0 ;;
esac
case "$1" in
  on)    notify "$(t waking)" ;;
  off)   notify "$(t n_shutting)" ;;
  sleep) notify "$(t n_sleeping)" ;;
esac
output=$(pc "$1" 2>&1); rc=$?
result=$(printf '%s\n' "$output" | tail -n 1)
[ -n "$result" ] && notify "$result"
# remember "off"/"sleep" only if it worked
if [ $rc -eq 0 ]; then case "$1" in off|sleep) echo "$1" > "$WAS_STATE" ;; esac; fi
exit 0
