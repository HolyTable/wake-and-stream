# 3 – Remote control: OpenSSH + UpSnap

- **Turning on:** a magic packet is a network broadcast – it does **not** travel through a VPN.
  [UpSnap](https://github.com/seriousm4x/UpSnap) runs on your always-on NAS inside the home network and
  sends it. The Mac asks UpSnap via its API (or you click in UpSnap's web page).
- **Turning off / sleep / handing the session back:** the Mac (and UpSnap) log in to the PC via
  **SSH with a key** and run a command.

## 3.1 OpenSSH server on Windows (keys only)

Admin PowerShell:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service sshd -StartupType Automatic
Start-Service sshd
```

Only allow your home network (the VPN puts your Mac into it as well):

```powershell
Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -RemoteAddress LocalSubnet
```

**Keys:** your Windows user is an administrator, so OpenSSH reads keys from
`C:\ProgramData\ssh\administrators_authorized_keys` (not from your user folder). Put one public key per
line; restrict the UpSnap key to the NAS:

```
ssh-ed25519 AAAA…your-mac-key… mac
from="192.168.1.10" ssh-ed25519 AAAA…upsnap-key… upsnap
```

The file must only be accessible to Administrators and SYSTEM:

```powershell
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "*S-1-5-32-544:F" /grant "*S-1-5-18:F"
```

Then switch password login off in `C:\ProgramData\ssh\sshd_config` (keep a backup copy first):

```
PasswordAuthentication no
```

`Restart-Service sshd`. **Test from the Mac:** `ssh your-windows-user@192.168.1.50 hostname`.

> Create the Mac key with `ssh-keygen -t ed25519` (no passphrase if the menu bar should work without
> asking) and copy `~/.ssh/id_ed25519.pub` – never the file without `.pub`.

## 3.2 Allow ping

UpSnap decides "online/offline" by ping. Windows blocks ping by default:

```powershell
Set-NetFirewallRule -Name FPS-ICMP4-ERQ-In -Profile Private -RemoteAddress LocalSubnet -Enabled True
```

## 3.3 UpSnap on the NAS

Deploy [`nas/upsnap-stack.yml`](../nas/upsnap-stack.yml) (e.g. Portainer → Stacks). `network_mode: host`
is required so the magic packet reaches your network. Open `http://<NAS-IP>:8090`, create the admin
account, then add the PC:

| Field | Value |
|---|---|
| IP | the PC's fixed IP, e.g. `192.168.1.50` |
| MAC | e.g. `AA:BB:CC:DD:EE:FF` |
| Netmask | `255.255.255.0` |
| Shutdown command | see below |
| Wake / shutdown timeout | `120` (seconds UpSnap waits for the state change) |

**SSH key for UpSnap:** open a console in the container and run
`ssh-keygen -t ed25519 -f /app/pb_data/ssh/id_ed25519 -N ""`. Download `id_ed25519.pub` with your NAS's
file manager (copy & paste in container consoles is often unreliable) and add it to
`administrators_authorized_keys` with `from="<NAS-IP>"`.

**Shutdown command** – the key is copied to `/tmp` first because some NAS systems force `rwxrwxrwx` on
shared folders and SSH refuses keys with such permissions:

```sh
cp /app/pb_data/ssh/id_ed25519 /tmp/k && chmod 600 /tmp/k && ssh -i /tmp/k -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=/app/pb_data/ssh/known_hosts your-windows-user@192.168.1.50 "shutdown /s /t 0"
```

**Test:** UpSnap → *Wake* → the PC turns green → *Shutdown* → it shuts down.

## 3.4 Login for the Mac

The `pc` command logs in to UpSnap's API with your UpSnap account. The password is stored in the macOS
**keychain**, never in a file – `mac/install.sh` asks for it, or later:

```bash
security add-generic-password -s wake-and-stream-upsnap -a "your-upsnap-user" -w
```

Test the login without turning anything on (prints only the start of the answer):

```bash
printf '{"identity":"%s","password":"%s"}' "your-upsnap-user" "$(security find-generic-password -s wake-and-stream-upsnap -w)" \
  | curl -s -X POST http://192.168.1.10:8090/api/collections/_superusers/auth-with-password -H 'Content-Type: application/json' --data @- | cut -c1-40
```

`{"record":…` = works. `Failed to authenticate` = wrong user/password. If the menu can't log in, it
falls back to opening UpSnap's web page.
