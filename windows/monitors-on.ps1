# wake-and-stream - wakes the monitors of the session this script runs in.
# Windows only reliably reacts to real input -> tiny mouse move there and back (the pointer stays
# where it is) plus "display required".
Add-Type -Namespace WakeAndStream -Name Waker -MemberDefinition @'
[DllImport("user32.dll")]
public static extern void mouse_event(uint flags, int dx, int dy, uint data, UIntPtr extra);
[DllImport("kernel32.dll")]
public static extern uint SetThreadExecutionState(uint flags);
'@
$MOUSEEVENTF_MOVE = 0x0001
[WakeAndStream.Waker]::mouse_event($MOUSEEVENTF_MOVE, 1, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 100
[WakeAndStream.Waker]::mouse_event($MOUSEEVENTF_MOVE, -1, 0, 0, [UIntPtr]::Zero)
# ES_DISPLAY_REQUIRED (0x2) - once, resets the display idle timer
[WakeAndStream.Waker]::SetThreadExecutionState(0x00000002) | Out-Null
