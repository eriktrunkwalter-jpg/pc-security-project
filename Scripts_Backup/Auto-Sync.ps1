# Auto-Sync.ps1
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."
Write-Host "Auto-Sync gestartet."

while ($true) {
    $status = git status --porcelain
    if ($status) {
        Write-Host "Changes detected..."
        git add .
        git commit -m "Auto-Sync"
        git push
    }
    Start-Sleep -Seconds 10
}
