# GenerateEncryptedBlob.ps1
# This script encrypts the sensitive data to be embedded in the final application.

$VaultPassword = "Lara04092019!"
$SecretContent = @"
=== BITLOCKER SICHERHEITSSPEICHER ===
Erstellt am: $(Get-Date -Format 'yyyy-MM-dd HH:mm')

[1] BitLocker Passwort:
ErikUser13092002!

[2] Wiederherstellungsschlüssel (Recovery Key):
163581-438592-518617-677391-246708-625273-066869-069586

Hinweis: Bewahren Sie dieses Programm sicher auf.
"@

# 1. Derive Key from Password (SHA256)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
$keyBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($VaultPassword))

# 2. Setup AES
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.Key = $keyBytes
$aes.GenerateIV()
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

# 3. Encrypt
$encryptor = $aes.CreateEncryptor()
$plainBytes = [System.Text.Encoding]::UTF8.GetBytes($SecretContent)
$encryptedBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)

# 4. Combine IV + Ciphertext
$finalBytes = $aes.IV + $encryptedBytes
$base64String = [Convert]::ToBase64String($finalBytes)

# 5. Output
$base64String | Out-File "$env:USERPROFILE\Documents\trae_projects\pc\VaultBlob.txt" -Encoding ascii
Write-Host "Blob generated."

