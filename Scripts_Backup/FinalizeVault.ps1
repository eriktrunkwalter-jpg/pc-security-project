# === FINALIZE VAULT & SHORTCUT (FIXED) ===
$ErrorActionPreference = "Stop"

$VaultPass = "Lara04092019!"
$KeyFile = "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
$SourceApp = "$env:USERPROFILE\Documents\trae_projects\pc\SecureKeyVault.ps1"
$DestDir = "$env:USERPROFILE\Documents\SecureVault"
$DestApp = "$DestDir\SecureKeyVault.ps1"

# Dynamic Desktop Path
$DesktopPath = [Environment]::GetFolderPath("Desktop")
if (-not (Test-Path $DesktopPath)) {
    # Fallback for OneDrive
    $DesktopPath = "$env:USERPROFILE\OneDrive\Desktop"
}
$ShortcutPath = Join-Path $DesktopPath "Sicherheits-Tresor.lnk"

# 1. Read Key
if (Test-Path $KeyFile) {
    $RecoveryKey = Get-Content $KeyFile -Raw
} else {
    $RecoveryKey = "KEY_NOT_FOUND_CHECK_BITLOCKER_STATUS"
}

# 2. Generate Content
$SecretContent = @"
=== BITLOCKER SICHERHEITSSPEICHER ===
Erstellt am: $(Get-Date -Format 'yyyy-MM-dd HH:mm')

[1] BitLocker Passwort:
ErikUser13092002!

[2] Wiederherstellungsschlüssel (Recovery Key):
$($RecoveryKey.Trim())

Hinweis: Bewahren Sie dieses Programm sicher auf.
"@

# 3. Encrypt (AES-256)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$keyBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($VaultPass))
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.Key = $keyBytes
$aes.GenerateIV()
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$encryptor = $aes.CreateEncryptor()
$plainBytes = [System.Text.Encoding]::UTF8.GetBytes($SecretContent)
$encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
$finalBytes = $aes.IV + $encryptedBytes
$base64String = [Convert]::ToBase64String($finalBytes)

# 4. Update App Code
$AppCode = Get-Content $SourceApp -Raw
# Regex replace the blob line
$NewAppCode = $AppCode -replace '\$EncryptedBlob = ".*"', "`$EncryptedBlob = `"$base64String`""
$NewAppCode | Out-File $SourceApp -Encoding UTF8

# 5. Install App
if (!(Test-Path $DestDir)) { New-Item -Path $DestDir -ItemType Directory -Force }
Copy-Item -Path $SourceApp -Destination $DestApp -Force

# 6. Create Shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestApp`""
$Shortcut.IconLocation = "shell32.dll,48"
$Shortcut.Description = "Secure Vault for BitLocker Keys"
$Shortcut.Save()

Write-Host "Vault Finalized. Shortcut Created at: $ShortcutPath"

