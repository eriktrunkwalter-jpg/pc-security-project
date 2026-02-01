# Auto-Sync.ps1
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."
Write-Host "Auto-Sync (Bidirektional) gestartet."

while ($true) {
    Write-Host "Updates vom Mac holen..."
    git pull

    $status = git status --porcelain
    if ($status) {
        Write-Host "Changes detected..."
        git add .
        git commit -m "Auto-Sync"
        git push
    }
    
    Start-Sleep -Seconds 10
}
