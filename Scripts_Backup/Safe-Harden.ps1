# Safe-Harden.ps1 - Stellt Sicherheit & Anonymität her (OHNE Lockout)
# Admin-Rechte erforderlich

$ErrorActionPreference = "SilentlyContinue"

Write-Host "Starte sichere Härtung..." -ForegroundColor Cyan

# 1. Firewall Härtung (MIT Whitelist für Spotify & GitHub)
Write-Host "Konfiguriere Firewall..." -ForegroundColor Yellow
# Reset Firewall (Start from clean state)
# netsh advfirewall reset

# Block Inbound, Allow Outbound (Standard)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow

# Whitelist Spotify
$spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"
if (Test-Path $spotifyPath) {
    New-NetFirewallRule -DisplayName "Allow Spotify" -Direction Outbound -Program $spotifyPath -Action Allow -Force
    New-NetFirewallRule -DisplayName "Allow Spotify In" -Direction Inbound -Program $spotifyPath -Action Allow -Force
    Write-Host "Spotify erlaubt." -ForegroundColor Green
} else {
    Write-Warning "Spotify nicht gefunden unter $spotifyPath"
}

# Whitelist Git/GitHub
New-NetFirewallRule -DisplayName "Allow Git" -Direction Outbound -Program "C:\Program Files\Git\cmd\git.exe" -Action Allow -Force
New-NetFirewallRule -DisplayName "Allow GitHub CLI" -Direction Outbound -Program "C:\Program Files\GitHub CLI\gh.exe" -Action Allow -Force

# 2. Anonymität (Telemetry deaktivieren)
Write-Host "Deaktiviere Telemetrie..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force
Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"

# 3. BitLocker Check (Nur Warnung, kein Zwang)
Write-Host "Prüfe BitLocker..." -ForegroundColor Yellow
$drive = Get-BitLockerVolume -MountPoint "C:"
if ($drive.ProtectionStatus -eq "Off") {
    Write-Warning "BitLocker ist NICHT aktiv. Bitte manuell aktivieren für volle Sicherheit."
    # Wir starten es nicht automatisch, um Lockout zu vermeiden, wenn kein TPM da ist
} else {
    Write-Host "BitLocker ist aktiv und sicher." -ForegroundColor Green
}

# 4. Logs bereinigen (Anonymität)
Write-Host "Bereinige Logs..." -ForegroundColor Yellow
wevtutil el | ForEach-Object { wevtutil cl "$_" }

# 5. TOR NETWORK INTEGRATION
Write-Host "Prüfe Tor-Netzwerk..." -ForegroundColor Cyan
$torPath = "$PSScriptRoot\..\Tools\Tor\tor.exe"

if (Test-Path $torPath) {
    if (-not (Get-Process "tor" -ErrorAction SilentlyContinue)) {
        Write-Host "Starte Tor Hintergrund-Dienst..." -ForegroundColor Green
        Start-Process -FilePath $torPath -WindowStyle Hidden
        
        # Warte auf Bootstrap (bis Port 9050 offen ist)
        Write-Host "Warte auf Tor-Verbindung..." -NoNewline
        for ($i=0; $i -lt 20; $i++) {
            $conn = Test-NetConnection -ComputerName "127.0.0.1" -Port 9050 -InformationLevel Quiet
            if ($conn) { break }
            Start-Sleep -Seconds 2
            Write-Host "." -NoNewline
        }
        Write-Host ""
    } else {
        Write-Host "Tor läuft bereits." -ForegroundColor Green
    }
    
    # Prüfe ob Tor wirklich bereit ist, bevor wir Git umleiten
    if (Test-NetConnection -ComputerName "127.0.0.1" -Port 9050 -InformationLevel Quiet) {
        # Git über Tor leiten
        git config --global http.proxy socks5://127.0.0.1:9050
        Write-Host "Git-Sync ist jetzt ANONYM (Tor Proxy)." -ForegroundColor Green
    } else {
        Write-Warning "Tor scheint nicht bereit zu sein. Proxy wird NICHT aktiviert, um Verbindung zu halten."
        git config --global --unset http.proxy
    }
} else {
    Write-Warning "Tor nicht gefunden. Bitte 'Install-Tor.ps1' ausführen."
}

# 6. DNS LEAK PROTECTION (Cloudflare)
Write-Host "Setze sichere DNS-Server (1.1.1.1)..." -ForegroundColor Yellow
try {
    Get-NetAdapter | Where-Object Status -eq "Up" | Set-DnsClientServerAddress -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
} catch {}

Write-Host "Sichere Härtung abgeschlossen." -ForegroundColor Cyan
