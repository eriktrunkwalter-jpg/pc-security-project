# EnableBitLockerFallback.ps1
$PinSimple = "ErikUser13092002" # Removed ! to avoid syntax errors
$Log = "$env:USERPROFILE\Documents\BitLockerFallbackLog.txt"

function Log { param($m) Add-Content $Log "[$((Get-Date).ToString('HH:mm:ss'))] $m"; Write-Host $m }

Log "Trying simplified password (no special chars)..."

# Direct PowerShell execution of manage-bde (bypassing batch/cmd issues)
# We use Start-Process with ArgumentList which handles strings properly
$args = @("-protectors", "-add", "C:", "-pw", "$PinSimple")
$proc = Start-Process "manage-bde.exe" -ArgumentList $args -Wait -PassThru -NoNewWindow

if ($proc.ExitCode -eq 0) {
    Log "Protector added with simplified password."
    
    # Enable
    Start-Process "manage-bde.exe" -ArgumentList "-on", "C:", "-rp", "-skiphardwaretest" -Wait -NoNewWindow
    
    # Get Key
    Start-Sleep -Seconds 2
    $out = manage-bde -protectors -get C:
    $out | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
    Log "Recovery Key saved."
} else {
    Log "Failed even with simplified password. Exit Code: $($proc.ExitCode)"
}

