# DriveInputSlow2.ps1
$LogFile = "$env:USERPROFILE\Documents\DriveInputLog.txt"
function Log { param($m) Add-Content $LogFile "[$((Get-Date).ToString('HH:mm:ss'))] $m" }

Log "Starting SLOW Input 2..."
$wshell = New-Object -ComObject WScript.Shell
Add-Type -AssemblyName Microsoft.VisualBasic

$proc = Start-Process "cmd.exe" -ArgumentList "/c $env:USERPROFILE\Documents\trae_projects\pc\LaunchBDE.bat" -PassThru

if ($proc) {
    Log "PID: $($proc.Id)"
    
    # Wait for title
    for ($i=0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        $proc.Refresh()
        if ($proc.MainWindowTitle -match "BL_SETUP") { break }
    }
    
    # Wait for manage-bde to be ready (Batch waits 3s)
    Start-Sleep -Seconds 4
    
    Log "Focusing..."
    [Microsoft.VisualBasic.Interaction]::AppActivate($proc.Id)
    Start-Sleep -Milliseconds 500
    
    # Send Keys
    $pw = "ErikUser13092002{!}"
    
    Log "Typing PW1..."
    $wshell.SendKeys($pw)
    Start-Sleep -Milliseconds 500
    $wshell.SendKeys("{ENTER}")
    
    Log "Waiting for Confirm prompt..."
    Start-Sleep -Seconds 3
    
    Log "Typing PW2..."
    $wshell.SendKeys($pw)
    Start-Sleep -Milliseconds 500
    $wshell.SendKeys("{ENTER}")
    
    Log "Keys Sent. Waiting for completion..."
    Start-Sleep 10
    
    Log "Checking status..."
    manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
}

