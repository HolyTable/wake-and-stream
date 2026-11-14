# 10 – The widget

Instead of (or next to) the menu bar icon you can use a **widget** in Notification Center or on the
desktop. It shows the same state and the same choices as the menu bar, in two sizes:

| Size | Shows |
|---|---|
| small | state + the two most important buttons, *Shut down* / *Sleep* as round buttons in the corner |
| medium | state (with details like "Stream paused") + up to three buttons, *Shut down* / *Sleep* in the corner |

Clicks run **inside the widget** – Notification Center stays open. Turning on, *Shut down* and *Sleep*
ask "really …?" right in the widget (confirm or cancel; the question disappears after 20 seconds).
While something runs, the widget says so ("Turning on …").

Needs **macOS 14 or newer** and the **Command Line Tools** (`xcode-select --install`) – no Xcode, no
Apple developer account.

## Check everything (stethoscope)

The round **stethoscope** button in the corner runs [`pc doctor`](../README.md#using-the-pc-command) right in
the widget – nothing to type, nothing changes, the PC is never woken. After a few seconds the widget shows:

| Size | Result |
|---|---|
| small | *All good* or *2 problems* with the first problem, *Check again* below |
| medium | headline with the fix for the first problem (→ …), each problem with its message, all other checks in three columns |

✕ goes back to the normal view (it also does so by itself after 2 minutes). The full hints (e.g. the
keychain command) are in Terminal: `pc doctor`.

Under the hood the widget app runs `pc doctor --plain` – one tab-separated line per check
(`ok|bad|skip|info`, name, message, hint) – and passes the lines to the widget in `widget-state`.

## Install

`bash mac/install.sh` asks *Install the widget …?* at the end (Enter = yes). Then:

1. Click the date/time in the menu bar → **Edit Widgets**.
2. Search **Wake and Stream**, drag the small or medium widget into Notification Center or onto the
   desktop.

You can now remove the SwiftBar plugin (delete `wake-and-stream.10s.sh` from your SwiftBar plugin
folder) – or keep both.

## How it works

```
 widget (sandbox)                         Wake and Stream.app (background, starts at login)
 ┌──────────────────┐  reads             ┌──────────────────────────────────────────────┐
 │ state + buttons  │◄── widget-state ───│ every 10 s: pc state → widget-state           │
 │                  │                    │                                              │
 │ button click     │── widget-request ─►│ ask/<action> → widget shows "really …?"       │
 │ (App Intent)     │   + notification   │ do/<action>  → action.sh <action> (no dialog) │
 └──────────────────┘                    └──────────────────────────────────────────────┘
        both files live in ~/.config/wake-and-stream/
```

- **`~/Applications/Wake and Stream.app`** – an invisible background app (clicks in the widget show notifications only for errors – the widget shows the state itself) (no Dock icon, listed under
  *System Settings → General → Login Items*). It does what the SwiftBar plugin did: checks the state
  every 10 seconds (`pc state`) and redraws the widget when something changes.
- **The widget** runs in a sandbox and cannot reach the network or run scripts – it only reads the
  state file and hands clicks to the app.
- **Buttons are App Intents**, not links: a link would open the app and close Notification Center.
  App Intents need a description file (`Metadata.appintents`) that normally only Xcode generates –
  `mac/widget/build.sh` writes it from `extract.actionsdata.template`.

## Build it yourself

```bash
bash mac/widget/build.sh                       # → ~/Applications/Wake and Stream.app
bash mac/widget/build.sh --preview /tmp/prev   # renders every state as PNG (light + dark) to check the layout
```

The app is signed *ad hoc* (valid only on this Mac). `build.sh` quits the running widget, so macOS
loads the new version the next time it shows the widget; if it still looks old, remove it and add it again.

## Troubleshooting

| Problem | Fix |
|---|---|
| widget not in the gallery | open the app once (`open ~/Applications/"Wake and Stream.app"`); look for crash reports `~/Library/Logs/DiagnosticReports/WakeAndStreamWidget-*.ips` |
| widget says "Widget app is not running" | click *Start app*, or check *Login Items* |
| buttons do nothing | `log show --last 5m --predicate 'process == "linkd"' \| grep -i wake` – the intent description must be indexed |
| state is stale | `pc state` in Terminal must print `home=… on=…` (run `install.sh` again if `pc` is old) |
| "End work" does not appear | macOS hides the connection list from background apps, so the widget app asks the PC (`ssh … qwinsta`) – SSH with keys must work |

Pitfalls we hit while building it (so you don't have to):

- The widget extension must be linked with the entry point `_NSExtensionMain`
  (`-Xlinker -e -Xlinker _NSExtensionMain`), otherwise it crashes at start and never shows up.
- SwiftUI's Liquid Glass (`glassEffect`) is **not drawn inside widgets** – the buttons become
  invisible. The widget uses a glass-like fill instead; the widget background itself is glass anyway.
