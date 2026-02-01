# Force-Sync.ps1 - Zwingt den PC zum Update
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

Write-Host "FORCING UPDATE FROM MAC..." -ForegroundColor Yellow

# 1. Zwangspull
git fetch --all
git reset --hard origin/master

# 2. Status Update
"SYNC FORCED BY MAC AT $(Get-Date)" | Out-File "Logs\LIVE_STATUS.md" -Append

Write-Host "SYSTEM UPDATED. RESTARTING GUARDIAN..." -ForegroundColor Green

# 3. Guardian neu starten
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File .\Scripts_Backup\Guardian-Loop.ps1"
