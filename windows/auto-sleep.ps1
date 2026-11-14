<#
.SYNOPSIS
  wake-and-stream - auto sleep. Started every 5 minutes by the scheduled task
  "WakeAndStream\Auto sleep" (runs as SYSTEM). Puts the PC to sleep once nobody has used it for
  -Minutes minutes - e.g. when you forgot to shut it down after working or playing remotely.

.DESCRIPTION
  The PC counts as "in use" while at least one of these is true:
    - a remote desktop connection is open (TCP port 3389)
    - a Moonlight stream is running (Apollo/Sunshine has its stream ports 47998-48000 open)
    - someone used mouse/keyboard at the PC since the last check
    - CPU or GPU load is above -LoadPercent
    - a program or service asks Windows to stay awake ("powercfg /requests": updates, downloads, music ...)
  When the PC became idle is kept in auto-sleep.state. If the last check is long ago (the PC was
  asleep or off), counting starts again - so after waking up you always get the full -Minutes.
  Every automatic sleep is written to auto-sleep.log.

  See what the script sees, without sleeping (admin PowerShell):
    powershell -ExecutionPolicy Bypass -File C:\ProgramData\WakeAndStream\auto-sleep.ps1 -Check
#>
param(
  [int]$Minutes = 30,
  [int]$IntervalMinutes = 5,          # how often the scheduled task runs this script
  [int]$LoadPercent = 20,
  [int]$RdpPort = 3389,
  [int[]]$StreamPorts = @(47998, 47999, 48000),
  [switch]$Check
)
$ErrorActionPreference = 'Continue'
$state = Join-Path $PSScriptRoot 'auto-sleep.state'
$log   = Join-Path $PSScriptRoot 'auto-sleep.log'
$now   = Get-Date
$busy  = New-Object System.Collections.Generic.List[string]

# one line per check; with -Check it is also printed
function Note([string]$name, [bool]$isBusy, [string]$detail) {
  if ($isBusy) { $busy.Add("$name ($detail)") }
  if ($Check) {
    $mark = if ($isBusy) { 'BUSY' } else { 'idle' }
    Write-Host ('{0}  {1,-15} {2}' -f $mark, $name, $detail)
  }
}

function Write-Log([string]$text) {
  $old = @()
  if (Test-Path $log) { $old = @(Get-Content $log -Tail 199) }
  Set-Content $log -Value ($old + ('{0:yyyy-MM-dd HH:mm}  {1}' -f (Get-Date), $text)) -Encoding ASCII
}

# 1. remote desktop: an established TCP connection on the RDP port
$rdp = @(Get-NetTCPConnection -LocalPort $RdpPort -State Established -ErrorAction SilentlyContinue)
Note 'Remote desktop' ($rdp.Count -gt 0) $(if ($rdp.Count) { 'connected' } else { 'no connection' })

# 2. Moonlight: Apollo/Sunshine opens its UDP stream ports only while a client is streaming
$udp = @(Get-NetUDPEndpoint -LocalPort $StreamPorts -ErrorAction SilentlyContinue)
Note 'Moonlight' ($udp.Count -gt 0) $(if ($udp.Count) { 'stream running' } else { 'no stream' })

