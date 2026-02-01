# ConfigureBitLocker.ps1
# ZIEL: BitLocker aktivieren/konfigurieren mit spezifischem Passwort/PIN
# UND: Recovery Key ausgeben

param (
    [string]$Password = "ErikUser13092002!"
)

# Hilfsfunktionen
function Log-Action { param([string]$m) Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $m" -ForegroundColor Cyan }
function Log-Error { param([string]$m) Write-Host "   [ERROR] $m" -ForegroundColor Red }
function Log-Success { param([string]$m) Write-Host "   [OK] $m" -ForegroundColor Green }

Log-Action "Starte BitLocker Konfiguration..."

# 1. Check BitLocker Status
$status = Get-BitLockerVolume -MountPoint "C:"
Log-Action "Aktueller Status: $($status.ProtectionStatus)"

# 2. GPO: Enhanced PINs erlauben (für ASCII Zeichen im PIN)
Log-Action "Setze GPO: Erlaube erweiterte PINs..."
$gpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (!(Test-Path $gpoPath)) { New-Item $gpoPath -Force | Out-Null }
Set-ItemProperty -Path $gpoPath -Name "UseEnhancedPin" -Value 1 -Type DWord
Set-ItemProperty -Path $gpoPath -Name "AllowMbaWithoutTpm" -Value 1 -Type DWord # Fallback
Log-Success "GPO angepasst"

# 3. Protector hinzufügen
# Wir versuchen TPM+PIN. Wenn kein TPM, versuchen wir Password (Legacy).
$tpm = Get-Tpm
$hasTpm = $tpm.TpmPresent -and $tpm.TpmReady

try {
    if ($status.ProtectionStatus -eq "Off") {
        Log-Action "BitLocker ist AUS. Aktiviere..."
        
        if ($hasTpm) {
            Log-Action "TPM erkannt. Versuche TPM+PIN..."
            # Enable-BitLocker -MountPoint "C:" -Pin $Password -EncryptionMethod XtsAes256 -SkipHardwareTest -RecoveryPasswordProtector
            # Note: Enable-BitLocker might fail if policies aren't fully propagated or reboot pending.
            # Using specific protectors step-by-step is safer.
            Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -SkipHardwareTest -RecoveryPasswordProtector -Pin $Password -TpmAndPinProtector
        } else {
            Log-Action "Kein TPM oder nicht bereit. Versuche Software-Passwort..."
            Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -SkipHardwareTest -RecoveryPasswordProtector -PasswordProtector -Password $Password
        }
    } else {
        Log-Action "BitLocker ist bereits AN. Füge Protector hinzu/Aktualisiere..."
        
        # Check existing protectors
        $protectors = $status.KeyProtector
        
        # Remove existing PIN/Password if present to update it
        $pinProt = $protectors | Where-Object { $_.KeyProtectorType -eq "TpmPin" }
        if ($pinProt) { Remove-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $pinProt.KeyProtectorId }
        
        $pwProt = $protectors | Where-Object { $_.KeyProtectorType -eq "Password" }
        if ($pwProt) { Remove-BitLockerKeyProtector -MountPoint "C:" -KeyProtectorId $pwProt.KeyProtectorId }

        # Add new
        if ($hasTpm) {
            Add-BitLockerKeyProtector -MountPoint "C:" -TpmAndPinProtector -Pin $Password
        } else {
            # On OS drive, password protector might fail if not explicitly allowed via GPO "Enable use of BitLocker authentication requiring preboot keyboard input on slates" etc.
            # Assuming GPO "AllowMbaWithoutTpm" covers basic cases.
            Add-BitLockerKeyProtector -MountPoint "C:" -PasswordProtector -Password $Password
        }
    }
    Log-Success "Protector Konfiguration abgeschlossen"
} catch {
    Log-Error "Fehler beim Konfigurieren: $($_.Exception.Message)"
}

# 4. Get Recovery Key
Start-Sleep -Seconds 2
$finalStatus = Get-BitLockerVolume -MountPoint "C:"
$recoveryKey = $finalStatus.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }

if ($recoveryKey) {
    Write-Host "`n=======================================================" -ForegroundColor Yellow
    Write-Host " WICHTIG: BITLOCKER WIEDERHERSTELLUNGSSCHLÜSSEL" -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Yellow
    Write-Host "ID:  $($recoveryKey.KeyProtectorId)"
    Write-Host "KEY: $($recoveryKey.RecoveryPassword)" -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Yellow
    
    # Backup to file (User Documents)
    $backupPath = "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
    "BitLocker Recovery Key for C:`nID: $($recoveryKey.KeyProtectorId)`nKey: $($recoveryKey.RecoveryPassword)" | Out-File $backupPath
    Write-Host "Gespeichert in: $backupPath"
} else {
    Log-Error "Kein Recovery Key gefunden! Bitte manuell prüfen: 'manage-bde -protectors -get C:'"
}

