# 11 – Auto sleep

Forgot to shut the PC down after working or playing remotely? It puts itself to sleep once nobody has
used it for **30 minutes**. Sleep (not shut down) on purpose: open programs and a paused game survive,
and *Turn on* wakes it via Wake-on-LAN as usual.

Installed by [`windows/setup.ps1`](../windows/setup.ps1) together with the other scripts – the
scheduled task **WakeAndStream\Auto sleep** runs `auto-sleep.ps1` as SYSTEM every 5 minutes.

## When does the PC count as "in use"?

| Check | How |
|---|---|
| Remote desktop | an established connection on TCP port 3389 |
| Moonlight | Apollo/Sunshine has its UDP stream ports 47998–48000 open (only while a client streams) |
| Someone at the PC | mouse/keyboard input since the last check – `last-input.ps1` asks Windows inside the session on the PC screen (via PsExec, without a window) |
| Load | CPU or GPU above 20 % (average over 5 s) |
| Stay-awake requests | a program or service asks Windows to stay awake (`powercfg /requests`, e.g. Windows Update, downloads, music) – driver requests are ignored |

Only when **none** of these applies for 30 minutes in a row does the PC go to sleep. After waking up
the count starts from zero. A paused Moonlight stream (app still running, nobody connected) counts as
idle – sleep keeps the game in memory.

Every automatic sleep is logged in `C:\ProgramData\WakeAndStream\auto-sleep.log`.

## Check what it sees

Admin PowerShell – shows every check, never puts the PC to sleep:

```powershell
powershell -ExecutionPolicy Bypass -File C:\ProgramData\WakeAndStream\auto-sleep.ps1 -Check
```

```text
idle  Remote desktop  no connection
idle  Moonlight       no stream
BUSY  At the PC       last mouse/keyboard input 0 min ago
idle  Load            CPU 3 %, GPU 1 % (limit 20 %)
idle  Stay awake      no requests

In use - no sleep.
```

Run it once while streaming and once while connected via remote desktop – the matching line must say
**BUSY**.

## Change or turn off

Re-run the setup (admin PowerShell, from the repository):

```powershell
powershell -ExecutionPolicy Bypass -File windows\setup.ps1 -AutoSleepMinutes 60   # other time
powershell -ExecutionPolicy Bypass -File windows\setup.ps1 -AutoSleepMinutes 0    # no auto sleep
```

## Good to know

- The sleep command is the same as *Sleep* in the menu/widget. If hibernation is enabled in Windows,
  the PC hibernates instead – Wake-on-LAN works from both.
- The Mac can't tell "asleep" from "off" – after an automatic sleep the widget simply shows the PC as off.
  *Turn on* works either way.
- Never goes to sleep? Run `-Check`: the line marked **BUSY** tells you why. A program that keeps a
  stay-awake request forever shows up under *Stay awake*.
- Changed Apollo's port in its settings? Then the stream ports move too (base port + 9 … + 11) – pass
  them with `-StreamPorts` in the scheduled task.
