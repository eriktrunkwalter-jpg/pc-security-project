# DriveInputPid.ps1
$LogFile = "$env:USERPROFILE\Documents\DriveInputLog.txt"
function Log { param($m) Add-Content $LogFile "[$((Get-Date).ToString('HH:mm:ss'))] $m" }

Log "Starting PID-based approach..."
$wshell = New-Object -ComObject WScript.Shell

# 1. Start Process and capture it
Log "Launching process..."
$proc = Start-Process "cmd.exe" -ArgumentList "/c $env:USERPROFILE\Documents\trae_projects\pc\LaunchBDE.bat" -PassThru

if ($proc) {
    Log "Process ID: $($proc.Id)"
    
    # Wait for window title to update
    for ($i=0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        $proc.Refresh()
        Log "Title: $($proc.MainWindowTitle)"
        if ($proc.MainWindowTitle -match "BL_SETUP") {
            Log "Title Match Found!"
            break
        }
    }
    
    # Try to Activate by PID
    Log "Activating by PID: $($proc.Id)..."
    if ($wshell.AppActivate($proc.Id)) {
        Log "Activation Success. Sending Keys..."
        Start-Sleep -Milliseconds 500
        
        $wshell.SendKeys("ErikUser13092002{!}")
        $wshell.SendKeys("{ENTER}")
        
        Start-Sleep -Seconds 1
        
        $wshell.SendKeys("ErikUser13092002{!}")
        $wshell.SendKeys("{ENTER}")
        Log "Keys Sent."
    } else {
        Log "Failed to Activate by PID. Trying Title..."
        if ($wshell.AppActivate("BL_SETUP_WINDOW")) {
            Log "Activated by Title."
            $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
            Start-Sleep 1
            $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
        } else {
            Log "Failed to Activate by Title too."
        }
    }
    
    # Wait for completion
    Start-Sleep -Seconds 5
    
    # Enable Encryption
    Log "Enabling..."
    manage-bde -on C: -rp -skiphardwaretest | Out-File "$env:USERPROFILE\Documents\BL_Enable_Log.txt"
    
    # Get Key
    Start-Sleep -Seconds 2
    manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
} else {
    Log "Failed to start process."
}
Log "Done."

