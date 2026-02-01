# === REMEDIATION FOR BRUTAL RED TEAM FINDINGS ===
# Checks for Admin privileges and self-elevates if necessary

$params = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges to apply security fixes..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList $params
    exit
}

# --- ACTUAL FIXES BELOW ---

# 1. Fix LSASS Vulnerability (Enable LSA Protection)
$LsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
Write-Host "Hardening LSASS (Preventing Credential Dumping)..." -ForegroundColor Cyan
New-ItemProperty -Path $LsaPath -Name "RunAsPPL" -Value 1 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path $LsaPath -Name "LsaCfgFlags" -Value 1 -PropertyType DWord -Force | Out-Null

# 2. Fix Ransomware Vulnerability (Controlled Folder Access)
Write-Host "Enabling Controlled Folder Access (Ransomware Protection)..." -ForegroundColor Cyan
try {
    Set-MpPreference -EnableControlledFolderAccess AuditMode -ErrorAction Stop
    # Add Spotify to allow list
    Add-MpPreference -ControlledFolderAccessAllowedApplications "$env:USERPROFILE\AppData\Roaming\Spotify\Spotify.exe"
    Write-Host "   -> Ransomware Protection Enabled (Audit Mode)." -ForegroundColor Green
} catch {
    Write-Host "   -> Failed to set Defender Preference. Check manually." -ForegroundColor Red
}

Write-Host "Remediation Applied. Restart required." -ForegroundColor Green
Start-Sleep -Seconds 5

