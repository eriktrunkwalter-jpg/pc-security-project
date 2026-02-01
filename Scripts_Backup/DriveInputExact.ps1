# DriveInputExact.ps1
$LogFile = "$env:USERPROFILE\Documents\DriveInputLog.txt"
function Log { param($m) Add-Content $LogFile "[$((Get-Date).ToString('HH:mm:ss'))] $m" }

Log "Starting EXACT Title approach..."
$wshell = New-Object -ComObject WScript.Shell
Add-Type -AssemblyName Microsoft.VisualBasic

$proc = Start-Process "cmd.exe" -ArgumentList "/c $env:USERPROFILE\Documents\trae_projects\pc\LaunchBDE.bat" -PassThru

if ($proc) {
    Log "PID: $($proc.Id)"
    
    # Wait for title
    $title = ""
    for ($i=0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        $proc.Refresh()
        $title = $proc.MainWindowTitle
        Log "Current Title: '$title'"
        if ($title -match "BL_SETUP") { break }
    }
    
    if ($title -match "BL_SETUP") {
        Log "Attempting WScript.AppActivate('$title')..."
        if ($wshell.AppActivate($title)) {
            Log "Success!"
            $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
            Start-Sleep 1
            $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
        } else {
            Log "Failed. Trying VB AppActivate(PID)..."
            try {
                [Microsoft.VisualBasic.Interaction]::AppActivate($proc.Id)
                Log "VB Success!"
                $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
                Start-Sleep 1
                $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
            } catch {
                Log "VB Failed: $($_.Exception.Message)"
            }
        }
    }
    
    Start-Sleep 5
    manage-bde -on C: -rp -skiphardwaretest | Out-File "$env:USERPROFILE\Documents\BL_Enable_Log.txt"
    Start-Sleep 2
    manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
}

