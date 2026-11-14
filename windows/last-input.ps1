# wake-and-stream - helper for auto-sleep.ps1. Runs inside the session on the PC screen (started via
# PsExec) and writes how many seconds ago the last mouse/keyboard input was to last-input.txt.
# Only a process inside that session can ask Windows for it (GetLastInputInfo).
Add-Type -Namespace WakeAndStream -Name Input -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
[DllImport("user32.dll")]
static extern bool GetLastInputInfo(ref LASTINPUTINFO info);
public static long IdleSeconds() {
  LASTINPUTINFO info = new LASTINPUTINFO();
  info.cbSize = (uint)Marshal.SizeOf(info);
  if (!GetLastInputInfo(ref info)) return -1;
  return unchecked((uint)Environment.TickCount - info.dwTime) / 1000;
}
'@
# -1 (Windows did not answer) is written as "failed" - auto-sleep.ps1 then counts the PC as busy, to be safe
$idle = [WakeAndStream.Input]::IdleSeconds()
Set-Content (Join-Path $PSScriptRoot 'last-input.txt') -Value $(if ($idle -ge 0) { $idle } else { 'failed' }) -Encoding ASCII
