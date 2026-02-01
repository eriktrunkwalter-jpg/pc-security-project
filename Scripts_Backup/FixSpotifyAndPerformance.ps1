# === RESTORE MULTIMEDIA & PERFORMANCE ===
# Run as ADMINISTRATOR
# Fixes Spotify and Performance Issues

Write-Host "--- FIXING SPOTIFY & PERFORMANCE ---" -ForegroundColor Cyan

# 1. FIX NETWORK (IPv6 & Multicast for Spotify)
Write-Host "[+] Restoring Network for Multimedia..." -ForegroundColor Green
# Restore IPv6 (Spotify needs it often)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0 -Type DWord -ErrorAction SilentlyContinue

# Restore Multicast/LLMNR (Spotify Connect needs it)
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -ErrorAction SilentlyContinue

# 2. FIX FIREWALL (Explicitly Allow Spotify)
Write-Host "[+] Creating Firewall Rules for Spotify..." -ForegroundColor Green
$spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"
if (Test-Path $spotifyPath) {
    New-NetFirewallRule -DisplayName "Spotify_In_Allow" -Direction Inbound -Program $spotifyPath -Action Allow -Profile Any -Force -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Spotify_Out_Allow" -Direction Outbound -Program $spotifyPath -Action Allow -Profile Any -Force -ErrorAction SilentlyContinue
    Write-Host "   -> Spotify Rules Added."
} else {
    Write-Host "   -> Spotify.exe not found at standard location." -ForegroundColor Yellow
}

# 3. FIX PERFORMANCE (Reset TCP & Services)
Write-Host "[+] Resetting Performance Settings..." -ForegroundColor Green
# Reset TCP Congestion Provider (CTCP might cause lag on some routers)
netsh int tcp set global congestionprovider=default
# Ensure Audio Services are Priority
Set-Service "Audiosrv" -StartupType Automatic
Set-Service "AudioEndpointBuilder" -StartupType Automatic
Start-Service "Audiosrv" -ErrorAction SilentlyContinue

# 4. RESTORE XBOX SERVICES (Sometimes needed for Gaming/Store)
Write-Host "[+] Restoring Gaming Services..." -ForegroundColor Green
Set-Service "XblAuthManager" -StartupType Manual -ErrorAction SilentlyContinue
Set-Service "XblGameSave" -StartupType Manual -ErrorAction SilentlyContinue

# 5. CLEAR CACHES (Can cause slowness)
Write-Host "[+] Clearing Network Cache..." -ForegroundColor Green
ipconfig /flushdns

Write-Host "--- FIX COMPLETE! PLEASE REBOOT ---" -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
