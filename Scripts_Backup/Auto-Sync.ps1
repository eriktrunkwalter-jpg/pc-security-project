# Auto-Sync.ps1
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."
Write-Host "Auto-Sync (TURBO MODE) gestartet."

while ($true) {
    Write-Host "Updates vom Mac holen..."
    git pull

    $status = git status --porcelain
    if ($status) {
        Write-Host "Changes detected..."
        git add .
        git commit -m "Auto-Sync (Turbo)"
        git push
    }
    
    # Reduziert auf 2 Sekunden für schnelleren Sync
    Start-Sleep -Seconds 2
}
