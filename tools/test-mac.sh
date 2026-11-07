#!/bin/bash
# test-mac.sh – tests the Mac scripts (pc, menu bar plugin, lib.sh) without a Mac and without a PC.
# All macOS/network commands are replaced by small fakes ("mocks") that log what would happen.
#
#   bash tools/test-mac.sh
#
# Scenario switches (set per test): HOME_UP, PC_ON, ML_RUNNING (Moonlight open), RDP_UP,
# DIALOG (0 = user confirms, 1 = cancels), UPSNAP_OK, KEYCHAIN_OK
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
export MOCKLOG="$T/calls.log" MOCKSTATE="$T/state"
mkdir -p "$T/bin" "$T/home/.config/wake-and-stream/icons" "$T/home/SwiftBar" "$MOCKSTATE"

# ---------- fake commands ----------
mk() { printf '#!/bin/bash\n%s\n' "$2" > "$T/bin/$1"; chmod +x "$T/bin/$1"; }
mk ping      'echo "ping $*" >> "$MOCKLOG"; [ "${HOME_UP:-1}" = 1 ]'
mk nc        'echo "nc $*" >> "$MOCKLOG"; [ "${PC_ON:-1}" = 1 ]'
mk pgrep     '[ -f "$MOCKSTATE/moonlight" ] || [ "${ML_RUNNING:-0}" = 1 ]'
mk pkill     'echo "pkill $*" >> "$MOCKLOG"; case "$*" in *Moonlight*) rm -f "$MOCKSTATE/moonlight"; export ML_RUNNING=0;; esac; exit 0'
mk open      'echo "open $*" >> "$MOCKLOG"; case "$*" in *"Moonlight --args stream"*) touch "$MOCKSTATE/moonlight";; esac; exit 0'
mk osascript 'echo "osascript $*" >> "$MOCKLOG"; case "$*" in *"display dialog"*) exit "${DIALOG:-0}";; esac; exit 0'
mk security  'echo "security $*" >> "$MOCKLOG"; [ "${KEYCHAIN_OK:-1}" = 1 ] || exit 44
              case "$*" in *" -w"*) echo "s3cr\"et";; *) echo "    \"acct\"<blob>=\"user@example.com\"";; esac'
mk curl      'echo "curl $*" >> "$MOCKLOG"; data=$(cat 2>/dev/null </dev/stdin & sleep 0.1; kill $! 2>/dev/null);
              case "$*" in
                *auth-with-password*) [ "${UPSNAP_OK:-1}" = 1 ] && echo "{\"record\":{},\"token\":\"TOKEN123\"}" || echo "{\"message\":\"Failed to authenticate.\"}";;
                *devices/records*) echo "{\"items\":[{\"collectionId\":\"x\",\"id\":\"DEV42\",\"ip\":\"192.168.1.50\"}]}";;
                *upsnap/wake*) echo "wake-called" >> "$MOCKLOG";;
              esac'
mk ssh       'echo "ssh $*" >> "$MOCKLOG"; [ "${SSH_OK:-1}" = 1 ] || { echo "ssh: connect to host port 22: Operation timed out" >&2; exit 255; }'
mk netstat   '[ "${RDP_UP:-0}" = 1 ] && echo "tcp4 0 0 192.168.1.203.50000 192.168.1.50.3389 ESTABLISHED"; echo "tcp4 0 0 192.168.1.203.50001 192.168.1.150.3389 ESTABLISHED"; exit 0'
mk base64    'echo "BASE64DATA"'
mk sleep     'exit 0'
mk nohup     '"$@"'

