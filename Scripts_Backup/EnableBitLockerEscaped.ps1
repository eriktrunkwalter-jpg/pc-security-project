# EnableBitLockerEscaped.ps1
$Pin = "ErikUser13092002!"
$Log = "$env:USERPROFILE\Documents\BitLockerEscapedLog.txt"

function Log { param($m) Add-Content $Log "[$((Get-Date).ToString('HH:mm:ss'))] $m"; Write-Host $m }

Log "Trying to set password protector with escaping..."

# Method 1: Use specific quoting for cmd.exe to handle "!"
# "ErikUser13092002!" -> "^!..." or similar? 
# Easier: Write to a temporary batch file which handles the string literally, then run it.

$BatchFile = "$env:TEMP\EnableBL.bat"
$BatchContent = @"
@echo off
manage-bde -protectors -add C: -pw "%Pin%" > "$env:USERPROFILE\Documents\BL_Output.txt" 2>&1
manage-bde -on C: -rp -skiphardwaretest >> "$env:USERPROFILE\Documents\BL_Output.txt" 2>&1
"@
$BatchContent | Out-File $BatchFile -Encoding ASCII

Log "Batch file created: $BatchFile"
Log "Running batch file..."

Start-Process "cmd.exe" -ArgumentList "/c `"$BatchFile`"" -Wait -Verb RunAs

Log "Batch finished. Checking output..."
if (Test-Path "$env:USERPROFILE\Documents\BL_Output.txt") {
    $out = Get-Content "$env:USERPROFILE\Documents\BL_Output.txt"
    Log "Output:`n$($out -join "`n")"
}

# Get Key
Start-Sleep -Seconds 2
manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
Log "Key retrieval attempted."

