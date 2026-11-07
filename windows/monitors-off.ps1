# wake-and-stream - turns off the monitors of the session this script runs in
# (same as "turn off display after ..."). Mouse or keyboard input turns them back on.
# Started by rdp-monitors-off.ps1 inside the console session (sign-in screen during remote desktop).
Add-Type -Namespace WakeAndStream -Name Display -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
'@
# HWND_BROADCAST (0xFFFF), WM_SYSCOMMAND (0x0112), SC_MONITORPOWER (0xF170), 2 = off
[WakeAndStream.Display]::PostMessage([IntPtr]0xFFFF, 0x0112, [IntPtr]0xF170, [IntPtr]2) | Out-Null
