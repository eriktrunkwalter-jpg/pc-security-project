# RunAutoBitLocker.ps1
# ZIEL: Automatisierte Aktivierung von BitLocker via VBScript Injection

function Log-Action { param([string]$m) Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $m" -ForegroundColor Cyan }

Log-Action "Starte VBScript Automation..."

# 1. Execute VBScript (Must run as Admin - this script is assumed to be running as Admin)
Start-Process "cscript.exe" -ArgumentList "//Nologo", "$env:USERPROFILE\Documents\trae_projects\pc\AutoBitLocker.vbs" -Wait

Log-Action "VBScript fertig. Prüfe Protectors..."

# 2. Check if protector was added
$status = Get-BitLockerVolume -MountPoint "C:"
$pwProt = $status.KeyProtector | Where-Object { $_.KeyProtectorType -eq "Password" }

if ($pwProt) {
    Log-Action "Passwort-Protector erfolgreich hinzugefügt!"
    
    # 3. Enable Encryption
    Log-Action "Aktiviere Verschlüsselung..."
    manage-bde -on C: -rp -skiphardwaretest
    
    # 4. Save Key
    Start-Sleep -Seconds 5
    manage-bde -protectors -get C: > "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
    Log-Action "Recovery Key gespeichert unter: $env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
} else {
    Write-Host "   [ERROR] Passwort-Protector wurde NICHT hinzugefügt. VBScript Timing Problem?" -ForegroundColor Red
}

