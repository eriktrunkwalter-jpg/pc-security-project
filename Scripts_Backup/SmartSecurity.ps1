# === HYBRID SECURITY & SPOTIFY OPTIMIZATION ===
# Run as ADMINISTRATOR
# Purpose: Maximum Security WITHOUT breaking Spotify/Multimedia

Write-Host "--- APPLYING SMART SECURITY (Spotify-Friendly) ---" -ForegroundColor Cyan

# 1. CORE SECURITY (Does not affect Spotify)
Write-Host "[+] Enabling Core Security (LSA & Telemetry)..." -ForegroundColor Green
# LSA Protection (Anti-Mimikatz)
$lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (!(Test-Path $lsaPath)) { New-Item $lsaPath -Force | Out-Null }
Set-ItemProperty -Path $lsaPath -Name "RunAsPPL" -Value 1 -Type DWord

# Disable Telemetry (Privacy)
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (!(Test-Path $telemetryPath)) { New-Item $telemetryPath -Force | Out-Null }
Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord
Stop-Service "DiagTrack" -ErrorAction SilentlyContinue
Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

# 2. NETWORK HARDENING (Smart Mode)
Write-Host "[+] Hardening Network (Smart Mode)..." -ForegroundColor Green
# Block Dangerous Ports (SMB/RPC) - Spotify doesn't need these
$profiles = @("Domain", "Private", "Public")
foreach ($profile in $profiles) {
    New-NetFirewallRule -DisplayName "Block_SMB_445_$profile" -Direction Inbound -LocalPort 445 -Protocol TCP -Action Block -Profile $profile -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Block_RPC_135_$profile" -Direction Inbound -LocalPort 135 -Protocol TCP -Action Block -Profile $profile -ErrorAction SilentlyContinue
}

# 3. SPOTIFY COMPATIBILITY LAYER (The "Solution")
Write-Host "[+] Configuring Spotify Compatibility..." -ForegroundColor Green

# ENABLE IPv6 (Crucial for Spotify Performance/Connectivity)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# ENABLE Multicast/LLMNR (Crucial for Spotify Connect / Device Discovery)
# We remove the "Disable" policy if it exists
$dnsClientPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
Remove-ItemProperty -Path $dnsClientPath -Name "EnableMulticast" -ErrorAction SilentlyContinue

# FIREWALL EXCEPTIONS for Spotify
$spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"
if (Test-Path $spotifyPath) {
    New-NetFirewallRule -DisplayName "Spotify_In_Allow" -Direction Inbound -Program $spotifyPath -Action Allow -Profile Any -Force -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Spotify_Out_Allow" -Direction Outbound -Program $spotifyPath -Action Allow -Profile Any -Force -ErrorAction SilentlyContinue
    Write-Host "   -> Spotify Whitelisted in Firewall."
}

# 4. CLEANUP & PERFORMANCE
Write-Host "[+] Cleaning & Optimizing..." -ForegroundColor Green
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
ipconfig /flushdns

Write-Host "--- SMART SECURITY APPLIED! PLEASE REBOOT ---" -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
