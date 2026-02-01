# RetryBitLocker.ps1
$ErrorActionPreference = "Continue"
$LogFile = "$env:USERPROFILE\Documents\BitLockerLog.txt"
$UserPin = "ErikUser13092002!"

function Log {
    param($msg)
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

Log "Starting BitLocker Setup..."

# 1. Check Admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Log "ERROR: Not running as Admin!"
    exit
}

# 2. Check TPM
try {
    $tpm = Get-Tpm
    Log "TPM Present: $($tpm.TpmPresent), Ready: $($tpm.TpmReady)"
} catch {
    Log "Error checking TPM: $($_.Exception.Message)"
}

# 3. Enable GPO for Enhanced PINs (Critical for special chars in PIN)
try {
    $key = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
    if (!(Test-Path $key)) { New-Item $key -Force | Out-Null }
    Set-ItemProperty -Path $key -Name "UseEnhancedPin" -Value 1 -Type DWord
    Set-ItemProperty -Path $key -Name "AllowMbaWithoutTpm" -Value 1 -Type DWord
    Log "GPO 'UseEnhancedPin' enabled."
} catch {
    Log "Error setting GPO: $($_.Exception.Message)"
}

# 4. Check Volume Status
try {
    $vol = Get-BitLockerVolume -MountPoint "C:"
    Log "Current Status: $($vol.ProtectionStatus)"
    
    if ($vol.ProtectionStatus -eq "Off") {
        Log "Attempting to enable BitLocker on C:..."
        # Try TPM+PIN first
        try {
            Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -SkipHardwareTest -RecoveryPasswordProtector -TpmAndPinProtector -Pin $UserPin -ErrorAction Stop
            Log "Enable-BitLocker command sent (TPM+PIN)."
        } catch {
            Log "Failed TPM+PIN: $($_.Exception.Message). Trying Password only (Software)..."
            try {
                 Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -SkipHardwareTest -RecoveryPasswordProtector -PasswordProtector -Password $UserPin
                 Log "Enable-BitLocker command sent (Password)."
            } catch {
                Log "Failed Password method too: $($_.Exception.Message)"
            }
        }
    } else {
        Log "BitLocker is already On. Ensuring Protectors..."
        # Add PIN if missing
        if (!($vol.KeyProtector | Where-Object { $_.KeyProtectorType -match "Pin" })) {
             try {
                Add-BitLockerKeyProtector -MountPoint "C:" -TpmAndPinProtector -Pin $UserPin
                Log "Added TPM+PIN protector."
             } catch {
                Log "Failed to add PIN: $($_.Exception.Message)"
             }
        }
    }
} catch {
    Log "Error accessing BitLocker Volume: $($_.Exception.Message)"
}

# 5. Retrieve Recovery Key
try {
    $vol = Get-BitLockerVolume -MountPoint "C:"
    $key = $vol.KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }
    if ($key) {
        Log "SUCCESS. Recovery Key Found."
        Log "ID: $($key.KeyProtectorId)"
        Log "KEY: $($key.RecoveryPassword)"
        
        # Save explicit key file for user
        "BitLocker Recovery Key for C:`r`nIdentifier: $($key.KeyProtectorId)`r`nRecovery Key: $($key.RecoveryPassword)" | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
    } else {
        Log "WARNING: No Recovery Key protector found!"
    }
} catch {
    Log "Error retrieving key: $($_.Exception.Message)"
}

Log "Done."

