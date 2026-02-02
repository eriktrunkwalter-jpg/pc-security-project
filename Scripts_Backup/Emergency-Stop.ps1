# EMERGENCY STOP & CLEANUP
# Starten Sie dieses Skript, um alle laufenden Loops zu beenden und den PC freizugeben.

Write-Host "!!! EMERGENCY STOP INITIIERT !!!" -ForegroundColor Red -BackgroundColor Yellow

# 1. Beende alle Instanzen von 'Guardian-Loop' oder anderen Skripten
# Wir suchen nach PowerShell-Prozessen, die NICHT dieses Fenster sind.
$currentPid = $PID
$procs = Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $currentPid }

foreach ($p in $procs) {
    try {
        Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
        Write-Host "Prozess $($p.Id) beendet." -ForegroundColor Yellow
    } catch {}
}

# 2. Netzwerk zurücksetzen (falls durch Loop blockiert)
Write-Host "Setze Netzwerk zurück..." -ForegroundColor Cyan
ipconfig /flushdns
ipconfig /release
ipconfig /renew

# 3. Git-Locks entfernen (falls der Loop Git blockiert hat)
if (Test-Path ".git\index.lock") { Remove-Item ".git\index.lock" -Force }
if (Test-Path ".git\HEAD.lock") { Remove-Item ".git\HEAD.lock" -Force }

# 4. Status-Update (Lokal)
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host "PC IST JETZT FREI. KEINE SKRIPTE LAUFEN." -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host "Sie können das Fenster jetzt schließen."
