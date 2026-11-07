# wake-and-stream - started by the scheduled task "WakeAndStream\Monitors off on remote desktop"
# (runs as SYSTEM) whenever someone logs on or reconnects via remote desktop.
# During remote desktop the PC screen shows the sign-in screen - this turns those monitors off.

Start-Sleep -Seconds 5                      # give Windows time to switch the sessions
$sessions = query session

# Only act if a remote desktop session is really active.
# (Handing the session back via tscon raises the same event - then the monitors should stay on.)
if (-not ($sessions -match 'rdp-tcp#')) { exit }

# ID of the session on the PC screen ("console")
$line = $sessions | Where-Object { $_ -match '^\s*>?console\s' } | Select-Object -First 1
$id = ($line -split '\s+' | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
if (-not $id) { exit }

& "$PSScriptRoot\PsExec64.exe" -accepteula -nobanner -i $id -s -d powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$PSScriptRoot\monitors-off.ps1" 2>$null | Out-Null
