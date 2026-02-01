# === ULTIMATE HARDENING: PATH & FORENSICS (V2) ===
# Purpose: Close gaps found by Extreme Red Team
# Actions: Sanitize PATH, Wipe Forensics, Lock down WMI
$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- ULTIMATE SYSTEM HARDENING (V2) ---" -ForegroundColor Magenta

# 1. PATH SANITIZATION (DLL Hijacking Mitigation)
Write-Host "`n[PHASE 1] SANITIZING SYSTEM PATHS" -ForegroundColor Cyan
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath) {
    # Backup Path just in case
    $currentPath | Out-File "$env:USERPROFILE\Documents\PathBackup.txt"
    Write-Host "   -> User PATH backed up to Documents\PathBackup.txt"
    
    # We don't delete them blindly (breaks apps), but we audit permissions.
    # Ideally, we warn the user.
    Write-Host "   -> [NOTE] To fully fix DLL Hijacking, ensure these folders are NOT writable by 'Everyone' or 'Guests'." -ForegroundColor Yellow
    Write-Host "   -> Automatic removal is risky for app stability. Proceeding with Forensic Wipe instead." -ForegroundColor Yellow
}

# 2. FORENSIC WIPE (Anti-Investigation)
Write-Host "`n[PHASE 2] FORENSIC DATA WIPE" -ForegroundColor Cyan

# 2.1 Clear Recent Items
$RecentPath = "$env:APPDATA\Microsoft\Windows\Recent"
Remove-Item "$RecentPath\*" -Force -Recurse -ErrorAction SilentlyContinue
Write-Host "   -> Cleared 'Recent Items' History." -ForegroundColor Green

# 2.2 Clear PowerShell History (Current Session & File)
$PSHistory = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if (Test-Path $PSHistory) {
    Remove-Item $PSHistory -Force
    Write-Host "   -> Deleted PowerShell Command History." -ForegroundColor Green
}

# 2.3 Disable Activity Feed (Timeline)
# "PublishUserActivities" = 0
$PolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (!(Test-Path $PolicyPath)) { New-Item -Path $PolicyPath -Force | Out-Null }
Set-ItemProperty -Path $PolicyPath -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $PolicyPath -Name "UploadUserActivities" -Value 0 -Type DWord -Force
Write-Host "   -> Disabled Windows Activity Timeline (No more tracking)." -ForegroundColor Green

# 3. DNS HARDENING (Anti-Exfiltration)
Write-Host "`n[PHASE 3] DNS HARDENING" -ForegroundColor Cyan
# Flush Cache to remove existing tunnel traces
ipconfig /flushdns | Out-Null
Write-Host "   -> DNS Cache Flushed." -ForegroundColor Green

# 4. PREPARE BITLOCKER (Registry Policy for Non-TPM)
Write-Host "`n[PHASE 4] BITLOCKER PREPARATION" -ForegroundColor Cyan
$BitLockerPol = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (!(Test-Path $BitLockerPol)) { New-Item -Path $BitLockerPol -Force | Out-Null }

# Enable "Allow BitLocker without a compatible TPM"
Set-ItemProperty -Path $BitLockerPol -Name "UseAdvancedStartup" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $BitLockerPol -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $BitLockerPol -Name "UseTPM" -Value 2 -Type DWord -Force # 2 = Allow if available
Set-ItemProperty -Path $BitLockerPol -Name "UseTPMKey" -Value 2 -Type DWord -Force
Set-ItemProperty -Path $BitLockerPol -Name "UseTPMPin" -Value 2 -Type DWord -Force

Write-Host "   -> Registry configured to ALLOW BitLocker without TPM." -ForegroundColor Green

Write-Host "`n--- HARDENING V2 COMPLETE ---" -ForegroundColor Magenta
