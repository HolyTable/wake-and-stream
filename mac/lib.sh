#!/bin/bash
# wake-and-stream – shared settings and translations for the "pc" command and the menu bar plugin.
# Works with the bash 3.2 that ships with macOS (no associative arrays).

WAS_HOME="$HOME/.config/wake-and-stream"
WAS_CONFIG="$WAS_HOME/config"
WAS_ICONS="$WAS_HOME/icons"
WAS_STATE="$WAS_HOME/last-state"          # remembers "off" or "sleep" chosen via the menu
WAS_STREAM="$WAS_HOME/stream-active"      # exists while a Moonlight stream was started and not ended
                                          # (Apollo/Sunshine only tell paired clients whether a stream runs)

# defaults (overridden by the config file)
LANGUAGE=en
PC_IP=""; PC_USER=""; ROUTER_IP=""
UPSNAP_URL=""; KEYCHAIN_SERVICE=wake-and-stream-upsnap
APOLLO_URL=""; STREAM_APP=Desktop
WINDOWS_DIR='C:\ProgramData\WakeAndStream'
RDP_APP="Windows App"; RDP_PC_NAME=Desktop
PLAY_FULLSCREEN=no

# shellcheck source=/dev/null
[ -f "$WAS_CONFIG" ] && . "$WAS_CONFIG"
[ -n "$APOLLO_URL" ] || APOLLO_URL="https://$PC_IP:47990"

# t <key> [arg] – translated text
t() {
  case "$LANGUAGE:$1" in
    de:no_config)       echo "Keine Konfiguration gefunden: $WAS_CONFIG – zuerst install.sh ausführen." ;;
    *:no_config)        echo "No configuration found: $WAS_CONFIG – run install.sh first." ;;
    de:no_home)         echo "Heimnetz nicht erreichbar – VPN an?" ;;
    *:no_home)          echo "Home network not reachable – is the VPN on?" ;;
    de:waking)          echo "PC wird eingeschaltet …" ;;
    *:waking)           echo "Turning the PC on …" ;;
    de:wake_fallback)   echo "Direktes Einschalten ging nicht – UpSnap öffnet sich, dort auf Einschalten klicken." ;;
    *:wake_fallback)    echo "Could not wake the PC directly – UpSnap opens, click wake there." ;;
    de:waiting)         printf "Warte auf PC" ;;
    *:waiting)          printf "Waiting for PC" ;;
    de:arrived)         echo " – da!" ;;
    *:arrived)          echo " – there!" ;;
    de:timeout)         echo "PC nach 3 Minuten nicht erreichbar." ;;
    *:timeout)          echo "PC not reachable after 3 minutes." ;;
    de:already_on)      echo "PC läuft schon." ;;
    *:already_on)       echo "PC is already on." ;;
    de:ready)           echo "PC ist bereit." ;;
    *:ready)            echo "PC is ready." ;;
    de:rdp_ready)       echo "PC ist bereit – in der $RDP_APP auf „$RDP_PC_NAME“ doppelklicken." ;;
    *:rdp_ready)        echo "PC is ready – double-click \"$RDP_PC_NAME\" in $RDP_APP." ;;
    de:moon_start)      echo "Moonlight startet." ;;
    *:moon_start)       echo "Starting Moonlight." ;;
    de:stopping)        echo "Stream wird beendet – Monitore gehen gleich wieder an." ;;
    *:stopping)         echo "Ending the stream – monitors will turn back on." ;;
    de:released)        echo "Remotedesktop beendet." ;;
    *:released)         echo "Remote desktop ended." ;;
    de:shutting_down)   echo "PC fährt herunter." ;;
    *:shutting_down)    echo "PC is shutting down." ;;
    de:sleeping)        echo "PC schläft." ;;
    *:sleeping)         echo "PC is asleep." ;;
    de:is_on)           echo "PC ist an." ;;
    *:is_on)            echo "PC is on." ;;
    de:is_off)          echo "PC ist aus (oder nicht erreichbar)." ;;
    *:is_off)           echo "PC is off (or not reachable)." ;;
    # menu bar
    de:m_open_vpn)      echo "VPN öffnen" ;;
    *:m_open_vpn)       echo "Open VPN" ;;
    de:m_turn_on)       echo "Einschalten" ;;
    *:m_turn_on)        echo "Turn on" ;;
    de:m_wake)          echo "Aufwecken" ;;
    *:m_wake)           echo "Wake up" ;;
    de:m_work)          echo "Arbeiten" ;;
    *:m_work)           echo "Work" ;;
    de:m_work_end)      echo "Arbeiten beenden" ;;
    *:m_work_end)       echo "End work session" ;;
    de:m_play)          echo "Spielen" ;;
    *:m_play)           echo "Play" ;;
    de:m_play_resume)   echo "Weiterspielen" ;;
    *:m_play_resume)    echo "Resume playing" ;;
    de:m_play_end)      echo "Spielen beenden" ;;
    *:m_play_end)       echo "End play session" ;;
    de:m_power)         echo "Ausschalten" ;;
    *:m_power)          echo "Power" ;;
    de:m_shutdown)      echo "Herunterfahren" ;;
    *:m_shutdown)       echo "Shut down" ;;
    de:m_sleep)         echo "Standby" ;;
    *:m_sleep)          echo "Sleep" ;;
    de:m_more)          echo "Mehr" ;;
    *:m_more)           echo "More" ;;
    # dialogs
    de:d_cancel)        echo "Abbrechen" ;;
    *:d_cancel)         echo "Cancel" ;;
    de:d_turn_on)       echo "Der PC ist aus. Wirklich einschalten?" ;;
    *:d_turn_on)        echo "The PC is off. Really turn it on?" ;;
    de:d_shutdown)      echo "PC wirklich herunterfahren? Nicht gespeicherte Arbeit geht verloren." ;;
    *:d_shutdown)       echo "Really shut down the PC? Unsaved work will be lost." ;;
    de:d_sleep)         echo "PC wirklich schlafen legen?" ;;
    *:d_sleep)          echo "Really put the PC to sleep?" ;;
    de:n_shutting)      echo "PC wird heruntergefahren …" ;;
    *:n_shutting)       echo "Shutting down the PC …" ;;
    de:n_sleeping)      echo "PC wird schlafen gelegt …" ;;
    *:n_sleeping)       echo "Putting the PC to sleep …" ;;
    *)                  echo "$1" ;;
  esac
}

