# === ACTIVATE BITLOCKER (NON-TPM MODE) ===
# Uses Password Protector
$ErrorActionPreference = "Stop"
$Password = "ErikUser13092002!"
$RecoveryFile = "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"

Write-Host "--- ACTIVATING BITLOCKER ---" -ForegroundColor Magenta

# 1. Convert Password to SecureString
$SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force

# 2. Enable BitLocker
# Syntax Correction: -PasswordProtector is a Switch, -Password is the parameter for the secure string
try {
    Write-Host "Attempting to enable BitLocker on C: ..." -ForegroundColor Cyan
    
    # Correct Syntax: -PasswordProtector (Switch) AND -Password (SecureString)
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -PasswordProtector -Password $SecurePass -SkipHardwareTest -UsedSpaceOnly
    
    Write-Host "   -> BitLocker Enabled Successfully!" -ForegroundColor Green
    
    # 3. Extract Recovery Key
    Start-Sleep -Seconds 5
    $Key = (Get-BitLockerVolume -MountPoint "C:").KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
    if ($Key) {
        $Key.RecoveryPassword | Out-File $RecoveryFile -Encoding UTF8
        Write-Host "   -> Recovery Key saved to: $RecoveryFile" -ForegroundColor Yellow
        Write-Host "   -> KEY: $($Key.RecoveryPassword)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   [!] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -match "group policy") {
        Write-Host "   -> Policy Conflict. Retrying with explicit TPM-bypass logic..." -ForegroundColor Yellow
    }
}

