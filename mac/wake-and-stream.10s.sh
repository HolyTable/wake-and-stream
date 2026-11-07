#!/bin/bash
# <swiftbar.title>wake-and-stream</swiftbar.title>
# <swiftbar.desc>Turn your Windows PC on, connect, play and shut it down from the menu bar (uses the pc command)</swiftbar.desc>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
#
# SwiftBar plugin. "10s" in the file name = refresh every 10 seconds.
# Without argument: prints icon + menu. With argument (on/work/play/stop/release/off/sleep):
# asks for confirmation where needed, runs "pc <argument>" and shows the result as a notification.

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
# shellcheck source=/dev/null
. "$HOME/.config/wake-and-stream/lib.sh" 2>/dev/null || { echo "⚠ | sfimage=exclamationmark.triangle"; echo "---"; echo "wake-and-stream is not installed"; exit 0; }
SELF="${SWIFTBAR_PLUGIN_PATH:-$0}"

notify() { osascript -e "display notification \"$1\" with title \"PC\"" >/dev/null 2>&1; }

# Confirmation dialog: $1 = question, $2 = confirm button, $3 = icon name (power-on/power-off/sleep).
# "Cancel" is the default button, so an accidental Enter does nothing. Returns 0 if confirmed.
confirm() {
  local icon="caution" file="$WAS_ICONS/$3.icns" cancel
  cancel=$(t d_cancel)
  [ -f "$file" ] && icon="(POSIX file \"$file\" as alias)"
  osascript -e "display dialog \"$1\" with title \"PC\" buttons {\"$cancel\", \"$2\"} default button \"$cancel\" cancel button \"$cancel\" with icon $icon" >/dev/null 2>&1
}

# ---------- action (menu click) ----------
if [ -n "$1" ]; then
  case "$1" in
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
  result=$(pc "$1" 2>&1 | tail -n 1)
  [ -n "$result" ] && notify "$result"
  case "$1" in off|sleep) echo "$1" > "$WAS_STATE" ;; esac
  exit 0
fi

# ---------- display ----------
# menu bar icon: green power = on, red power = off, yellow moon = asleep, ⚠ = home network not reachable
# bar_icon <name> <SF symbol fallback>
bar_icon() {
  local f="$WAS_ICONS/menubar-$1.png"
  if [ -f "$f" ]; then echo "| image=$(base64 -i "$f" | tr -d '\n')"; else echo "| sfimage=$2"; fi
}
item() { echo "$1 | bash=\"$SELF\" param1=$2 terminal=false $3"; }   # item <text> <action> [extra]

if [ -z "$PC_IP" ]; then
  echo "| sfimage=exclamationmark.triangle"; echo "---"; t no_config; exit 0
fi

if ! home_reachable; then
  echo "| sfimage=exclamationmark.triangle"
  echo "---"
  echo "$(t m_open_vpn) | bash=/usr/bin/open param1=-a param2=WireGuard terminal=false sfimage=lock.shield"
  exit 0
fi

if port_open 3389; then
  # Moonlight stream: 2 = open on this Mac right now, 1 = paused (started via the menu/pc, not ended yet), 0 = none.
  # (Apollo/Sunshine only report the stream state to paired clients, so we track it on the Mac.)
  stream=0; rdp=0
  [ -f "$WAS_STREAM" ] && stream=1
  pgrep -x Moonlight >/dev/null && [ $stream -eq 1 ] && stream=2
  # Is this Mac connected via remote desktop? (open connection to port 3389)
  netstat -an -p tcp 2>/dev/null | grep -q "${PC_IP//./\\.}\.3389 .*ESTABLISHED" && rdp=1
  rm -f "$WAS_STATE"

  bar_icon on power.circle.fill
  echo "---"
  if [ $rdp -eq 1 ]; then item "$(t m_work_end)" release "refresh=true sfimage=briefcase.fill"
  else                     item "$(t m_work)" work "sfimage=briefcase"; fi
  if [ $stream -eq 2 ]; then
    item "$(t m_play_end)" stop "refresh=true sfimage=stop.circle"
  elif [ $stream -eq 1 ]; then
    item "$(t m_play_resume)" play "sfimage=gamecontroller.fill"
    item "$(t m_play_end)" stop "refresh=true sfimage=stop.circle"
  else
    item "$(t m_play)" play "sfimage=gamecontroller"
  fi
  echo "---"
  echo "$(t m_power) | sfimage=power"
  item "--$(t m_shutdown)" off "refresh=true"
  item "--$(t m_sleep)" sleep "refresh=true"
else
  rm -f "$WAS_STREAM"   # PC is off/asleep → no stream can be running
  # sleep and off look the same from outside → use what was last chosen in the menu
  if [ "$(cat "$WAS_STATE" 2>/dev/null)" = "sleep" ]; then
    bar_icon sleep moon.zzz
    echo "---"
    item "$(t m_wake)" on "refresh=true sfimage=sun.max"
  else
    bar_icon off power.circle
    echo "---"
    item "$(t m_turn_on)" on "refresh=true sfimage=power"
  fi
  item "$(t m_work)" work "sfimage=briefcase"
  item "$(t m_play)" play "sfimage=gamecontroller"
  echo "---"
fi

echo "$(t m_more) | sfimage=ellipsis.circle"
echo "--UpSnap | href=$UPSNAP_URL"
echo "--Apollo | href=$APOLLO_URL"