# ---------- install files like install.sh would ----------
cp "$REPO/mac/lib.sh" "$T/home/.config/wake-and-stream/"
cp "$REPO"/mac/icons/*.icns "$REPO"/mac/icons/menubar-*.png "$T/home/.config/wake-and-stream/icons/"
sed -e 's|^ROUTER_IP=.*|ROUTER_IP=192.168.1.1|' "$REPO/mac/config.example" > "$T/home/.config/wake-and-stream/config"
cp "$REPO/mac/pc" "$T/bin/pc"; chmod +x "$T/bin/pc"
PLUGIN="$T/home/SwiftBar/wake-and-stream.10s.sh"
cp "$REPO/mac/wake-and-stream.10s.sh" "$PLUGIN"; chmod +x "$PLUGIN"
CFG="$T/home/.config/wake-and-stream"

run() {  # run <command...> with fakes first in PATH, captures output in $OUT
  : > "$MOCKLOG"
  OUT=$(HOME="$T/home" PATH="$T/bin:$PATH" SWIFTBAR_PLUGIN_PATH="$PLUGIN" "$@" 2>&1)
}
reset_state() { rm -f "$CFG/stream-active" "$CFG/last-state" "$MOCKSTATE/moonlight"; }
ok()   { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ✗ $1"; echo "$OUT" | sed 's/^/      | /' | head -20; echo "      log:"; sed 's/^/      | /' "$MOCKLOG" | head -20; }
has()  { echo "$OUT" | grep -q -- "$1"; }
logged(){ grep -q -- "$1" "$MOCKLOG"; }

echo "== pc command =="
reset_state
run bash "$T/bin/pc" status;               has "PC is on." && ok "status: on" || bad "status: on"
PC_ON=0 run bash "$T/bin/pc" status;        has "PC is off" && ok "status: off" || bad "status: off"
run bash "$T/bin/pc";                       has "pc play" && ok "help (en)" || bad "help (en)"
HOME_UP=0 run bash "$T/bin/pc" on;          has "Home network not reachable" && ok "on: no VPN → message" || bad "on: no VPN"
run bash "$T/bin/pc" on;                    has "already on" && ok "on: already on" || bad "on: already on"

# PC off → wake via UpSnap API; PC comes up on the 2nd port check
cat > "$T/bin/nc" <<'EOF'
#!/bin/bash
echo "nc $*" >> "$MOCKLOG"; n=$(cat "$MOCKSTATE/nccount" 2>/dev/null || echo 0); n=$((n+1)); echo $n > "$MOCKSTATE/nccount"
[ "${PC_ON:-1}" = 1 ] || [ $n -ge 3 ]
EOF
chmod +x "$T/bin/nc"
rm -f "$MOCKSTATE/nccount"; PC_ON=0 run bash "$T/bin/pc" on
has "Turning the PC on" && logged "upsnap/wake/DEV42" && has "PC is ready" && ! logged "open http" \
  && ok "on: wakes via UpSnap API (token + device id), no browser" || bad "on: UpSnap API wake"
grep -q 's3cr\\"et' "$MOCKLOG" && bad "on: password must not appear in command arguments" || ok "on: password not passed as argument"
rm -f "$MOCKSTATE/nccount"; PC_ON=0 UPSNAP_OK=0 run bash "$T/bin/pc" on
has "Could not wake the PC directly" && logged "open http://192.168.1.10:8090" && ok "on: wrong login → falls back to UpSnap page" || bad "on: fallback"
rm -f "$MOCKSTATE/nccount"; PC_ON=0 KEYCHAIN_OK=0 run bash "$T/bin/pc" on
has "Could not wake the PC directly" && ! logged "curl" && ok "on: no keychain entry → fallback, no API call" || bad "on: no keychain"
printf '#!/bin/bash\necho "nc $*" >> "$MOCKLOG"; [ "${PC_ON:-1}" = 1 ]\n' > "$T/bin/nc"

reset_state; run bash "$T/bin/pc" play
logged "open -a Moonlight --args stream 192.168.1.50 Desktop" && [ -f "$CFG/stream-active" ] && has "Starting Moonlight" \
  && ok "play: starts Moonlight stream + remembers stream" || bad "play"
ML_RUNNING=1 run bash "$T/bin/pc" play
logged "pkill -x Moonlight" && ok "play: closes an already open Moonlight first (one instance)" || bad "play: single instance"
grep -q "^osascript *$" "$MOCKLOG" && ok "play: switches the stream window to full screen (PLAY_FULLSCREEN=yes)" || bad "play: fullscreen helper"
sed -i 's/^PLAY_FULLSCREEN=.*/PLAY_FULLSCREEN=no/' "$CFG/config"; reset_state; run bash "$T/bin/pc" play
! grep -q "^osascript *$" "$MOCKLOG" && ok "play: no full screen with PLAY_FULLSCREEN=no" || bad "play: fullscreen off"
sed -i 's/^PLAY_FULLSCREEN=.*/PLAY_FULLSCREEN=yes/' "$CFG/config"
run bash "$T/bin/pc" stop
logged "open -a Moonlight --args quit 192.168.1.50" && [ ! -f "$CFG/stream-active" ] && ok "stop: quits app on PC + forgets stream" || bad "stop"
run bash "$T/bin/pc" release
first=$(grep -n -m1 'pkill -x Windows App' "$MOCKLOG" | cut -d: -f1); second=$(grep -n -m1 'release-session.bat' "$MOCKLOG" | cut -d: -f1)
[ -n "$first" ] && [ -n "$second" ] && [ "$first" -lt "$second" ] \
  && logged 'your-windows-user@192.168.1.50 C:\\ProgramData\\WakeAndStream\\release-session.bat' \
  && ok "release: first closes Windows App, then runs release-session.bat via SSH" || bad "release"
