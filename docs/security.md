# Security

This setup is meant for a private home network. Know what it trades off:

## What is protected

- **No port is opened to the internet.** Everything runs through your router's VPN. Without the VPN
  nothing is reachable.
- **SSH with keys only** (`PasswordAuthentication no`). The UpSnap key only works from the NAS's IP
  (`from="…"`). The Mac uses SSH with `BatchMode` – it never falls back to a password prompt.
- **UpSnap login lives in the macOS keychain**, never in a file or in command-line arguments (the
  password is sent to UpSnap via stdin).
- **Scheduled task runs as SYSTEM** → its scripts are in `C:\ProgramData\WakeAndStream`, where only
  administrators and SYSTEM may write (`setup.ps1` sets this). Never point a SYSTEM task at scripts in a
  user folder – anything running as that user could change them and gain SYSTEM rights.
- **PsExec** is downloaded from Microsoft at setup time and only kept if its Authenticode signature is
  valid and issued to *Microsoft Corporation*.
- **Confirmation dialogs** before turning the PC on/off, *Cancel* as default.
- Apollo gives newly paired devices **restricted rights**; only allow what each device needs.

## What you trade off

- **Automatic logon:** whoever switches the PC on at home is logged in.
- **"End work session" leaves the PC unlocked** (needed so Moonlight can stream without a password).
  The monitors stay off, but someone at the PC only has to move the mouse. If other people have access
  to your PC, lock it instead (`Win+L`) and accept typing the password in Moonlight.
- **Apollo web UI and serverinfo** are reachable in your home network (and via VPN). Use a strong Apollo
  web password.
- **Full-tunnel VPN** sends all your traffic through your home connection – good on hotel Wi-Fi, but it
  uses your home upload.

## Smart plug as emergency reset (optional)

If the PC hangs, neither SSH nor UpSnap helps. A switchable plug (e.g. FRITZ!DECT) plus BIOS *Restore on
AC power loss = Power On* lets you cut power for a few seconds and have the PC boot again.

## Keeping personal data out of this repository

If you fork this repo, enable the privacy hook (see [CONTRIBUTING](../CONTRIBUTING.md)): it blocks commits
that contain your blocklisted values, private IPs other than the `192.168.1.x` examples, MAC addresses,
e-mail addresses, keys, and commits with a non-noreply author e-mail.
