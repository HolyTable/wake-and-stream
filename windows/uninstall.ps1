<#
.SYNOPSIS
  wake-and-stream - removes what setup.ps1 created. Run in an ADMIN PowerShell:
    powershell -ExecutionPolicy Bypass -File windows\uninstall.ps1
#>
param([string]$InstallDir = 'C:\ProgramData\WakeAndStream')
$TaskName = 'WakeAndStream\Monitors off on remote desktop'

schtasks /delete /f /tn $TaskName 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host "OK  scheduled task removed" } else { Write-Host "-   no scheduled task found" }
schtasks /delete /f /tn 'WakeAndStream\Auto sleep' 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Host "OK  auto sleep task removed" } else { Write-Host "-   no auto sleep task found" }

if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force; Write-Host "OK  $InstallDir removed" }
else { Write-Host "-   $InstallDir not found" }
