# Contributing

Thanks for improving wake-and-stream!

## 1. Enable the privacy check (once per clone)

```bash
git config core.hooksPath .githooks
```

Create your personal blocklist **outside** the repository – one text per line that must never be
committed (your name, real IPs, MAC address, user names, e-mail, …):

```bash
nano ~/.wake-and-stream-blocklist.txt
```

Use your GitHub noreply address for commits in this repo:

```bash
git config user.email "12345678+yourname@users.noreply.github.com"
```

Check everything at any time:

```bash
bash tools/check-private.sh --all
```

Examples in code and docs use `192.168.1.x`, `AA:BB:CC:DD:EE:FF` and `@example.com` – the check allows
exactly these.

## 2. Run the tests

```bash
bash tools/test-mac.sh
```

Runs the `pc` command, the menu bar plugin and the installer against fake versions of all macOS and
network commands – no Mac or PC needed. Please add a test for every bug you fix.

Windows scripts: at least run them through the PowerShell parser and test `setup.ps1` in an admin shell.

## 3. Style

- Mac scripts: bash 3.2 compatible (the version macOS ships), LF line endings.
- Windows scripts: Windows PowerShell 5.1 compatible, CRLF line endings (`.gitattributes` handles it).
- User-facing texts go into `mac/lib.sh` → `t()` – in **English and German**.
