<#
.SYNOPSIS
  wake-and-stream - Windows setup. Run in an ADMIN PowerShell from the repository:
    powershell -ExecutionPolicy Bypass -File windows\setup.ps1

.DESCRIPTION
  1. Copies the scripts to C:\ProgramData\WakeAndStream (only admins can change files there -
     important, because the scheduled task runs them as SYSTEM).
  2. Downloads PsExec64.exe from Microsoft Sysinternals and checks its digital signature.
  3. Creates the scheduled task "WakeAndStream\Monitors off on remote desktop".
  4. Creates the scheduled task "WakeAndStream\Auto sleep" (every 5 min, see auto-sleep.ps1).
  Nothing else on the system is changed. Undo: windows\uninstall.ps1

.PARAMETER TurnMonitorsOnAfterRelease
  After "pc release" switch the monitors back on (default: they stay off until mouse/keyboard input).

.PARAMETER AutoSleepMinutes
  Put the PC to sleep after this many minutes without use (default 30). 0 = no auto sleep.
#>
param(
  [string]$InstallDir = 'C:\ProgramData\WakeAndStream',
  [switch]$TurnMonitorsOnAfterRelease,
  [int]$AutoSleepMinutes = 30
)
$ErrorActionPreference = 'Stop'
$TaskName = 'WakeAndStream\Monitors off on remote desktop'
$SleepTaskName = 'WakeAndStream\Auto sleep'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Host 'Please run this in an administrator PowerShell.' -ForegroundColor Red; exit 1 }
# Windows PowerShell 5.1 drops inner quotes when calling schtasks/cmd - so the folder must not contain spaces
if ($InstallDir -match '\s') { Write-Host 'InstallDir must not contain spaces.' -ForegroundColor Red; exit 1 }
# older Windows PowerShell versions may not use TLS 1.2 by default (needed for the PsExec download)
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# 1. folder + scripts
New-Item -ItemType Directory -Force $InstallDir | Out-Null
'release-session.bat', 'monitors-off.ps1', 'monitors-on.ps1', 'rdp-monitors-off.ps1', 'auto-sleep.ps1', 'last-input.ps1' |
  ForEach-Object { Copy-Item (Join-Path $PSScriptRoot $_) $InstallDir -Force }
$flag = Join-Path $InstallDir 'turn-monitors-on.flag'
if ($TurnMonitorsOnAfterRelease) { New-Item -ItemType File -Force $flag | Out-Null }
elseif (Test-Path $flag) { Remove-Item $flag }

# only Administrators and SYSTEM may change the folder, everyone else may only read/execute
icacls $InstallDir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "Could not set the permissions on $InstallDir." -ForegroundColor Red; exit 1 }
Write-Host "OK  scripts -> $InstallDir (write access: admins only)"

# 2. PsExec (Microsoft Sysinternals) - not redistributed with this repo, downloaded from Microsoft
$psexec = Join-Path $InstallDir 'PsExec64.exe'
if (-not (Test-Path $psexec)) {
  Invoke-WebRequest 'https://live.sysinternals.com/PsExec64.exe' -OutFile $psexec -UseBasicParsing
}
$sig = Get-AuthenticodeSignature $psexec
if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'CN=Microsoft Corporation') {
  Remove-Item $psexec -Force
  Write-Host 'PsExec64.exe has no valid Microsoft signature - removed, setup stopped.' -ForegroundColor Red
  exit 1
}
Write-Host 'OK  PsExec64.exe (signature: Microsoft Corporation, valid)'

# 3. scheduled task: on remote desktop logon (event 21) or reconnect (event 25) -> monitors off
# (no quotes around the path on purpose - PowerShell 5.1 would strip them anyway; the path has no spaces)
$action = "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $InstallDir\rdp-monitors-off.ps1"
schtasks /create /f /tn $TaskName /ru SYSTEM /rl HIGHEST /sc onevent `
  /ec Microsoft-Windows-TerminalServices-LocalSessionManager/Operational `
  /mo '*[System[(EventID=21 or EventID=25)]]' /tr $action | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'Could not create the scheduled task.' -ForegroundColor Red; exit 1 }
# check that the task really exists and points to the right script
$xml = (schtasks /query /xml /tn $TaskName) -join "`n"
if ($xml -notmatch [regex]::Escape("$InstallDir\rdp-monitors-off.ps1")) {
  Write-Host 'Scheduled task was created but looks wrong - please check it in Task Scheduler.' -ForegroundColor Yellow
}
Write-Host "OK  scheduled task '$TaskName'"

# 4. scheduled task: every 5 minutes check whether the PC is in use, sleep after $AutoSleepMinutes idle minutes
if ($AutoSleepMinutes -gt 0) {
  $action = "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $InstallDir\auto-sleep.ps1 -Minutes $AutoSleepMinutes"
  schtasks /create /f /tn $SleepTaskName /ru SYSTEM /rl HIGHEST /sc minute /mo 5 /tr $action | Out-Null
  if ($LASTEXITCODE -ne 0) { Write-Host 'Could not create the auto sleep task.' -ForegroundColor Red; exit 1 }
  Write-Host "OK  scheduled task '$SleepTaskName' (sleep after $AutoSleepMinutes idle minutes)"
} else {
  # (not "schtasks /delete ... 2>$null": with ErrorActionPreference Stop, PowerShell 5.1 would abort on its error text)
  Get-ScheduledTask -TaskPath '\WakeAndStream\' -TaskName 'Auto sleep' -ErrorAction SilentlyContinue |
    Unregister-ScheduledTask -Confirm:$false
  Write-Host "-   auto sleep off (scheduled task '$SleepTaskName' removed if it existed)"
}

Write-Host ''
Write-Host 'Done. Test: connect via remote desktop - after ~5-10 s the PC monitors turn off.'
Write-Host "Auto sleep - what does it see right now? powershell -ExecutionPolicy Bypass -File $InstallDir\auto-sleep.ps1 -Check"
