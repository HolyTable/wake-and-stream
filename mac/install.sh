#!/bin/bash
# wake-and-stream – Mac installer
# Run from the repository:  bash mac/install.sh
#
# What it does (asks before each step that needs your password):
#   1. ~/.config/wake-and-stream/        lib.sh, icons, config (created from your answers, kept on updates)
#   2. /usr/local/bin/pc                 the "pc" command (needs sudo)
#   3. SwiftBar plugin folder            menu bar plugin (if SwiftBar is installed)
#   4. macOS keychain                    UpSnap login (optional)
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/wake-and-stream"

ask() {  # ask <question> <default> → answer
  local a; read -r -p "$1 [$2]: " a; echo "${a:-$2}"
}

echo "== wake-and-stream installer =="
mkdir -p "$DEST/icons"

# 1. shared files + icons
cp "$HERE/lib.sh" "$DEST/lib.sh"
cp "$HERE"/icons/*.icns "$HERE"/icons/menubar-*.png "$DEST/icons/"
echo "✓ lib.sh and icons → $DEST"

# config: create once from your answers, never overwrite
if [ -f "$DEST/config" ]; then
  echo "✓ keeping existing config ($DEST/config)"
else
  echo
  echo "Configuration (press Enter to keep the value in brackets):"
  lang=$(ask "Language (en/de)" en)
  pc_ip=$(ask "IP of your Windows PC" 192.168.1.50)
  pc_user=$(ask "Windows user name for SSH" your-windows-user)
  router=$(ask "IP of your router" 192.168.1.1)
  upsnap=$(ask "UpSnap URL" "http://192.168.1.10:8090")
  sed -e "s|^LANGUAGE=.*|LANGUAGE=$lang|" \
      -e "s|^PC_IP=.*|PC_IP=$pc_ip|" \
      -e "s|^PC_USER=.*|PC_USER=$pc_user|" \
      -e "s|^ROUTER_IP=.*|ROUTER_IP=$router|" \
      -e "s|^UPSNAP_URL=.*|UPSNAP_URL=$upsnap|" \
      -e "s|^APOLLO_URL=.*|APOLLO_URL=https://$pc_ip:47990|" \
      "$HERE/config.example" > "$DEST/config"
  echo "✓ config written → $DEST/config (edit it any time)"
fi

# 2. pc command
echo
echo "Installing the pc command to /usr/local/bin (your Mac password may be asked):"
sudo mkdir -p /usr/local/bin
sudo install -m 755 "$HERE/pc" /usr/local/bin/pc
echo "✓ /usr/local/bin/pc"

# 3. SwiftBar plugin
plugdir=$(defaults read com.ameba.SwiftBar PluginDirectory 2>/dev/null || true)
if [ -d "/Applications/SwiftBar.app" ] || [ -n "$plugdir" ]; then
  plugdir=$(ask "SwiftBar plugin folder" "${plugdir:-$HOME/SwiftBar}")
  plugdir="${plugdir/#\~/$HOME}"
  mkdir -p "$plugdir"
  install -m 755 "$HERE/wake-and-stream.10s.sh" "$plugdir/"
  echo "✓ menu bar plugin → $plugdir"
else
  echo "• SwiftBar not found – skipping the menu bar plugin (install SwiftBar and run this again)."
fi

# 4. UpSnap login in the keychain
echo
case "$(ask "Store your UpSnap login in the keychain now? (y/n)" y)" in [yYjJ]*)
  # shellcheck source=/dev/null
  . "$DEST/config"
  user=$(ask "UpSnap user name / e-mail" "")
  if [ -n "$user" ]; then
    security delete-generic-password -s "$KEYCHAIN_SERVICE" >/dev/null 2>&1 || true
    echo "Type your UpSnap password twice (it is not shown):"
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$user" -w
    echo "✓ UpSnap login stored in the keychain ($KEYCHAIN_SERVICE)"
  fi ;;
esac

echo
echo "Done. Try:  pc status"
