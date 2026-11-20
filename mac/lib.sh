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
PS5_IP=""; PS5_NAME=""; PS5_REGISTKEY=""; PS5_APP=chiaki-ng; PS5_FULLSCREEN=no
PS5_PORT=9302                             # PS5 discovery/wake port (only changed by the tests)
PS5_CHIAKI_PLIST="$HOME/Library/Preferences/com.chiaki.Chiaki.plist"   # chiaki-ng's settings

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
    # pc doctor
    de:dr_title)        echo "pc doktor – prüfe alles einmal durch (ändert nichts) …" ;;
    *:dr_title)         echo "pc doctor – checking every link once (changes nothing) …" ;;
    de:dr_config)       echo "Einstellungen" ;;
    *:dr_config)        echo "Settings" ;;
    de:dr_config_missing) printf "fehlt:" ;;
    *:dr_config_missing)  printf "missing:" ;;
    de:dr_config_hint)  echo "in $WAS_CONFIG eintragen oder install.sh erneut ausführen" ;;
    *:dr_config_hint)   echo "add it to $WAS_CONFIG or run install.sh again" ;;
    de:dr_home)         echo "Heimnetz" ;;
    *:dr_home)          echo "Home network" ;;
    de:dr_home_ok)      echo "Router $ROUTER_IP antwortet" ;;
    *:dr_home_ok)       echo "router $ROUTER_IP answers" ;;
    de:dr_home_bad)     echo "Router $ROUTER_IP antwortet nicht" ;;
    *:dr_home_bad)      echo "router $ROUTER_IP does not answer" ;;
    de:dr_home_hint)    echo "unterwegs: VPN an? (und nur eines – nicht zwei VPNs gleichzeitig)" ;;
    *:dr_home_hint)     echo "away from home: is the VPN on? (only one – never two VPNs at once)" ;;
    de:dr_rest)         echo "Rest" ;;
    *:dr_rest)          echo "Rest" ;;
    de:dr_rest_skipped) echo "UpSnap, PC, SSH, Apollo übersprungen (ohne Heimnetz nicht prüfbar)" ;;
    *:dr_rest_skipped)  echo "UpSnap, PC, SSH, Apollo skipped (can't be checked without the home network)" ;;
    de:dr_upsnap_down)  echo "$UPSNAP_URL antwortet nicht" ;;
    *:dr_upsnap_down)   echo "$UPSNAP_URL does not answer" ;;
    de:dr_upsnap_down_hint) echo "läuft der UpSnap-Container auf dem NAS? Adresse in UPSNAP_URL richtig?" ;;
    *:dr_upsnap_down_hint)  echo "is the UpSnap container running on the NAS? UPSNAP_URL correct?" ;;
    de:dr_upsnap_nokey) echo "erreichbar, aber kein Login im Schlüsselbund ($KEYCHAIN_SERVICE)" ;;
    *:dr_upsnap_nokey)  echo "reachable, but no login in the keychain ($KEYCHAIN_SERVICE)" ;;
    de:dr_upsnap_nokey_hint) echo "security add-generic-password -s $KEYCHAIN_SERVICE -a \"<UpSnap-Benutzer>\" -w" ;;
    *:dr_upsnap_nokey_hint)  echo "security add-generic-password -s $KEYCHAIN_SERVICE -a \"<upsnap-user>\" -w" ;;
    de:dr_upsnap_login) echo "erreichbar, aber der Login wird abgelehnt" ;;
    *:dr_upsnap_login)  echo "reachable, but the login is refused" ;;
    de:dr_upsnap_login_hint) echo "Passwort in UpSnap geändert? Eintrag $KEYCHAIN_SERVICE im Schlüsselbund neu anlegen" ;;
    *:dr_upsnap_login_hint)  echo "password changed in UpSnap? re-create the keychain entry $KEYCHAIN_SERVICE" ;;
    de:dr_upsnap_nodev) echo "Login ok, aber kein Gerät mit der IP $PC_IP" ;;
    *:dr_upsnap_nodev)  echo "login OK, but no device with IP $PC_IP" ;;
    de:dr_upsnap_nodev_hint) echo "in UpSnap das Gerät mit genau dieser IP anlegen (oder PC_IP prüfen)" ;;
    *:dr_upsnap_nodev_hint)  echo "add the device in UpSnap with exactly this IP (or check PC_IP)" ;;
    de:dr_upsnap_ok)    echo "erreichbar, Login ok, PC gefunden" ;;
    *:dr_upsnap_ok)     echo "reachable, login OK, PC found" ;;
    de:dr_pc_off)       echo "aus oder im Standby – PC-Prüfungen übersprungen (erst „pc an“, dann nochmal)" ;;
    *:dr_pc_off)        echo "off or asleep – PC checks skipped (\"pc on\" first, then run this again)" ;;
    de:dr_pc_on)        echo "an (Remotedesktop-Port 3389 antwortet)" ;;
    *:dr_pc_on)         echo "on (remote desktop port 3389 answers)" ;;
    de:dr_ping_ok)      echo "PC antwortet auf Ping (braucht UpSnap für „online“)" ;;
    *:dr_ping_ok)       echo "PC answers ping (UpSnap needs it to show \"online\")" ;;
    de:dr_ping_bad)     echo "PC antwortet nicht auf Ping – UpSnap zeigt ihn dann als aus" ;;
    *:dr_ping_bad)      echo "PC does not answer ping – UpSnap then shows it as off" ;;
    de:dr_ping_hint)    echo "Firewall-Regel FPS-ICMP4-ERQ-In am PC aktivieren (docs/03, 3.2)" ;;
    *:dr_ping_hint)     echo "enable the firewall rule FPS-ICMP4-ERQ-In on the PC (docs/03, 3.2)" ;;
    de:dr_ssh_ok)       echo "Anmeldung mit Schlüssel klappt" ;;
    *:dr_ssh_ok)        echo "key login works" ;;
    de:dr_ssh_hint)     echo "„Permission denied“ = Schlüssel; „timed out/refused“ = Dienst sshd am PC läuft nicht (docs/03)" ;;
    *:dr_ssh_hint)      echo "\"Permission denied\" = key; \"timed out/refused\" = sshd service not running on the PC (docs/03)" ;;
    de:dr_win)          echo "Windows-Teil" ;;
    *:dr_win)           echo "Windows part" ;;
    de:dr_win_missing)  printf "fehlt:" ;;
    *:dr_win_missing)   printf "missing:" ;;
    de:dr_win_hint)     echo "am PC im Admin-Terminal windows\\setup.ps1 ausführen" ;;
    *:dr_win_hint)      echo "run windows\\setup.ps1 in an admin terminal on the PC" ;;
    de:dr_sleep)        echo "Auto-Standby" ;;
    *:dr_sleep)         echo "Auto sleep" ;;
    de:dr_sleep_on)     printf "an – zuletzt: " ;;
    *:dr_sleep_on)      printf "on – last: " ;;
    de:dr_sleep_never)  echo "noch nie eingeschlafen" ;;
    *:dr_sleep_never)   echo "never slept yet" ;;
    de:dr_sleep_off)    echo "aus" ;;
    *:dr_sleep_off)     echo "off" ;;
    de:dr_apollo_ok)    echo "Stream-Port 47989 antwortet" ;;
    *:dr_apollo_ok)     echo "stream port 47989 answers" ;;
    de:dr_apollo_bad)   echo "Stream-Port 47989 antwortet nicht – Spielen geht nicht" ;;
    *:dr_apollo_bad)    echo "stream port 47989 does not answer – Play won't work" ;;
    de:dr_apollo_hint)  echo "läuft der Apollo-Dienst am PC? (docs/05)" ;;
    *:dr_apollo_hint)   echo "is the Apollo service running on the PC? (docs/05)" ;;
    de:dr_apps)         echo "Mac-Apps" ;;
    *:dr_apps)          echo "Mac apps" ;;
    de:dr_apps_missing) printf "fehlt:" ;;
    *:dr_apps_missing)  printf "missing:" ;;
    de:dr_apps_hint)    echo "Moonlight: moonlight-stream.org · Windows App: App Store (docs/04)" ;;
    *:dr_apps_hint)     echo "Moonlight: moonlight-stream.org · Windows App: App Store (docs/04)" ;;
    de:dr_widget_none)  echo "nicht installiert (optional)" ;;
    *:dr_widget_none)   echo "not installed (optional)" ;;
    de:dr_widget_ok)    echo "Hintergrund-App läuft" ;;
    *:dr_widget_ok)     echo "background app running" ;;
    de:dr_widget_bad)   echo "Hintergrund-App läuft nicht – Widget zeigt alten Stand" ;;
    *:dr_widget_bad)    echo "background app not running – the widget shows an old state" ;;
    de:dr_widget_hint)  echo "open \"$HOME/Applications/Wake and Stream.app\"" ;;
    *:dr_widget_hint)   echo "open \"$HOME/Applications/Wake and Stream.app\"" ;;
    de:dr_all_ok)       echo "Alles in Ordnung." ;;
    *:dr_all_ok)        echo "All good." ;;
    de:dr_problems)     echo "$2 Problem(e) gefunden – siehe → oben." ;;
    *:dr_problems)      echo "$2 problem(s) found – see → above." ;;
    # PlayStation 5 (pc ps5 …)
    de:ps5_no_config)   echo "Keine PS5 eingerichtet – PS5_IP in $WAS_CONFIG eintragen (docs/12-ps5.md)." ;;
    *:ps5_no_config)    echo "No PS5 set up – add PS5_IP to $WAS_CONFIG (docs/12-ps5.md)." ;;
    de:ps5_is_on)       echo "PS5 ist an." ;;
    *:ps5_is_on)        echo "PS5 is on." ;;
    de:ps5_is_standby)  echo "PS5 ist im Ruhemodus." ;;
    *:ps5_is_standby)   echo "PS5 is in rest mode." ;;
    de:ps5_is_off)      echo "PS5 antwortet nicht (ganz aus, oder im Ruhemodus ohne Netzwerk)." ;;
    *:ps5_is_off)       echo "PS5 does not answer (switched off, or rest mode without network)." ;;
    de:ps5_waking)      echo "PS5 wird geweckt …" ;;
    *:ps5_waking)       echo "Waking the PS5 …" ;;
    de:ps5_waiting)     printf "Warte auf PS5" ;;
    *:ps5_waiting)      printf "Waiting for PS5" ;;
    de:ps5_timeout)     echo "PS5 nach 1 Minute nicht wach – ganz aus? Ruhemodus-Einstellungen prüfen (docs/12-ps5.md)." ;;
    *:ps5_timeout)      echo "PS5 not awake after 1 minute – switched off? Check the rest mode settings (docs/12-ps5.md)." ;;
    de:ps5_ready)       echo "PS5 ist bereit." ;;
    *:ps5_ready)        echo "PS5 is ready." ;;
    de:ps5_already_on)  echo "PS5 läuft schon." ;;
    *:ps5_already_on)   echo "PS5 is already on." ;;
    de:ps5_no_key)      echo "Kein Remote-Play-Schlüssel gefunden – PS5 zuerst einmal zu Hause in $PS5_APP koppeln (docs/12-ps5.md)." ;;
    *:ps5_no_key)       echo "No Remote Play key found – pair the PS5 in $PS5_APP once at home first (docs/12-ps5.md)." ;;
    de:ps5_no_name)     echo "Name der gekoppelten PS5 unbekannt – PS5_NAME in $WAS_CONFIG eintragen (wie in $PS5_APP angezeigt)." ;;
    *:ps5_no_name)      echo "Name of the paired PS5 unknown – add PS5_NAME to $WAS_CONFIG (as shown in $PS5_APP)." ;;
    de:ps5_play_start)  echo "$PS5_APP startet den Stream." ;;
    *:ps5_play_start)   echo "$PS5_APP starts the stream." ;;
    de:ps5_stopped)     echo "PS5-Stream beendet (Ruhemodus je nach „Action On Disconnect“ in $PS5_APP)." ;;
    *:ps5_stopped)      echo "PS5 stream ended (rest mode depends on \"Action On Disconnect\" in $PS5_APP)." ;;
    de:ps5_still_open)  echo "$PS5_APP ist noch offen – fragt vermutlich nach dem Ruhemodus, bitte im Fenster antworten." ;;
    *:ps5_still_open)   echo "$PS5_APP is still open – probably asking about rest mode, answer in its window." ;;
    de:dr_ps5)          echo "PS5" ;;
    *:dr_ps5)           echo "PS5" ;;
    de:dr_ps5_on)       echo "an ($PS5_IP antwortet)" ;;
    *:dr_ps5_on)        echo "on ($PS5_IP answers)" ;;
    de:dr_ps5_standby)  echo "Ruhemodus, kann geweckt werden" ;;
    *:dr_ps5_standby)   echo "rest mode, can be woken" ;;
    de:dr_ps5_off)      echo "$PS5_IP antwortet nicht" ;;
    *:dr_ps5_off)       echo "$PS5_IP does not answer" ;;
    de:dr_ps5_off_hint) echo "ganz aus? IP richtig? Ruhemodus: „Mit dem Internet verbunden bleiben“ + „Einschalten über Netzwerk“ an (docs/12-ps5.md)" ;;
    *:dr_ps5_off_hint)  echo "switched off? IP correct? Rest mode: \"Stay connected to the internet\" + \"Enable turning on PS5 from network\" (docs/12-ps5.md)" ;;
    de:dr_ps5_pair)     echo "PS5-Kopplung" ;;
    *:dr_ps5_pair)      echo "PS5 pairing" ;;
    de:dr_ps5_pair_ok)  echo "Schlüssel gefunden, Konsole „$2“" ;;
    *:dr_ps5_pair_ok)   echo "key found, console \"$2\"" ;;
    de:dr_ps5_pair_bad) echo "kein Remote-Play-Schlüssel (oder kein Name) gefunden" ;;
    *:dr_ps5_pair_bad)  echo "no Remote Play key (or no name) found" ;;
    de:dr_ps5_pair_hint) echo "$PS5_APP öffnen, PS5 zu Hause einmal koppeln (docs/12-ps5.md)" ;;
    *:dr_ps5_pair_hint)  echo "open $PS5_APP and pair the PS5 once at home (docs/12-ps5.md)" ;;
    de:dr_ps5_app_hint) echo "$PS5_APP installieren: github.com/chiaki-ng/chiaki-ng/releases" ;;
    *:dr_ps5_app_hint)  echo "install $PS5_APP: github.com/chiaki-ng/chiaki-ng/releases" ;;
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
#   S_PS5    none (no PS5_IP) / on / standby / off;  S_PS5PLAY 1 = chiaki-ng is open on this Mac
# (Apollo/Sunshine only report the stream state to paired clients, so we track it on the Mac.)
was_state() {
  S_HOME=0; S_ON=0; S_STREAM=0; S_RDP=0; S_LAST=""; S_PS5=none; S_PS5PLAY=0
  [ -z "$PS5_IP" ] || S_PS5=off
  home_reachable || return 0
  S_HOME=1
  if [ -n "$PS5_IP" ]; then
    S_PS5=$(ps5_state)
    pgrep -x "$PS5_APP" >/dev/null && S_PS5PLAY=1
  fi
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

# ---------- PlayStation 5 (optional, needs chiaki-ng) ----------
# The PS5 answers a small UDP "search" on port 9302 – also in rest mode, if it stays connected –
# and wakes up from a "WAKEUP" packet with the Remote Play key that chiaki-ng got when pairing.
# Same protocol as chiaki-ng (lib/src/discovery.c). Unicast UDP, so it also works through Tailscale/VPN.

# ps5_state → on / standby / off (off = no answer: switched off, no network in rest mode, wrong IP)
ps5_state() {
  local r
  r=$(printf 'SRCH * HTTP/1.1\ndevice-discovery-protocol-version:00030010\n' |
      nc -u -w 1 "$PS5_IP" "$PS5_PORT" 2>/dev/null | head -n 1)
  case "$r" in *" 200 "*) echo on;; *" 620 "*) echo standby;; *) echo off;; esac
}