touch "$CFG/stream-active"; run bash "$T/bin/pc" off
logged "shutdown /s /t 0" && [ ! -f "$CFG/stream-active" ] && ok "off: shuts down + forgets stream" || bad "off"
grep -q "BatchMode=yes" "$MOCKLOG" && grep -q "ConnectTimeout=5" "$MOCKLOG" && ok "ssh: key only + 5 s timeout (no hanging password prompt)" || bad "ssh options"
touch "$CFG/stream-active"; SSH_OK=0 run bash "$T/bin/pc" off
[ -f "$CFG/stream-active" ] && ! has "shutting down" && ok "off: PC unreachable → error shown, stream not forgotten" || bad "off: ssh failure"
rm -f "$CFG/stream-active"
SSH_OK=0 run bash "$T/bin/pc" release; has "timed out" && ok "release: PC unreachable → error shown" || bad "release: ssh failure"
run bash "$T/bin/pc" sleep;                 logged "SetSuspendState" && ok "sleep" || bad "sleep"
run bash "$T/bin/pc" aus;                   logged "shutdown /s" && ok "German alias: aus" || bad "alias aus"
sed -i 's/^LANGUAGE=.*/LANGUAGE=de/' "$CFG/config"
run bash "$T/bin/pc" status;                has "PC ist an." && ok "German texts" || bad "German texts"
run bash "$T/bin/pc";                       has "pc spielen" && ok "help (de)" || bad "help (de)"
sed -i 's/^LANGUAGE=.*/LANGUAGE=en/' "$CFG/config"

echo "== menu bar plugin: display =="
reset_state
HOME_UP=0 run bash "$PLUGIN";  has "exclamationmark.triangle" && has "Open VPN" && ok "no home network → ⚠ + Open VPN" || bad "no VPN view"
run bash "$PLUGIN"
has "image=BASE64DATA" && has "^Work |" && has "^Play |" && has "^--Shut down" && ! has "End" && ok "PC on, idle → Work / Play / Power" || bad "on idle"
RDP_UP=1 run bash "$PLUGIN";   has "^End work session |" && ok "RDP connected → End work session" || bad "rdp view"
touch "$CFG/stream-active"
ML_RUNNING=1 run bash "$PLUGIN"; has "^End play session |" && ! has "^Resume playing" && ok "streaming (Moonlight open) → End play session" || bad "streaming view"
run bash "$PLUGIN";            has "^Resume playing |" && has "^End play session |" && ok "paused (Moonlight closed) → Resume + End" || bad "paused view"
PC_ON=0 run bash "$PLUGIN";    has "^Turn on |" && [ ! -f "$CFG/stream-active" ] && ok "PC off → Turn on, stream flag cleared" || bad "off view"
echo sleep > "$CFG/last-state"
PC_ON=0 run bash "$PLUGIN";    has "^Wake up |" && ok "after Sleep via menu → Wake up" || bad "sleep view"
run bash "$PLUGIN";            [ ! -f "$CFG/last-state" ] && ok "PC on again → sleep memory cleared" || bad "sleep memory"
has "--UpSnap | href=http://192.168.1.10:8090" && has "--Apollo | href=https://192.168.1.50:47990" && ok "More → UpSnap/Apollo links" || bad "links"

