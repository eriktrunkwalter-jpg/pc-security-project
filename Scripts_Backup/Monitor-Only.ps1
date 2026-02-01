$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."
Write-Host 'Monitor-Only gestartet' -ForegroundColor Cyan

while ($true) {
    $status = git status --porcelain
    if ($status) {
        Write-Host 'Sende Aenderungen...' -ForegroundColor Yellow
        git add .
        git commit -m 'Auto-Save'
        git push
    }

    git fetch origin -q
    $new = git log HEAD..origin/master --oneline
    if ($new) {
        Write-Host 'MAC AKTIVITAET:' -ForegroundColor Magenta
        Write-Host $new -ForegroundColor Magenta
    }

    Start-Sleep -Seconds 2
}
