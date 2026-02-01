# EnableBitLockerFixed.ps1
$Pin = "ErikUser13092002!"
$Log = "$env:USERPROFILE\Documents\BitLockerFixedLog.txt"

function Log { param($m) Add-Content $Log "[$((Get-Date).ToString('HH:mm:ss'))] $m"; Write-Host $m }

Log "Generating Batch File with interpolated password..."

# Create Batch File with the password directly embedded
# We use ASCII encoding to avoid BOM issues with legacy cmd
$BatchPath = "$env:TEMP\EnableBLFixed.bat"
$CmdLine = "manage-bde -protectors -add C: -pw ""$Pin"" > ""$env:USERPROFILE\Documents\BL_Output.txt"" 2>&1"
$CmdLine2 = "manage-bde -on C: -rp -skiphardwaretest >> ""$env:USERPROFILE\Documents\BL_Output.txt"" 2>&1"

$BatchContent = "@echo off`r`n$CmdLine`r`n$CmdLine2"
[System.IO.File]::WriteAllText($BatchPath, $BatchContent, [System.Text.Encoding]::ASCII)

Log "Batch file written to $BatchPath"
Log "Executing Batch File..."

Start-Process "cmd.exe" -ArgumentList "/c `"$BatchPath`"" -Wait -Verb RunAs

Log "Execution finished. Checking logs..."
if (Test-Path "$env:USERPROFILE\Documents\BL_Output.txt") {
    $out = Get-Content "$env:USERPROFILE\Documents\BL_Output.txt"
    Log "CMD Output:`n$($out -join "`n")"
}

# Retrieve Key
Start-Sleep -Seconds 2
manage-bde -protectors -get C: | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"

