# EnableBitLockerPipe.ps1
$Pin = "ErikUser13092002!"
$Log = "$env:USERPROFILE\Documents\BitLockerPipeLog.txt"
function Log { param($m) Add-Content $Log "[$((Get-Date).ToString('HH:mm:ss'))] $m"; Write-Host $m }

Log "Trying Interactive Pipe method..."

# Construct the command: echo Password | manage-bde ...
# We use a batch file again to handle the pipe reliably in the admin context
$BatchPath = "$env:TEMP\EnableBLPipe.bat"
# Use set /p to avoid trailing newline if needed, but echo is usually fine for manage-bde
$BatchContent = @"
@echo off
echo $Pin| manage-bde -protectors -add C: -pw > "$env:USERPROFILE\Documents\BL_Output.txt" 2>&1
manage-bde -on C: -rp -skiphardwaretest >> "$env:USERPROFILE\Documents\BL_Output.txt" 2>&1
"@
[System.IO.File]::WriteAllText($BatchPath, $BatchContent, [System.Text.Encoding]::ASCII)

Log "Running batch with pipe..."
Start-Process "cmd.exe" -ArgumentList "/c `"$BatchPath`"" -Wait -Verb RunAs

Log "Checking output..."
if (Test-Path "$env:USERPROFILE\Documents\BL_Output.txt") {
    $out = Get-Content "$env:USERPROFILE\Documents\BL_Output.txt"
    Log "CMD Output:`n$($out -join "`n")"
}

Start-Sleep -Seconds 2
manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"

