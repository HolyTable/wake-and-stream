# Troubleshooting

Every problem we actually ran into while building this, with the fix.

## Waking & shutting down

| Symptom | Cause | Fix |
|---|---|---|
| PC doesn't wake at all | ErP enabled / fast startup on / pattern-match wake | [chapter 1](01-pc.md) |
| Wake from the router works, from the Mac via VPN not | magic packets don't cross the VPN | wake via UpSnap ([chapter 3](03-remote-control.md)) |
| UpSnap shows the PC as offline although it runs | Windows blocks ping | firewall rule `FPS-ICMP4-ERQ-In` ([3.2](03-remote-control.md#32-allow-ping)) |
| UpSnap shutdown does nothing, SSH log: *preauth close* | NAS forces `rwxrwxrwx` on the key, SSH refuses it | copy the key to `/tmp` + `chmod 600` in the command ([3.3](03-remote-control.md#33-upsnap-on-the-nas)) |
| Can't paste into the container console | many NAS web consoles don't support it | download/upload files with the NAS file manager instead |
| *Turn on* opens UpSnap's web page instead of waking directly | no/incorrect keychain login | test the login ([3.4](03-remote-control.md#34-login-for-the-mac)); if you stored a wrong user, `security delete-generic-password -s wake-and-stream-upsnap` (repeat until "could not be found") and add it again |
| `pc` says *permission denied* | not executable | `sudo chmod +x /usr/local/bin/pc` (the installer does this) |

## Remote Desktop

| Symptom | Cause | Fix |
|---|---|---|
| *The credentials did not work* | account has only a PIN | set a real password ([1.6](01-pc.md#16-password--automatic-logon)) |
| Windows App asks for the password every time | connecting via an `.rdp` file | save the PC with credentials inside the Windows App |
| Certificate warning every time | not trusted yet | *Show Certificate* → *Always trust* |
| *Your session was disconnected … another connection (0x5)* after ending | session handed back before the app was closed | use *End work session* / `pc release` (closes the app first) |
| Microphone greyed out | microphone declined at first start | [chapter 7](07-remote-desktop-extras.md#microphone) |
| Monitors stay on during remote desktop | sign-in screen ignores the lock-screen timeout | `windows/setup.ps1` ([chapter 7](07-remote-desktop-extras.md)) |
| Start menu opens partly off-screen in the session | resolution/scaling of the remote window | set *Display* in the Windows App to "fit window" or change scaling in the session |

## Streaming (Apollo / Moonlight)

| Symptom | Cause | Fix |
|---|---|---|
| Real monitors switch on although you stream | plain Sunshine, DisplayPort monitor off = disconnected | use Apollo ([chapter 5](05-apollo.md)) |
| Pairing: *connection closed* | Apollo took over Sunshine's pairings | Apollo → PIN → **Unpair All**, pair again |
| *403 Permission denied* when starting an app | new clients have restricted rights | Apollo → PIN → device → allow *Launch apps* + inputs |
| Monitors stay off after streaming | the session is only **paused** | *End play session* / `pc stop` / Apollo → Applications |
| Picture has black bars | Moonlight resolution ≠ display | *Native (excluding notch)* |
| Icons/text tiny | 1:1 pixels on a high-DPI display | Windows scaling on the virtual display (Apollo remembers it per device) |
| Trackpad scrolling far too fast | trackpad momentum → many wheel steps; no separate setting in Moonlight/Apollo; Windows setting is global | use a mouse for longer sessions, or Remote Desktop for work |
| ⌘ isn't the Windows key | Moonlight doesn't capture system shortcuts | *Capture system keyboard shortcuts* → in full screen (+ Accessibility permission) |
| Menu bar not reachable in the stream | Moonlight's full screen hides it | swipe to another desktop or control+option+shift+Q |
| Two Moonlight icons in the Dock | old versions started Moonlight with `open -n` | update; `pc` now runs only one instance |
| Menu shows *Play* although a stream runs | Apollo only reports the state to paired clients | update; the state is now remembered on the Mac |
| Black empty full-screen space | `PLAY_FULLSCREEN=yes` (experimental) | set it to `no`, quit Moonlight with ⌘Q |
| macOS 🚀 Game Mode icon | Moonlight counts as a game | click → *Turn Game Mode Off* (or keep it – it lowers latency) |

## Windows setup

| Symptom | Cause | Fix |
|---|---|---|
| `winget install … PsTools`: *Installer hash does not match* | Microsoft updated the ZIP, winget's manifest is behind | don't force it – `setup.ps1` downloads `PsExec64.exe` directly from Microsoft and verifies the signature |
| `setup.ps1`: *InstallDir must not contain spaces* | Windows PowerShell 5.1 drops inner quotes when calling `schtasks` | use a path without spaces |
| `apps2samsung-cli`: *Subnet mismatch* | a VPN on the PC is active | disconnect the VPN during the install |

## Network

| Symptom | Cause | Fix |
|---|---|---|
| Whole network loses DNS when the NAS restarts | Pi-hole is the only DNS server | [DNS fallback](02-dns-fallback.md) |
| Random network drops of the PC | in our case: a broken LAN cable | swap the cable before debugging software 🙂 |