# Is a TCP port on the PC reachable?
port_open() { nc -z -G 2 "$PC_IP" "$1" >/dev/null 2>&1; }

# Is the home network reachable (directly or through the VPN)?
home_reachable() { ping -c1 -t1 "$ROUTER_IP" >/dev/null 2>&1; }

# was_state – checks everything once and sets (used by the menu bar plugin and the widget app):
#   S_HOME   1 = home network reachable
#   S_ON     1 = PC is on
#   S_STREAM 2 = Moonlight stream open on this Mac, 1 = paused (started, not ended), 0 = none
#   S_RDP    1 = this Mac is connected via remote desktop
#   S_LAST   "sleep"/"off" = what was last chosen while the PC is off (both look the same from outside)
# (Apollo/Sunshine only report the stream state to paired clients, so we track it on the Mac.)
was_state() {
  S_HOME=0; S_ON=0; S_STREAM=0; S_RDP=0; S_LAST=""
  home_reachable || return 0
  S_HOME=1
  if port_open 3389; then
    S_ON=1
    [ -f "$WAS_STREAM" ] && S_STREAM=1
    pgrep -x Moonlight >/dev/null && [ $S_STREAM -eq 1 ] && S_STREAM=2
    # remote desktop from this Mac? Only possible while the remote desktop app runs.
    if pgrep -x "$RDP_APP" >/dev/null; then
      if netstat -an 2>/dev/null | grep -q "^tcp"; then
        # open connection to port 3389 of the PC
        netstat -an 2>/dev/null | grep -q "${PC_IP//./\\.}\.3389 .*ESTABLISHED" && S_RDP=1
      else
        # macOS hides the connection list from background apps (the widget app) → ask the PC:
        # an active session "rdp-tcp#<n>" (state Active/Aktiv) means someone is connected
        ssh -o BatchMode=yes -o ConnectTimeout=3 "$PC_USER@$PC_IP" qwinsta 2>/dev/null |
          grep -q -i -E "rdp-tcp#[0-9]+ .*(activ|aktiv)" && S_RDP=1
      fi
    fi
    rm -f "$WAS_STATE"
  else
    rm -f "$WAS_STREAM"   # PC is off/asleep → no stream can be running
    S_LAST=$(cat "$WAS_STATE" 2>/dev/null)
  fi
  return 0
}
