# 4 – Mac

## 4.1 VPN into your home network

Any VPN that gives the Mac an address **inside** your home network works. Example FRITZ!Box:

1. *Internet → Permit Access → VPN (WireGuard)* → add a connection → *Connect a single device* → name it
   e.g. "MacBook".
2. Import the shown configuration into the **WireGuard** app on the Mac (scan/import the file, then
   **delete the downloaded file** – it contains your private key).
3. A *full tunnel* (`AllowedIPs = …, 0.0.0.0/0, ::/0`) is fine: all traffic goes through your home,
   so you also have your home DNS/ad blocker on the road.

**Test:** VPN on → `ping 192.168.1.1` answers.

## 4.2 Apps

- **[Windows App](https://apps.apple.com/app/windows-app/id1295203466)** (formerly Microsoft Remote
  Desktop) – add the PC: *PC name* = its IP, *Credentials* = your Windows user + password, *Friendly
  name* = e.g. `Desktop`. Under *Devices & Audio* enable **Microphone** if you need it (see
  [chapter 7](07-remote-desktop-extras.md#microphone)). On the first connection: *Show Certificate* →
  **Always trust**.
- **[Moonlight](https://moonlight-stream.org)** – pair with Apollo ([chapter 5](05-apollo.md)).
- **[SwiftBar](https://github.com/swiftbar/SwiftBar)** – shows the menu bar icon. Not needed if you
  only use the [widget](10-widget.md) (macOS 14+, Command Line Tools: `xcode-select --install`).

## 4.3 Install wake-and-stream

```bash
git clone https://github.com/<you>/wake-and-stream.git ~/wake-and-stream   # or copy the folder
bash ~/wake-and-stream/mac/install.sh
```

The installer asks for: language (`en`/`de`), PC IP, Windows user, router IP, UpSnap URL, the SwiftBar
plugin folder, – optionally – your UpSnap login for the keychain and whether to install the widget.
It installs:

| What | Where |
|---|---|
| settings, texts, icons | `~/.config/wake-and-stream/` (`config` = your values, kept on updates) |
| `pc` command | `/usr/local/bin/pc` (needs your Mac password once) |
| menu bar plugin | your SwiftBar plugin folder |
| `action.sh` (what a click does: confirm, run, notify) | `~/.config/wake-and-stream/` |
| widget + background app (optional) | `~/Applications/Wake and Stream.app` – see [chapter 10](10-widget.md) |

Change settings any time in `~/.config/wake-and-stream/config` (see
[`mac/config.example`](../mac/config.example)).

**Update later:** pull/copy the new version and run `install.sh` again – your config stays.

## 4.4 Recommended Moonlight settings (Mac)

| Setting | Value |
|---|---|
| Resolution | **Native (excluding notch)** – or custom, e.g. 3024×1890 on a 14" MacBook Pro |
| FPS | 120 (MacBook Pro display) |
| Display mode | **Borderless window** (Moonlight's own full screen) |
| Optimize mouse for remote desktop | ✅ – mouse feels like on the Mac |
| Capture system keyboard shortcuts | *in full screen* – then ⌘ acts as the Windows key |
| Optimize game settings | ❌ – otherwise Moonlight changes game settings on the PC |
| Quit app on host after stream ends | ❌ – so you can pause and resume |
| HDR | as you like – turn off if the picture looks washed out |

Moonlight's full screen **hides the Mac menu bar**. To end the stream, swipe with **three fingers** to
another desktop (or press **control+option+shift+Q** to close the window) and choose *End play
session* in the menu.

> macOS may show a 🚀 *Game Mode* icon while streaming. It's useful (lower Bluetooth latency, priority
> for Moonlight); click it → *Turn Game Mode Off* if you don't want it.

## Test (at home)

`pc status` → "PC is on." · menu bar → *Work* → *End work session* · *Play* → *End play session* ·
*Power → Shut down* · *Turn on*.
