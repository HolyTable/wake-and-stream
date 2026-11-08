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

# SwiftBar starts plugins with a minimal PATH – add the usual folders (after your own ones)
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# shellcheck source=/dev/null
. "$HOME/.config/wake-and-stream/lib.sh" 2>/dev/null || { echo "⚠ | sfimage=exclamationmark.triangle"; echo "---"; echo "wake-and-stream is not installed"; exit 0; }
SELF="${SWIFTBAR_PLUGIN_PATH:-$0}"

# ---------- action (menu click) → action.sh (shared with the widget app) ----------
[ -n "$1" ] && exec bash "$WAS_HOME/action.sh" "$1"

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

was_state
if [ $S_ON -eq 1 ]; then
  stream=$S_STREAM; rdp=$S_RDP
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
  # sleep and off look the same from outside → use what was last chosen in the menu
  if [ "$S_LAST" = "sleep" ]; then
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
