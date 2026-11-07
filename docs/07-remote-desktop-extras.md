# 7 – Remote Desktop extras

Installed by [`windows/setup.ps1`](../windows/setup.ps1) (admin PowerShell, from the repository):

```powershell
powershell -ExecutionPolicy Bypass -File windows\setup.ps1
```

It copies the scripts to `C:\ProgramData\WakeAndStream` (only administrators may change files there –
important, because a scheduled task runs them as SYSTEM), downloads **PsExec** from Microsoft
Sysinternals and checks its signature, and creates one scheduled task. Undo with `windows\uninstall.ps1`.

## End a session cleanly ("End work session" / `pc release`)

Normally, closing the remote desktop window asks "Are you sure?", and the PC stays **locked** at the
sign-in screen – annoying if you want to continue at the desk or stream with Moonlight afterwards.

`pc release` does it in this order:

1. closes the Windows App on the Mac immediately (no question) – the session on the PC is now just
   *disconnected*;
2. runs `release-session.bat` on the PC via SSH, which hands that session back to the PC screen
   (`tscon <session> /dest:console`) – **unlocked**.

The order matters: the other way round, the Windows App shows *"another connection was made to the
remote PC (0x5)"*.

## Monitors off during Remote Desktop

While you work remotely, the PC screen shows the Windows sign-in screen – and the monitors stay **on**
(the *console lock display-off timeout* only applies to the lock screen, not to the sign-in screen).

The scheduled task **WakeAndStream\Monitors off on remote desktop** reacts to the Windows events for a
remote desktop logon/reconnect (21/25), waits 5 s, checks that a remote desktop session is really
active and then switches the monitors of the PC screen off – using PsExec to run
`monitors-off.ps1` inside that console session. Any mouse/keyboard input at the PC turns them back on.

After *End work session* the monitors stay off until someone touches mouse or keyboard (protects
OLEDs, nobody sees your unlocked desktop). Want them on automatically?

```powershell
powershell -ExecutionPolicy Bypass -File windows\setup.ps1 -TurnMonitorsOnAfterRelease
```

Optional, independent of this project: make the monitors switch off quickly when you lock the PC
(`Win+L`) – admin PowerShell:

```powershell
powercfg -attributes SUB_VIDEO 8ec4b3a5-6868-48c2-be75-4f3044be88a7 -ATTRIB_HIDE
powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOCONLOCK 10
powercfg /setactive SCHEME_CURRENT
```

## Microphone

Windows App → right-click the PC → *Edit* → *Devices & Audio* → **Microphone**. In the session it shows up
as *Remote Audio*.

**Microphone/Cameras greyed out?** You declined the microphone question when the Windows App started for
the first time. Resetting the macOS permission (`tccutil reset Microphone com.microsoft.rdc.macos`) does
**not** help – the app remembers it itself. What works: quit the Windows App, move it to the Bin together
with `~/Library/Group Containers/UBF8T346G9.com.microsoft.rdc` (only this folder!), reinstall from the App
Store, **allow** the microphone, add the PC again.

Moonlight cannot transmit a microphone – run voice chat (Discord etc.) directly on the Mac while playing.
