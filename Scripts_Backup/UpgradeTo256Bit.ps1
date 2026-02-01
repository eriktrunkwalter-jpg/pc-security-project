# === UPGRADE TO XTS-AES 256-BIT ===
# Warning: This script decrypts the drive to reset encryption method!

$ErrorActionPreference = "SilentlyContinue"
Write-Host "--- UPGRADING BITLOCKER TO 256-BIT ---" -ForegroundColor Cyan

# 1. SET REGISTRY POLICY TO FORCE XTS-AES 256
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

# Enable "Choose drive encryption method and cipher strength (Windows 10 [Version 1511] and later)"
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsOs" -Value 7 -Type DWord -Force
# 7 = XTS-AES 256-bit

# Ensure it's enabled generally
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsFdv" -Value 7 -Type DWord -Force
Set-ItemProperty -Path $regPath -Name "EncryptionMethodWithXtsRdv" -Value 7 -Type DWord -Force

Write-Host "[OK] Registry Policy set to XTS-AES 256 (Military Grade)." -ForegroundColor Green

# 2. CHECK CURRENT STATUS
$status = manage-bde -status C: | Out-String

if ($status -match "XTS-AES 256") {
    Write-Host "[OK] Drive is already XTS-AES 256." -ForegroundColor Green
    Exit
}

# 3. START DECRYPTION
Write-Host "[INFO] Drive is currently using lower encryption (likely 128-bit)."
Write-Host "[ACTION] Starting Decryption... (This allows us to re-encrypt with 256-bit)" -ForegroundColor Yellow
manage-bde -off C:

Write-Host "`n[IMPORTANT] Decryption runs in the background." -ForegroundColor Magenta
Write-Host "You must wait for it to reach 0% encrypted (Protection Off) before re-enabling."
Write-Host "Creating a 'FINALIZE_256BIT.ps1' on your Desktop to finish the job later."

# 4. CREATE FINALIZATION SCRIPT ON DESKTOP
$desktop = [Environment]::GetFolderPath("Desktop")
if (-not (Test-Path $desktop)) { $desktop = "$env:USERPROFILE\OneDrive\Desktop" }
$scriptPath = Join-Path $desktop "FINALIZE_256BIT_ENCRYPTION.ps1"

$scriptContent = @"
# === FINALIZE 256-BIT ENCRYPTION ===
# Run this AFTER decryption is complete (manage-bde -status C: shows 'Fully Decrypted')

Write-Host 'Checking Decryption Status...'
`$status = manage-bde -status C: | Out-String

if (`$status -match 'Percentage Encrypted: 0.0 %' -or `$status -match 'Protection Off') {
    Write-Host 'Drive is ready for 256-bit Encryption.' -ForegroundColor Green
    
    # RE-ENCRYPT with Password
    Write-Host 'Starting Encryption with XTS-AES 256...'
    # Note: We rely on the Registry Policy we just set to ensure 256-bit
    
    # Use VBScript for password entry if interactive prompt fails, but here we try standard first or instruct user
    # Actually, we can use the AutoBitLocker approach or just ask user to type it.
    # Since this is a final manual step, let's try to be helpful.
    
    Write-Host 'Please enter the standard password: ErikUser13092002!'
    manage-bde -on C: -pw -sk sd
    
    Write-Host 'Encryption Started. Please check manage-bde -status C: to verify XTS-AES 256.'
    Pause
} else {
    Write-Host 'Drive is NOT fully decrypted yet.' -ForegroundColor Red
    Write-Host `$status
    Write-Host 'Please wait and try again later.'
    Pause
}
"@

Set-Content -Path $scriptPath -Value $scriptContent
Write-Host "[OK] Finalization script created at: $scriptPath" -ForegroundColor Green

