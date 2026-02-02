# DNS-Fixer.ps1
# Setzt DNS auf Automatisch zurück (löst Browser-Probleme)

Write-Host "Setze DNS auf Automatisch (DHCP) für alle Adapter..." -ForegroundColor Cyan

try {
    Get-NetAdapter | ForEach-Object {
        Write-Host "Bearbeite Adapter: $($_.Name)..."
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
    }
    Write-Host "DNS erfolgreich zurückgesetzt!" -ForegroundColor Green
} catch {
    Write-Host "Fehler beim DNS-Reset via PowerShell. Versuche CMD-Methode..." -ForegroundColor Yellow
    & netsh interface ip set dns name="Wi-Fi" source=dhcp
    & netsh interface ip set dns name="Ethernet" source=dhcp
}

Write-Host "Lösche DNS-Cache..."
ipconfig /flushdns

Write-Host "Fertig! Bitte Browser neu starten." -ForegroundColor Green
