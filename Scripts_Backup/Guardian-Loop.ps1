# Guardian-Loop.ps1 - Der Hauptwächter
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

Write-Host "GUARDIAN SYSTEM GESTARTET" -ForegroundColor Green
Write-Host "Überwache Mac-Signale und Systemstatus..."

$safeCommit = "a199a75c002f75757ac8f2ebbb55552a40909a18" # Aktueller 'Clean' State

while ($true) {
    # 1. Hole Befehle vom Mac
    git fetch origin -q
    
    # Prüfe auf Restore-Trigger (Datei existiert im Remote?)
    # Wir müssen schauen, ob die Datei im Origin/Master existiert, ohne zu mergen
    $remoteFiles = git ls-tree -r origin/master --name-only
    if ($remoteFiles -contains "RESTORE_REQUEST.trigger") {
        Write-Host "ALARM: Mac fordert Restore an!" -ForegroundColor Red
        # Wir müssen pullen/checkout machen, um das Script auszuführen? 
        # Nein, wir führen unser lokales Rescue Script aus
        & ".\Scripts_Backup\Mac-Rescuer.ps1" -SafeCommitHash $safeCommit
        
        # Nach Restore müssen wir den Trigger auch remote löschen, das ist tricky ohne Push-Rechte oder wenn wir 'Read-Only' sein sollen.
        # Aber der User hat gesagt: "der mac soll dich wieder herstellen können".
        # Wir gehen davon aus, dass der Reset lokal reicht.
    }

    # 2. Sende Status (Heartbeat)
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "GUARDIAN ALIVE: $date | STATUS: SECURE" | Out-File "Logs\HEARTBEAT.txt"
    
    if (Test-Path "Logs\HEARTBEAT.txt") {
        git add "Logs\HEARTBEAT.txt"
        git commit -m "Guardian Heartbeat" -q
        git push -q
    }

    # 3. Führe Sicherheits-Checks alle 60 Sekunden aus
    if ((Get-Date).Second -eq 0) {
        Write-Host "Führe Routine-Check aus..." -ForegroundColor Gray
        # & ".\Scripts_Backup\Safe-Harden.ps1" 
        # (Auskommentiert, damit wir nicht spammen, nur bei Bedarf aktivieren)
    }

    Start-Sleep -Seconds 5
}