# ps5_chiaki_value <key> – first value of <key> in chiaki-ng's settings (Qt stores them in a plist,
# keys like registered_hosts/1/rp_regist_key). Byte values come as <data> (base64), text as <string>.
ps5_chiaki_value() {
  local f v
  for f in "$PS5_CHIAKI_PLIST" "$HOME"/Library/Preferences/com.chiaki*.plist; do
    [ -f "$f" ] || continue
    v=$(plutil -convert xml1 -o - "$f" 2>/dev/null | awk -v k="$1" '
          found { buf = buf $0; if ($0 ~ /<\/(data|string)>/) { print buf; exit } next }
          $0 ~ "<key>([^<]*[./])?" k "</key>" { found = 1 }')
    case "$v" in
      *"<data>"*)   v=$(printf '%s' "$v" | sed -e 's/<[^>]*>//g' -e 's/[[:space:]]//g' | base64 -D 2>/dev/null | tr -d '\000') ;;
      *"<string>"*) v=$(printf '%s' "$v" | sed -e 's/.*<string>//' -e 's/<\/string>.*//' -e 's/^@ByteArray(\(.*\))$/\1/') ;;
      *) v="" ;;
    esac
    [ -n "$v" ] && { printf '%s\n' "$v"; return 0; }
  done
  return 1
}

# Remote Play key (8 hex digits): from the config, else from chiaki-ng's pairing. Returns 1 if none.
ps5_key() {
  local k="${PS5_REGISTKEY:-$(ps5_chiaki_value rp_regist_key)}"
  printf '%s' "$k" | grep -q -E '^[0-9a-fA-F]{1,16}$' || return 1
  printf '%s\n' "$k"
}
# Name of the paired console in chiaki-ng (needed to start a stream)
ps5_name() { printf '%s\n' "${PS5_NAME:-$(ps5_chiaki_value server_nickname)}"; }

# Send the wake packet. Returns 1 without a key.
ps5_wake() {
  local key cred
  key=$(ps5_key) || return 1
  cred=$(printf '%u' "0x$key")
  printf 'WAKEUP * HTTP/1.1\nclient-type:vr\nauth-type:R\nmodel:w\napp-type:r\nuser-credential:%s\ndevice-discovery-protocol-version:00030010\n' "$cred" |
    nc -u -w 1 "$PS5_IP" "$PS5_PORT" >/dev/null 2>&1
  return 0
}
