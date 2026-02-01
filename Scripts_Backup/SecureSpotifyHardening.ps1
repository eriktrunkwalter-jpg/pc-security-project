# === ULTIMATE SPOTIFY HARDENING ===
# Run as ADMINISTRATOR
# Strategy: "Invisible PC, Visible Spotify"
# 1. Disable OS-Level Discovery (LLMNR/NetBIOS) -> Closes the Security Leak
# 2. Allow Discovery Protocols ONLY for Spotify.exe -> Restores Functionality

Write-Host "--- APPLYING GRANULAR FIREWALL ISOLATION ---" -ForegroundColor Cyan

# 1. KILL OS-LEVEL LEAKS (LLMNR & NetBIOS)
Write-Host "[+] Disabling Windows LLMNR & NetBIOS (The 'Leak')..." -ForegroundColor Green
# Disable LLMNR (Registry)
$dnsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $dnsPath)) { New-Item $dnsPath -Force | Out-Null }
Set-ItemProperty -Path $dnsPath -Name "EnableMulticast" -Value 0 -Type DWord # 0 = Disabled

# Disable NetBIOS (WMI)
$interfaces = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
foreach ($interface in $interfaces) {
    $interface.SetTcpipNetbios(2) | Out-Null # 2 = Disabled
}

# 2. CLEANUP GENERIC FIREWALL RULES
Write-Host "[+] Removing Generic Discovery Rules..." -ForegroundColor Green
# Remove broad "Allow" rules for mDNS/SSDP that might exist
Remove-NetFirewallRule -DisplayName "Trae_Generic_mDNS" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Trae_Generic_SSDP" -ErrorAction SilentlyContinue

# 3. CREATE "SPOTIFY ONLY" TUNNEL
Write-Host "[+] Creating 'Spotify-Only' Network Tunnel..." -ForegroundColor Green
$spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"

if (Test-Path $spotifyPath) {
    # Rule 1: Allow Spotify Full Outbound (Needs to stream music)
    New-NetFirewallRule -DisplayName "Spotify_Secure_Out" -Direction Outbound -Program $spotifyPath -Action Allow -Profile Any -Force
    
    # Rule 2: Allow Spotify Inbound Connect (TCP) - Dynamic Ports
    New-NetFirewallRule -DisplayName "Spotify_Connect_TCP" -Direction Inbound -Program $spotifyPath -Protocol TCP -Action Allow -Profile Any -Force

    # Rule 3: Allow Spotify Discovery (UDP 5353 mDNS & 1900 SSDP) - ONLY FOR THIS APP
    # This is the magic: We blocked the OS from doing this, but we allow the APP.
    New-NetFirewallRule -DisplayName "Spotify_mDNS_UDP" -Direction Inbound -Program $spotifyPath -Protocol UDP -LocalPort 5353 -Action Allow -Profile Any -Force
    New-NetFirewallRule -DisplayName "Spotify_SSDP_UDP" -Direction Inbound -Program $spotifyPath -Protocol UDP -LocalPort 1900 -Action Allow -Profile Any -Force
    
    Write-Host "   -> Spotify Isolated: Allowed protocols restricted to application binary."
} else {
    Write-Host "   ERROR: Spotify.exe not found at $spotifyPath" -ForegroundColor Red
}

# 4. BLOCK GLOBAL DISCOVERY (Safety Net)
Write-Host "[+] Blocking Global Discovery Ports for other apps..." -ForegroundColor Green
# Block mDNS/SSDP for everything else (implicit deny usually works, but we make it explicit for 'Public' profile)
New-NetFirewallRule -DisplayName "Block_Global_mDNS" -Direction Inbound -Protocol UDP -LocalPort 5353 -Action Block -Profile Public -Force
New-NetFirewallRule -DisplayName "Block_Global_SSDP" -Direction Inbound -Protocol UDP -LocalPort 1900 -Action Block -Profile Public -Force

Write-Host "--- ISOLATION COMPLETE ---" -ForegroundColor Magenta
Write-Host "Result: Windows is silent (Safe). Spotify can speak (Functional)."
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
