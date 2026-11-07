# 9 – Test from outside

Do this before you rely on it on holiday. The Mac must **not** be in your home network.

## Preparation (iPhone hotspot)

1. iPhone: **turn its own VPN off** and **Wi-Fi off** (only mobile data).
2. iPhone: Personal Hotspot on → connect the Mac to it.
3. Mac, VPN still off: `ping -c 3 192.168.1.1` must **fail** (100 % packet loss) and the menu bar shows ⚠.
4. Connect the VPN → the ping answers, the menu shows the PC state.

> Mobile data: 60–120 ms latency is normal – fine for work, okay for relaxed games. Set Moonlight's
> bitrate to ~10 Mbit/s for the test (about 4–5 GB per hour).

## Checklist

- [ ] menu → *Power › Shut down* → icon turns red
- [ ] *Turn on* → confirm → no browser opens, notification "PC is ready", icon green
- [ ] *Work* → remote desktop works, PC monitors switch off after ~5–10 s → *End work session*
- [ ] *Play* → stream works → three-finger swipe to another desktop → *End play session* → monitors on
- [ ] *Sleep* → menu reacts immediately, icon becomes ☾ → *Wake up*
- [ ] backup: wake the PC with the router's app (e.g. MyFRITZ!App) – in case UpSnap/the NAS is down