echo "== menu bar plugin: actions =="
reset_state
DIALOG=1 run bash "$PLUGIN" off; ! logged "ssh" && ok "Shut down → Cancel → nothing happens" || bad "cancel off"
DIALOG=0 run bash "$PLUGIN" off; logged "shutdown /s" && [ "$(cat "$CFG/last-state")" = off ] && ok "Shut down → confirm → shuts down, remembers 'off'" || bad "confirm off"
rm -f "$CFG/last-state"; DIALOG=0 SSH_OK=0 run bash "$PLUGIN" off
[ ! -f "$CFG/last-state" ] && grep -q "timed out" "$MOCKLOG" && ok "Shut down fails → error notification, 'off' not remembered" || bad "off failure in menu"
DIALOG=0 run bash "$PLUGIN" sleep; [ "$(cat "$CFG/last-state")" = sleep ] && ok "Sleep → confirm → remembers 'sleep'" || bad "confirm sleep"
grep -q 'power-off.icns' "$MOCKLOG" || grep -q 'sleep.icns' "$MOCKLOG" && ok "dialog uses own icons" || bad "dialog icons"
PC_ON=0 DIALOG=1 run bash "$PLUGIN" on; ! logged "curl" && ! logged "open http" && ok "Turn on (PC off) → Cancel → nothing happens" || bad "cancel on"
DIALOG=1 run bash "$PLUGIN" play; logged "Moonlight --args stream" && ok "Play with PC already on → no question" || bad "play no confirm"
run bash "$PLUGIN" stop;        logged "--args quit" && ok "End play session → pc stop" || bad "stop action"

echo "== install.sh =="
I="$T/inst"; mkdir -p "$I/home" "$I/bin"
cp -r "$T/bin/." "$I/bin/"
printf '#!/bin/bash
echo "sudo $*" >> "$MOCKLOG"
' > "$I/bin/sudo"; chmod +x "$I/bin/sudo"
printf '#!/bin/bash
[ "$2" = com.ameba.SwiftBar ] && echo "$HOME/SwiftBar" || exit 1
' > "$I/bin/defaults"; chmod +x "$I/bin/defaults"
: > "$MOCKLOG"
OUT=$(printf 'de
192.168.1.77
meinuser
192.168.1.254
http://192.168.1.9:8090

j
me@example.com
' |
      HOME="$I/home" PATH="$I/bin:$PATH" bash "$REPO/mac/install.sh" 2>&1)
C="$I/home/.config/wake-and-stream"
grep -q '^LANGUAGE=de$' "$C/config" && grep -q '^PC_IP=192.168.1.77$' "$C/config" && grep -q '^PC_USER=meinuser$' "$C/config"   && grep -q '^ROUTER_IP=192.168.1.254$' "$C/config" && grep -q '^UPSNAP_URL=http://192.168.1.9:8090$' "$C/config"   && grep -q '^APOLLO_URL=https://192.168.1.77:47990$' "$C/config" && ok "install: config written from the answers" || bad "install: config"
[ -f "$C/lib.sh" ] && [ -f "$C/icons/power-on.icns" ] && [ -f "$C/icons/menubar-sleep.png" ] && ok "install: lib.sh + icons copied" || bad "install: files"
grep -q "sudo install -m 755 .*/pc /usr/local/bin/pc" "$MOCKLOG" && ok "install: pc command via sudo" || bad "install: pc"
[ -x "$I/home/SwiftBar/wake-and-stream.10s.sh" ] && ok "install: plugin copied to SwiftBar folder (executable)" || bad "install: plugin"
grep -q "security add-generic-password -s wake-and-stream-upsnap -a me@example.com -w" "$MOCKLOG" && ok "install: 'j' accepted, keychain entry created" || bad "install: keychain"
echo "PC_IP=192.168.1.99 # mine" >> "$C/config"
OUT=$(printf '
n
' | HOME="$I/home" PATH="$I/bin:$PATH" bash "$REPO/mac/install.sh" 2>&1)
grep -q "192.168.1.99 # mine" "$C/config" && echo "$OUT" | grep -q "keeping existing config" && ok "install: second run keeps your config" || bad "install: keep config"

echo
echo "Result: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
