# 5 – Apollo: streaming with a virtual display

[Apollo](https://github.com/ClassicOldSong/Apollo) is a fork of [Sunshine](https://github.com/LizardByte/Sunshine)
(the streaming server for Moonlight) with a built-in **virtual display** (SudoVDA driver). Why it matters:

- The stream gets **exactly your device's resolution** (MacBook without notch, 4K TV, …).
- Your **real monitors switch off** while you stream and come back afterwards.
- With DisplayPort monitors, a monitor that is switched off counts as *disconnected* – plain Sunshine
  then has nothing to capture. The virtual display solves that.

## 5.1 Coming from Sunshine?

Keep Sunshine installed as a fallback, but stop it – both use the same ports. Admin PowerShell:

```powershell
Stop-Service SunshineService
Set-Service SunshineService -StartupType Disabled
```

## 5.2 Install

Download the Windows installer (`.exe`) from Apollo's
[releases](https://github.com/ClassicOldSong/Apollo/releases/latest) and install with defaults. It
installs the Apollo service, the **SudoVDA** virtual display driver (silently – check Device Manager →
Display adapters → *SudoMaker Virtual Display Adapter*) and the firewall rules.

Open `https://localhost:47990` (accept the certificate warning – it's self-signed) and create the Apollo
web login.

## 5.3 Settings

*Configuration → Audio/Video*:

| Setting | Value |
|---|---|
| **Headless Mode** | ✅ – every app starts on the virtual display |
| *Advanced display device options* → **Device configuration** | **Deactivate other displays and activate only the specified display** |
| *Advanced display device options* → **Config revert on disconnect** | ✅ |

*Save* → *Apply*. Check the line *SudoVDA Driver status: Ready*.

## 5.4 Pair Moonlight

Moonlight → add PC (its IP) → it shows a PIN → Apollo web UI → **PIN** → enter it plus a device name.

- **Pairing fails ("connection closed")?** Apollo took over the pairings from Sunshine. Apollo → PIN →
  **Unpair All**, then pair again.
- **"403 Permission denied" when starting an app?** Apollo gives new devices restricted rights. Apollo →
  PIN → your device → *Edit* → allow **Launch apps** and the inputs you need (controller, keyboard,
  mouse). Clipboard/file transfer/server commands are not needed.

In Moonlight you'll see *Desktop*, *Steam Big Picture* and *Virtual Display* – with Headless Mode
*Desktop* and *Virtual Display* are the same.

## 5.5 Pause vs. end

Closing Moonlight (control+option+shift+Q or the window's ✕) only **pauses**: the app keeps running on
the PC, the virtual display stays, the **real monitors stay off**. Resume later, or end it with the menu
(*End play session*) / `pc stop`. If you prefer every close to end the session, enable *Terminate on
Pause* for the app in Apollo (Applications → Edit).

## 5.6 Display scaling on the virtual display

While streaming: right-click the desktop → *Display settings* → *Scale*, e.g. 200 % on a MacBook. Windows
remembers it **per device** (Apollo gives every client its own virtual display identity), your real
monitors keep their own scaling.

## Test

`pc play` → both real monitors go dark, the Mac shows the desktop in its native resolution → `pc stop`
→ monitors come back.
