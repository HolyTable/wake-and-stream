# wake-and-stream

**Use your Windows gaming PC from anywhere – without leaving it running all day.**

Wake the PC from your Mac through your router's VPN, work on it via Remote Desktop or play via
Moonlight, and shut it down again – all from one icon in the macOS menu bar.

> 🇩🇪 Kurz auf Deutsch: Windows-PC von unterwegs per WireGuard der FRITZ!Box aufwecken, per
> Remotedesktop arbeiten oder per Moonlight spielen und wieder ausschalten – bequem über ein Symbol
> in der Mac-Menüleiste. Menü und Meldungen gibt es auf Deutsch (`LANGUAGE=de`).

## What you get

- **Menu bar icon on the Mac** that shows the PC's state – on, off, asleep, or "VPN not connected" –
  with *Turn on*, *Work*, *Play*, *End session*, *Shut down*, *Sleep*.
- **Wake-on-LAN through the VPN.** Magic packets don't cross a VPN tunnel, so a small container on
  your NAS ([UpSnap](https://github.com/seriousm4x/UpSnap)) sends them; the Mac asks it via its API.
- **Work:** Remote Desktop (Windows App). *End work session* hands the session back to the PC
  screen without the usual "are you sure / another connection" dialogs.
- **Play:** Moonlight + [Apollo](https://github.com/ClassicOldSong/Apollo) with a virtual display –
  the stream matches your Mac's resolution (no notch), and the PC's real monitors stay **off**.
- **Monitors off during Remote Desktop too** (scheduled task), so nobody at home watches along.
- **Safety:** confirmation dialogs before turning on/off, SSH with keys only, no open ports.
- **Optional:** stream to a TV (Samsung/Tizen), German or English texts.

```
   MacBook (anywhere)                       Home network
 ┌────────────────────┐   WireGuard   ┌────────────┐
 │ menu bar  ─► pc     │═══════════════│  router    │
 │  ├ Windows App (RDP)│               └─────┬──────┘
 │  └ Moonlight        │                     │
 └────────────────────┘          ┌──────────┴───────────┐
                                  │                      │
                          ┌───────┴──────┐       ┌───────┴────────┐
                          │ NAS / server │ WoL   │ Windows PC     │
                          │ UpSnap (API) │──────►│ Apollo, RDP,   │
                          └──────────────┘       │ OpenSSH (keys) │
                                                 └────────────────┘
```

## Requirements

| Part | What you need |
|---|---|
| Router | VPN for your Mac, e.g. WireGuard on a FRITZ!Box (any router/VPN that puts you into the home network works) |
| NAS / home server | Docker (for UpSnap), always on |
| Windows PC | Windows 10/11 **Pro** (for Remote Desktop), Wake-on-LAN capable wired network card, NVIDIA/AMD/Intel GPU for streaming |
| Mac | macOS, [SwiftBar](https://github.com/swiftbar/SwiftBar), [Windows App](https://apps.apple.com/app/windows-app/id1295203466), [Moonlight](https://moonlight-stream.org) |

## Quick start

1. **PC:** prepare BIOS/Windows → [docs/01-pc.md](docs/01-pc.md)
2. **Remote control:** OpenSSH (keys only) + UpSnap on the NAS → [docs/03-remote-control.md](docs/03-remote-control.md)
3. **Streaming:** Apollo with virtual display → [docs/05-apollo.md](docs/05-apollo.md)
4. **Windows helpers** (admin PowerShell, in this repository):
   ```powershell
   powershell -ExecutionPolicy Bypass -File windows\setup.ps1
   ```
5. **Mac** (in this repository):
   ```bash
   bash mac/install.sh
   ```
6. **Test from outside** (phone hotspot) → [docs/09-test-from-outside.md](docs/09-test-from-outside.md)

## Guide

| # | Chapter |
|---|---|
| 1 | [Prepare the PC](docs/01-pc.md) – BIOS, Wake-on-LAN, fast startup, Remote Desktop, auto logon |
| 2 | [DNS fallback](docs/02-dns-fallback.md) – optional, if you run Pi-hole |
| 3 | [Remote control](docs/03-remote-control.md) – OpenSSH with keys, UpSnap on the NAS |
| 4 | [Mac](docs/04-mac.md) – VPN, Windows App, Moonlight, installer |
| 5 | [Apollo](docs/05-apollo.md) – virtual display, monitors off while streaming |
| 6 | [Menu bar](docs/06-menu-bar.md) – what each state and item means |
| 7 | [Remote Desktop extras](docs/07-remote-desktop-extras.md) – end session cleanly, monitors off, microphone |
| 8 | [TV](docs/08-tv.md) – Moonlight on a Samsung (Tizen) TV |
| 9 | [Test from outside](docs/09-test-from-outside.md) |
| – | [Troubleshooting](docs/troubleshooting.md) – every pitfall we hit, with the fix |
| – | [Security](docs/security.md) – what this setup trades off and why |

## Repository layout

```
mac/        pc command, SwiftBar plugin, installer, config example, icons (+ generator)
windows/    setup.ps1 / uninstall.ps1, release-session.bat, monitors off/on scripts
nas/        UpSnap Docker Compose stack
docs/       the guide
tools/      privacy check (pre-commit hook) and the Mac test suite
```

## Using the `pc` command

```
pc on | work | play        turn on (if needed) / + remote desktop / + Moonlight
pc stop | release          end the Moonlight stream / end remote desktop
pc off | sleep | status
```
German aliases: `an`, `arbeiten`, `spielen`, `stopp`, `zurueck`, `aus`, `standby`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) – run `bash tools/test-mac.sh` and enable the privacy hook.

## License

[MIT](LICENSE). Third-party tools (Apollo, Moonlight, UpSnap, SwiftBar, PsExec) are **not** included –
they are downloaded from their official sources and keep their own licenses.
