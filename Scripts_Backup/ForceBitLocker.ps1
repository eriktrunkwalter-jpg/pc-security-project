# === FORCE BITLOCKER (ADMIN ELEVATION) ===
$params = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "Elevating to Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList $params
    exit
}

# --- ACTUAL SCRIPT ---
$ErrorActionPreference = "Stop"
$Password = "ErikUser13092002!"
$RecoveryFile = "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"

Write-Host "--- ACTIVATING BITLOCKER (ADMIN) ---" -ForegroundColor Magenta
$SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force

try {
    # Try Standard
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -PasswordProtector -Password $SecurePass -SkipHardwareTest -UsedSpaceOnly
    Write-Host "SUCCESS: BitLocker Enabled." -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Retrying with manage-bde (CLI Fallback)..." -ForegroundColor Yellow
    # Fallback to CLI
    manage-bde -on C: -pw -sk -em XtsAes256
}

Start-Sleep -Seconds 5
# Extract Key
$Key = (Get-BitLockerVolume -MountPoint "C:").KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
if ($Key) {
    $Key.RecoveryPassword | Out-File $RecoveryFile -Encoding UTF8
    Write-Host "RECOVERY KEY SAVED: $($Key.RecoveryPassword)" -ForegroundColor Yellow
}
Read-Host "Press Enter to Exit"

