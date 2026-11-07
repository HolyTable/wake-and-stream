#!/bin/bash
# wake-and-stream – shared settings and translations for the "pc" command and the menu bar plugin.
# Works with the bash 3.2 that ships with macOS (no associative arrays).

WAS_HOME="$HOME/.config/wake-and-stream"
WAS_CONFIG="$WAS_HOME/config"
WAS_ICONS="$WAS_HOME/icons"
WAS_STATE="$WAS_HOME/last-state"          # remembers "off" or "sleep" chosen via the menu

# defaults (overridden by the config file)
LANGUAGE=en
PC_IP=""; PC_USER=""; ROUTER_IP=""
UPSNAP_URL=""; KEYCHAIN_SERVICE=wake-and-stream-upsnap
APOLLO_URL=""; STREAM_APP=Desktop
WINDOWS_DIR='C:\ProgramData\WakeAndStream'
RDP_APP="Windows App"; RDP_PC_NAME=Desktop

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
