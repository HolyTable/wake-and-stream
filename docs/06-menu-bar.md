# 6 – The menu bar icon

The SwiftBar plugin refreshes every 10 seconds and only shows what makes sense right now.
Prefer a widget? See [chapter 10](10-widget.md) – same states, same choices.

| Icon | Meaning | Menu |
|---|---|---|
| green ⏻ | PC is on | *Work* / *End work session* · *Play* / *Resume playing* + *End play session* · *Power ›* (Shut down, Sleep) · *More ›* |
| red ⏻ | PC is off | *Turn on* · *Work* · *Play* (both turn the PC on first) · *More ›* |
| yellow ☾ | PC asleep (put to sleep via the menu) | *Wake up* · *Work* · *Play* · *More ›* |
| ⚠ | home network not reachable | *Open VPN* |

*More ›* links to the UpSnap and Apollo web pages (e.g. to end a stream that was started on the TV).

## How the states are detected

| State | How |
|---|---|
| home network | ping to the router |
| PC on | Remote Desktop port 3389 answers |
| remote desktop connected | this Mac has an open connection to port 3389 |
| stream running / paused | remembered on the Mac when *Play* is used (Apollo/Sunshine only tell **paired** clients) – "running" if Moonlight is open, otherwise "paused" |
| asleep vs. off | look the same from outside → the last choice in the menu is remembered |

## Confirmations

Turning the PC **on** (also via *Work*/*Play* when it's off), **Shut down** and **Sleep** ask first.
*Cancel* is the default button, so an accidental Enter does nothing. Each dialog has its own icon
(`mac/icons/`, regenerate with `python3 mac/icons/generate.py`).

## Settings (`~/.config/wake-and-stream/config`)

| Key | Meaning |
|---|---|
| `LANGUAGE` | `en` or `de` |
| `PC_IP`, `PC_USER`, `ROUTER_IP` | your network |
| `UPSNAP_URL`, `KEYCHAIN_SERVICE` | UpSnap address, keychain entry with its login |
| `APOLLO_URL`, `STREAM_APP` | Apollo web UI, app that *Play* starts |
| `WINDOWS_DIR` | where `setup.ps1` installed the Windows scripts |
| `RDP_APP`, `RDP_PC_NAME` | remote desktop app and the saved PC's name |
| `PLAY_FULLSCREEN` | **experimental**, `no` by default – tries to put Moonlight into macOS full screen via AppleScript; on some setups it leaves an empty black space behind |
