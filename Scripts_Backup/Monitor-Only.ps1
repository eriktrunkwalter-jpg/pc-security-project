$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."
Write-Host 'Monitor-Only (Optimiert) gestartet' -ForegroundColor Cyan

$lastCommit = ""

while ($true) {
    # 1. Sende meine Änderungen (nur wenn es welche gibt)
    $status = git status --porcelain
    if ($status) {
        Write-Host 'Sende lokale Aenderungen...' -ForegroundColor Yellow
        git add .
        git commit -m 'Auto-Save'
        git push -q
    }

    # 2. Prüfe auf neue Mac-Aktivität
    git fetch origin -q
    $currentCommit = git rev-parse origin/master
    
    if ($currentCommit -ne $lastCommit) {
        $new = git log HEAD..origin/master --oneline
        if ($new) {
            # Nur anzeigen, wenn wir diesen Zustand noch nicht gemeldet haben
            # (Hier vereinfacht: Wenn sich der Remote-Head ändert, zeigen wir das Diff an)
            Write-Host "`n[NEUE AKTIVITAET VOM MAC]:" -ForegroundColor Magenta
            Write-Host $new -ForegroundColor Green
            $lastCommit = $currentCommit
        }
    }

    Start-Sleep -Seconds 2
}
