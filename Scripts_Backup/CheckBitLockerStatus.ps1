# Check BitLocker Status (Elevated)
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}
manage-bde -status C: | Out-File "$env:USERPROFILE\Documents\BL_Final_Status.txt" -Encoding UTF8
