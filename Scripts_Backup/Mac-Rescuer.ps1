# Mac-Rescuer.ps1 - Notfall-Wiederherstellung durch den Mac
param([string]$SafeCommitHash = "a199a75c002f75757ac8f2ebbb55552a40909a18", [switch]$Force = $false)

$triggerFile = "RESTORE_REQUEST.trigger"

if ((Test-Path $triggerFile) -or $Force) {
    Write-Host "NOTFALL-WIEDERHERSTELLUNG VOM MAC ANGEFORDERT!" -ForegroundColor Red -BackgroundColor Yellow
    
    # 1. Hard Reset auf den sicheren Commit
    git reset --hard $SafeCommitHash
    
    # 2. Trigger löschen
    Remove-Item $triggerFile -Force
    
    # 3. Push Force, um den Remote auch zu resetten (optional, aber gut für Sync)
    # git push origin HEAD --force 
    # (Vorsicht mit Force Push, lieber nur lokal resetten und dann sauberen Status melden)
    
    Write-Host "System auf sicheren Zustand ($SafeCommitHash) zurückgesetzt." -ForegroundColor Green
    
    # 4. Status Update
    "SYSTEM RESTORED TO SAFE STATE BY MAC REQUEST AT $(Get-Date)" | Out-File "Logs\LIVE_STATUS.md" -Append
    
    # 5. Neustart der Monitor-Skripte erzwingen (hier symbolisch)
    Write-Host "Bitte Monitor neu starten."
}
