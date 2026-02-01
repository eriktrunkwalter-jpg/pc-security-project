# RESTORE_AND_SECURE.ps1
# 1. Restore Missing Shortcuts and Scripts
# 2. Enforce Final Security Settings

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DocPath = [Environment]::GetFolderPath("MyDocuments")

Write-Host ">>> FINAL RESTORATION & HARDENING <<<" -ForegroundColor Cyan

# --- 1. Restore BitLocker Finalizer Script ---
$BitLockerScriptPath = "$DesktopPath\FINALIZE_256BIT_ENCRYPTION.ps1"
$BitLockerContent = @"
# FINAL BITLOCKER ENCRYPTION STEP
# Run this when Decryption reaches 0%

Write-Host "Checking BitLocker Status..." -ForegroundColor Yellow
manage-bde -status C:

Write-Host "`nIf 'Percentage Encrypted' is 0.0% and 'Protection Status' is 'Off':" -ForegroundColor Cyan
Write-Host "Press ENTER to start XTS-AES 256 Encryption with Password." -ForegroundColor Cyan
Write-Host "Otherwise, close this window and wait longer." -ForegroundColor Gray
`$input = Read-Host "Press Enter to Continue or Ctrl+C to Cancel"

try {
    Write-Host "Setting Policy to XTS-AES 256..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "EncryptionMethodWithXtsOs" -Value 7 -Type DWord -Force
    
    Write-Host "Enabling BitLocker..." -ForegroundColor Yellow
    manage-bde -on C: -pw -sk sd
    
    Write-Host "SUCCESS! Encryption Started." -ForegroundColor Green
    Pause
} catch {
    Write-Host "Error: `$_" -ForegroundColor Red
    Pause
}
"@
Set-Content -Path $BitLockerScriptPath -Value $BitLockerContent
Write-Host "[+] Restored 'FINALIZE_256BIT_ENCRYPTION.ps1' to Desktop." -ForegroundColor Green

# --- 2. Restore Secure Vault Shortcut ---
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\Sicherheits-Tresor.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$DocPath\SecureVault\SecureKeyVault.ps1`""
$Shortcut.IconLocation = "shell32.dll,48" # Lock Icon
$Shortcut.Save()
Write-Host "[+] Restored 'Sicherheits-Tresor' Shortcut to Desktop." -ForegroundColor Green

# --- 3. Final Security Enforcement (DNS & Shadows) ---
Write-Host "[*] Enforcing Security..." -ForegroundColor Yellow
try {
    # DNS
    $ifIndex = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1 -ExpandProperty ifIndex
    if ($ifIndex) {
        Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses ("1.1.1.1", "9.9.9.9") -ErrorAction SilentlyContinue
        Write-Host "    [+] DNS set to Cloudflare/Quad9." -ForegroundColor Green
    }
    
    # Shadow Copies
    vssadmin delete shadows /all /quiet
    Write-Host "    [+] Shadow Copies purged." -ForegroundColor Green
    
} catch {
    Write-Host "    [!] Minor error in enforcement: `$_" -ForegroundColor Red
}

Write-Host "`n[DONE] System is Finalized." -ForegroundColor Cyan
Read-Host "Press Enter to Exit"
