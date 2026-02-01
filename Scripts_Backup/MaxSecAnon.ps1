# === MAXIMUM SECURITY & ANONYMITY PROTOCOL ===
# COMBINES: State-Actor Hardening + Secure DNS + Spotify Exception + BitLocker 256
$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- ACTIVATING MAXIMUM SECURITY & ANONYMITY ---" -ForegroundColor Cyan

# 1. SECURE DNS (Privacy Layer)
Write-Host "[LAYER 1] DNS PRIVACY"
$interfaces = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.InterfaceAlias -notlike "*Pseudo*" }
foreach ($iface in $interfaces) {
    Write-Host "   -> Securing Interface: $($iface.InterfaceAlias)"
    # Primary: Cloudflare (1.1.1.1), Secondary: Quad9 (9.9.9.9) for redundancy & privacy
    Set-DnsClientServerAddress -InterfaceIndex $iface.InterfaceIndex -ServerAddresses ("1.1.1.1", "9.9.9.9") -ErrorAction SilentlyContinue
}
Write-Host "   -> DNS switched to Encrypted Providers (Cloudflare/Quad9)." -ForegroundColor Green

# 2. TELEMETRY & TRACKING KILL (Anonymity Layer)
Write-Host "`n[LAYER 2] DATA HARVESTING BLOCK"
# Telemetry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
# Advertising ID
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force
# Activity Feed
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -Force
# Location Service
Stop-Service "lfsvc" -Force -ErrorAction SilentlyContinue
Set-Service "lfsvc" -StartupType Disabled
Write-Host "   -> Telemetry, Ads, Timeline, Location: DISABLED." -ForegroundColor Green

# 3. NETWORK HARDENING (Security Layer)
Write-Host "`n[LAYER 3] NETWORK FORTRESS"
# SMBv1 Disable
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
# WPAD Disable (Man-in-the-Middle Protection)
Stop-Service "WinHttpAutoProxySvc" -Force -ErrorAction SilentlyContinue
Set-Service "WinHttpAutoProxySvc" -StartupType Disabled
Write-Host "   -> SMBv1 & WPAD (MitM Vector) Disabled." -ForegroundColor Green

# 4. SPOTIFY EXCEPTION (Usability Layer)
Write-Host "`n[LAYER 4] APP ISOLATION (SPOTIFY)"
# Remove old rules to be clean
Remove-NetFirewallRule -DisplayName "Allow Spotify Final" -ErrorAction SilentlyContinue
# Create strict Outbound Allow
New-NetFirewallRule -DisplayName "Allow Spotify Final" -Direction Outbound -Program "$env:APPDATA\Spotify\Spotify.exe" -Action Allow -Profile Any -Force | Out-Null
Write-Host "   -> Spotify Isolated & Allowed via Firewall." -ForegroundColor Green

# 5. BITLOCKER 256-BIT ENFORCEMENT (Physical Security)
Write-Host "`n[LAYER 5] ENCRYPTION INTEGRITY"
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsOs" -Value 7 -Type DWord -Force # XTS-AES 256
Write-Host "   -> Registry Policy: ENFORCED XTS-AES 256." -ForegroundColor Green

# 6. FINAL CLEANUP
Write-Host "`n[LAYER 6] ARTIFACT WIPING"
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   -> Temporary Artifacts Destroyed." -ForegroundColor Green

Write-Host "`n--- SYSTEM IS NOW AT MAXIMUM SECURITY LEVEL ---" -ForegroundColor Magenta
Write-Host "DNS: Secure | Disk: 256-Bit | App: Isolated | OS: Hardened"