# 3. someone at the PC: last mouse/keyboard input in the session on the PC screen ("console").
#    SYSTEM cannot see that input itself, so last-input.ps1 runs inside that session via PsExec
#    (conhost --headless: no window flashes up) and writes the idle seconds to last-input.txt.
$consoleId = $null
$line = query session 2>$null | Where-Object { $_ -match '^\s*>?console\s' } | Select-Object -First 1
if ($line) { $consoleId = $line -split '\s+' | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1 }
$userSessions = @(Get-Process explorer -ErrorAction SilentlyContinue | ForEach-Object { $_.SessionId })
if (-not $consoleId -or $userSessions -notcontains [int]$consoleId) {
  Note 'At the PC' $false 'nobody signed in on the PC screen'
} else {
  $out = Join-Path $PSScriptRoot 'last-input.txt'
  Remove-Item $out -ErrorAction SilentlyContinue
  & "$PSScriptRoot\PsExec64.exe" -accepteula -nobanner -i $consoleId -s "$env:windir\System32\conhost.exe" --headless `
    powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\last-input.ps1" 2>$null | Out-Null
  $idle = Get-Content $out -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($idle -notmatch '^\d+$') {
    Note 'At the PC' $true 'could not read the last input - to be safe: counts as busy'
  } else {
    $idleMin = [int]$idle / 60
    Note 'At the PC' ($idleMin -lt $IntervalMinutes + 1) ('last mouse/keyboard input {0:0} min ago' -f $idleMin)
  }
}

# 4. load: average over 5 samples, 1 s apart (CPU total, GPU busiest engine type, e.g. 3D or compute)
$cpu = @(); $gpu = @()
for ($i = 0; $i -lt 5; $i++) {
  $c = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue
  if ($c) { $cpu += [int]$c.PercentProcessorTime }
  $g = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUEngine -ErrorAction SilentlyContinue)
  if ($g.Count) {
    $perType = $g | Group-Object { ($_.Name -split 'engtype_')[-1] } |
      ForEach-Object { ($_.Group | Measure-Object UtilizationPercentage -Sum).Sum }
    $gpu += [int](($perType | Measure-Object -Maximum).Maximum)
  }
  Start-Sleep -Seconds 1
}
$cpuAvg = if ($cpu.Count) { ($cpu | Measure-Object -Average).Average } else { 0 }
$gpuAvg = if ($gpu.Count) { ($gpu | Measure-Object -Average).Average } else { 0 }
Note 'Load' ($cpuAvg -gt $LoadPercent -or $gpuAvg -gt $LoadPercent) ('CPU {0:0} %, GPU {1:0} % (limit {2} %)' -f $cpuAvg, $gpuAvg, $LoadPercent)

# 5. programs/services that ask Windows to stay awake (drivers are ignored - some hold a request forever)
$section = ''; $requests = @()
foreach ($l in @(powercfg /requests 2>$null)) {
  if ($l -match '^([A-Z]+):\s*$') { $section = $Matches[1]; continue }
  if (($section -in @('SYSTEM', 'EXECUTION', 'AWAYMODE')) -and ($l -match '^\[(PROCESS|SERVICE)\]\s*(.+?)\s*$')) {
    $requests += ($Matches[2] -split '\\')[-1]
  }
}
Note 'Stay awake' ($requests.Count -gt 0) $(if ($requests.Count) { ($requests | Sort-Object -Unique) -join ', ' } else { 'no requests' })

# --- decide ---
$since = $now; $lastCheck = [datetime]::MinValue
$saved = @(Get-Content $state -ErrorAction SilentlyContinue)
if ($saved.Count -ge 2 -and $saved[0] -match '^\d+$' -and $saved[1] -match '^\d+$') {
  $since = [datetime][long]$saved[0]; $lastCheck = [datetime][long]$saved[1]
}
# PC was asleep/off (or first run) -> start counting now
if (($now - $lastCheck).TotalMinutes -gt 3 * $IntervalMinutes) { $since = $now }
if ($busy.Count) { $since = $now }
$idleFor = ($now - $since).TotalMinutes

if ($Check) {
  Write-Host ''
  if ($busy.Count) { Write-Host 'In use - no sleep.' -ForegroundColor Green }
  else { Write-Host ('Idle for {0:0} of {1} min - after that the PC goes to sleep.' -f $idleFor, $Minutes) -ForegroundColor Yellow }
  exit 0
}

if (-not $busy.Count -and $idleFor -ge $Minutes) {
  Write-Log ('idle for {0:0} min -> sleep' -f $idleFor)
  # forget the state - after waking up the count starts from zero
  Remove-Item $state -ErrorAction SilentlyContinue
  # same command as "Sleep" in the menu/widget (hibernates instead if hibernation is enabled)
  & rundll32.exe 'powrprof.dll,SetSuspendState' '0,1,0'
  exit 0
}
Set-Content $state -Value @($since.Ticks, $now.Ticks) -Encoding ASCII
