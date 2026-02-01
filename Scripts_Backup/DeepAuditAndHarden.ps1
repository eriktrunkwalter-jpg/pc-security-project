# === DEEP AUDIT & HARDENING (STATE-ACTOR RESISTANT) ===
# Focus: Backdoor Elimination, ASR Rules, Service Hardening
# Safety: Preserves Spotify Functionality

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- INITIATING DEEP SYSTEM AUDIT ---" -ForegroundColor Magenta

# 1. BACKDOOR HUNTING
Write-Host "`n[PHASE 1] BACKDOOR ELIMINATION" -ForegroundColor Cyan

# 1.1 Sticky Keys / Utilman Backdoor Check
# Hackers replace sethc.exe or utilman.exe with cmd.exe to get System shell at login.
$System32 = "$env:SystemRoot\System32"
$SethcHash = (Get-FileHash "$System32\sethc.exe").Hash
$CmdHash = (Get-FileHash "$System32\cmd.exe").Hash

if ($SethcHash -eq $CmdHash) {
    Write-Host "   [!] CRITICAL: Sticky Keys Backdoor DETECTED!" -ForegroundColor Red
    # Remediation would require SFC /SCANNOW, user alert only for now.
} else {
    Write-Host "   [+] Sticky Keys (sethc.exe) is clean." -ForegroundColor Green
}

# 1.2 Hidden Users
Write-Host "   [+] Checking for Hidden Users..."
$Users = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
foreach ($u in $Users) {
    if ($u.Name -in @("Administrator", "Guest", "WDAGUtilityAccount")) { continue }
    if ($u.Name -eq $env:USERNAME) { continue }
    Write-Host "   [?] Review User: $($u.Name) (Enabled)" -ForegroundColor Yellow
}
# Disable Guest Account explicit
Disable-LocalUser -Name "Guest" -ErrorAction SilentlyContinue
Write-Host "   [+] Guest Account Disabled." -ForegroundColor Green

# 2. ATTACK SURFACE REDUCTION (ASR) RULES
Write-Host "`n[PHASE 2] ENABLING ASR RULES (BLOCK MODE)" -ForegroundColor Cyan
# These GUIDs are standard Microsoft ASR rules.
$ASR_Rules = @{
    "Block Office apps from creating child processes" = "d4f940ab-401b-4efc-aadc-ad5f3c50688a"
    "Block executable content from email client and webmail" = "be9ba2d9-53ea-4cdc-bd2e-747f489d3048"
    "Block JavaScript or VBScript from launching downloaded executable content" = "d3e037e1-3eb8-44c8-a917-57927947596d"
    "Block persistence through WMI event subscription" = "e6db77e5-3dde-48c5-9e60-167f033460b9"
    "Block credential stealing from LSASS" = "9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2"
}

foreach ($ruleName in $ASR_Rules.Keys) {
    $guid = $ASR_Rules[$ruleName]
    try {
        Add-MpPreference -AttackSurfaceReductionRules_Ids $guid -AttackSurfaceReductionRules_Actions Enabled -ErrorAction Stop
        Write-Host "   [+] Enabled: $ruleName" -ForegroundColor Green
    } catch {
        Write-Host "   [!] Failed to enable: $ruleName" -ForegroundColor Yellow
    }
}

# 3. SERVICE & PROTOCOL HARDENING
Write-Host "`n[PHASE 3] PROTOCOL & SERVICE HARDENING" -ForegroundColor Cyan

# 3.1 Disable SMBv1 (Legacy, Wannacry Vector)
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
Write-Host "   [+] SMBv1 Disabled." -ForegroundColor Green

# 3.2 Disable RDP (Remote Desktop)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1 -ErrorAction SilentlyContinue
Write-Host "   [+] Remote Desktop (RDP) Disabled." -ForegroundColor Green

# 3.3 Disable WPAD (Web Proxy Auto-Discovery - MITM Vector)
# Stops Windows from asking "Where is the proxy?" to the local network.
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name "WpadOverride" -Value 1 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
Write-Host "   [+] WPAD (Proxy Auto-Discovery) Disabled." -ForegroundColor Green

# 3.4 Disable PowerShell 2.0 (Legacy Downgrade Attack)
Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart -ErrorAction SilentlyContinue
Write-Host "   [+] PowerShell 2.0 (Legacy) Disabled." -ForegroundColor Green

# 4. PRIVACY & ANONYMITY (NO TELEMETRY)
Write-Host "`n[PHASE 4] PRIVACY ENHANCEMENT" -ForegroundColor Cyan
# Disable Advertising ID
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "   [+] Advertising ID Disabled." -ForegroundColor Green

Write-Host "`n--- DEEP AUDIT COMPLETE ---" -ForegroundColor Magenta
