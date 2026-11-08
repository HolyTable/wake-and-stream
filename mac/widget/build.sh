#!/bin/bash
# wake-and-stream – builds the widget app without Xcode (the Command Line Tools are enough):
#   bash mac/widget/build.sh [output folder]      (default: ~/Applications)
#   bash mac/widget/build.sh --preview <folder>   only render the widget in all states as PNG files
#
# Result: "Wake and Stream.app" = an invisible background app + the widget inside it
# (Contents/PlugIns/WakeAndStreamWidget.appex). It is signed "ad hoc" (only for this Mac),
# no Apple developer account needed. Needs macOS 14 or newer.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
if [ "$1" = --preview ]; then
  OUT="${2:-.}"; mkdir -p "$OUT"; P="$(mktemp -d)"
  swiftc -parse-as-library -target "$(uname -m)-apple-macos14.0" -sdk "$(xcrun --show-sdk-path)" \
    -module-name WakeAndStreamWidget \
    "$HERE/Shared.swift" "$HERE/Widget.swift" "$HERE/preview.swift" -o "$P/preview"
  "$P/preview" "$OUT"; rm -rf "$P"; exit 0
fi
OUT="${1:-$HOME/Applications}"
APP="$OUT/Wake and Stream.app"
EXT="$APP/Contents/PlugIns/WakeAndStreamWidget.appex"
TARGET="$(uname -m)-apple-macos14.0"
SDK="$(xcrun --show-sdk-path)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

command -v swiftc >/dev/null || { echo "swiftc not found – install the Command Line Tools: xcode-select --install"; exit 1; }

echo "Building the widget app …"
swiftc -O -parse-as-library -target "$TARGET" -sdk "$SDK" -module-name WakeAndStream \
  "$HERE/Shared.swift" "$HERE/App.swift" -o "$TMP/WakeAndStream"
swiftc -O -parse-as-library -application-extension -target "$TARGET" -sdk "$SDK" -module-name WakeAndStreamWidget \
  -Xlinker -e -Xlinker _NSExtensionMain \
  "$HERE/Shared.swift" "$HERE/Widget.swift" "$HERE/WidgetMain.swift" -o "$TMP/WakeAndStreamWidget"

# Metadata.appintents: describes the button intent for macOS (normally made by an Xcode-only tool).
# The Swift type name comes from a small helper built with the same module name.
swiftc -parse-as-library -target "$TARGET" -sdk "$SDK" -module-name WakeAndStreamWidget \
  "$HERE/Shared.swift" "$HERE/Widget.swift" "$HERE/preview.swift" -o "$TMP/helper"
MANGLED="$("$TMP/helper" --mangled)"
[ -n "$MANGLED" ] || { echo "could not determine the intent type name"; exit 1; }

# quit a running copy before replacing it
pkill -x WakeAndStream 2>/dev/null && sleep 1 || true
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$EXT/Contents/MacOS"
cp "$TMP/WakeAndStream" "$APP/Contents/MacOS/"
cp "$HERE/App-Info.plist" "$APP/Contents/Info.plist"
cp "$HERE/../icons/power-on.icns" "$APP/Contents/Resources/AppIcon.icns"
cp "$TMP/WakeAndStreamWidget" "$EXT/Contents/MacOS/"
cp "$HERE/Widget-Info.plist" "$EXT/Contents/Info.plist"
mkdir -p "$EXT/Contents/Resources/Metadata.appintents"
sed "s/@MANGLED@/$MANGLED/g" "$HERE/extract.actionsdata.template" > "$EXT/Contents/Resources/Metadata.appintents/extract.actionsdata"
printf '{\n  "toolsVersion" : "27A225b",\n  "version" : "3.0"\n}\n' > "$EXT/Contents/Resources/Metadata.appintents/version.json"

# sign: first the widget (sandbox is required for widgets), then the app around it
codesign --force --sign - --entitlements "$HERE/Widget.entitlements" "$EXT"
codesign --force --sign - "$APP"
echo "✓ $APP"
