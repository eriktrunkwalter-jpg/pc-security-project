# EnableBitLockerSecure.ps1
$Pin = "ErikUser13092002!"
$Log = "$env:USERPROFILE\Documents\BitLockerSecureLog.txt"

function Log { param($m) Add-Content $Log "[$((Get-Date).ToString('HH:mm:ss'))] $m"; Write-Host $m }

Log "Attempting PowerShell BitLocker Enable (SecureString)..."

try {
    # 1. Convert Password
    $SecurePin = ConvertTo-SecureString $Pin -AsPlainText -Force
    Log "Password converted to SecureString."

    # 2. Enable
    # Note: On non-TPM OS drives, -PasswordProtector is often invalid. 
    # Valid protectors: -StartupKeyProtector OR -Tpm...
    # BUT, if "AllowMbaWithoutTpm" is set, -PasswordProtector MIGHT work if the OS supports "Slate" mode pre-boot auth.
    # Let's try.
    Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -SkipHardwareTest -RecoveryPasswordProtector -PasswordProtector -Password $SecurePin -ErrorAction Stop
    Log "SUCCESS: Enable-BitLocker command accepted."
} catch {
    Log "ERROR (PowerShell): $($_.Exception.Message)"
    Log "Details: $($_.Exception.InnerException.Message)"
    
    # Fallback: Try managing protectors separately
    Log "Trying to add protector via manage-bde (Capturing Output)..."
    $output = cmd /c "manage-bde -protectors -add C: -pw $Pin 2>&1"
    Log "Manage-bde Output:`n$output"
    
    if ($output -match "Fehler" -or $output -match "Error") {
        Log "Manage-bde failed. Trying to just Enable with Recovery Password (No User Password)..."
        $res = cmd /c "manage-bde -on C: -rp -skiphardwaretest 2>&1"
        Log "Fallback Output:`n$res"
    }
}

# 3. Get Key
Start-Sleep -Seconds 2
$output = manage-bde -protectors -get C:
$output | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"

