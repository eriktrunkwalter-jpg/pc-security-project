# DriveInput.ps1
# ZIEL: Simuliert Tastatureingaben für das BitLocker-Fenster

$LogFile = "$env:USERPROFILE\Documents\DriveInputLog.txt"
function Log { param($m) Add-Content $LogFile "[$((Get-Date).ToString('HH:mm:ss'))] $m" }

Log "Starting..."
$wshell = New-Object -ComObject WScript.Shell

# 1. Start Batch File (Hidden/Minimized? No, must be visible for SendKeys)
Log "Launching Batch File..."
Start-Process "cmd.exe" -ArgumentList "/c $env:USERPROFILE\Documents\trae_projects\pc\LaunchBDE.bat"
Start-Sleep -Seconds 3

# 2. Focus Window
Log "Attempting Focus 'BL_SETUP_WINDOW'..."
if ($wshell.AppActivate("BL_SETUP_WINDOW")) {
    Log "Focus Success. Sending Keys..."
    
    # Password: ErikUser13092002!
    # ! must be escaped as {!}
    $wshell.SendKeys("ErikUser13092002{!}")
    Start-Sleep -Milliseconds 500
    $wshell.SendKeys("{ENTER}")
    
    Start-Sleep -Seconds 1
    
    $wshell.SendKeys("ErikUser13092002{!}")
    Start-Sleep -Milliseconds 500
    $wshell.SendKeys("{ENTER}")
    
    Log "Keys Sent."
} else {
    Log "ERROR: Window 'BL_SETUP_WINDOW' not found!"
    # Try alternate titles just in case
    if ($wshell.AppActivate("Administrator")) {
         Log "Found 'Administrator' window instead. Trying..."
         $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
         Start-Sleep 1
         $wshell.SendKeys("ErikUser13092002{!}{ENTER}")
    }
}

Start-Sleep -Seconds 5

# 3. Enable Encryption (assuming password was set)
Log "Enabling BitLocker..."
manage-bde -on C: -rp -skiphardwaretest | Out-File "$env:USERPROFILE\Documents\BL_Enable_Log.txt"

# 4. Get Key
Start-Sleep -Seconds 2
manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
Log "Done."

