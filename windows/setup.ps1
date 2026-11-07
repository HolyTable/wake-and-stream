<#
.SYNOPSIS
  wake-and-stream - Windows setup. Run in an ADMIN PowerShell from the repository:
    powershell -ExecutionPolicy Bypass -File windows\setup.ps1

.DESCRIPTION
  1. Copies the scripts to C:\ProgramData\WakeAndStream (only admins can change files there -
     important, because the scheduled task runs them as SYSTEM).
  2. Downloads PsExec64.exe from Microsoft Sysinternals and checks its digital signature.
  3. Creates the scheduled task "WakeAndStream\Monitors off on remote desktop".
  Nothing else on the system is changed. Undo: windows\uninstall.ps1

.PARAMETER TurnMonitorsOnAfterRelease
  After "pc release" switch the monitors back on (default: they stay off until mouse/keyboard input).
#>
param(
  [string]$InstallDir = 'C:\ProgramData\WakeAndStream',
  [switch]$TurnMonitorsOnAfterRelease
)
$ErrorActionPreference = 'Stop'
$TaskName = 'WakeAndStream\Monitors off on remote desktop'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { Write-Host 'Please run this in an administrator PowerShell.' -ForegroundColor Red; exit 1 }

# 1. folder + scripts
New-Item -ItemType Directory -Force $InstallDir | Out-Null
'release-session.bat', 'monitors-off.ps1', 'monitors-on.ps1', 'rdp-monitors-off.ps1' |
  ForEach-Object { Copy-Item (Join-Path $PSScriptRoot $_) $InstallDir -Force }
$flag = Join-Path $InstallDir 'turn-monitors-on.flag'
if ($TurnMonitorsOnAfterRelease) { New-Item -ItemType File -Force $flag | Out-Null }
elseif (Test-Path $flag) { Remove-Item $flag }

# only Administrators and SYSTEM may change the folder, everyone else may only read/execute
icacls $InstallDir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' | Out-Null
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
$action = "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$InstallDir\rdp-monitors-off.ps1`""
schtasks /create /f /tn $TaskName /ru SYSTEM /rl HIGHEST /sc onevent `
  /ec Microsoft-Windows-TerminalServices-LocalSessionManager/Operational `
  /mo '*[System[(EventID=21 or EventID=25)]]' /tr $action | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'Could not create the scheduled task.' -ForegroundColor Red; exit 1 }
Write-Host "OK  scheduled task '$TaskName'"

Write-Host ''
Write-Host 'Done. Test: connect via remote desktop - after ~5-10 s the PC monitors turn off.'
