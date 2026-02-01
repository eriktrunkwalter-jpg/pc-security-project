# EnableBitLockerFinal.ps1
$Pin = "ErikUser13092002!"
$Log = "$env:USERPROFILE\Documents\BitLockerFinalLog.txt"

function Log { param($m) Add-Content $Log "[$((Get-Date).ToString('HH:mm:ss'))] $m"; Write-Host $m }

Log "Configuring BitLocker (No TPM Mode)..."

# 1. Force GPO Registry Settings (Allow Password/No TPM)
$key = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (!(Test-Path $key)) { New-Item $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name "UseEnhancedPin" -Value 1 -Type DWord
Set-ItemProperty -Path $key -Name "AllowMbaWithoutTpm" -Value 1 -Type DWord
Set-ItemProperty -Path $key -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord # Legacy name check
Log "Registry policies set."

# 2. Add Password Protector via manage-bde
Log "Adding Password Protector..."
# We use Start-Process to avoid shell parsing issues with "!"
$proc = Start-Process -FilePath "manage-bde.exe" -ArgumentList "-protectors","-add","C:","-pw","$Pin" -PassThru -Wait -NoNewWindow
if ($proc.ExitCode -eq 0) {
    Log "Password protector added successfully."
} else {
    Log "Failed to add password protector. Exit Code: $($proc.ExitCode)"
    # Fallback: try enabling directly
}

# 3. Enable BitLocker with Recovery Password
Log "Enabling BitLocker..."
$proc2 = Start-Process -FilePath "manage-bde.exe" -ArgumentList "-on","C:","-rp","-skiphardwaretest" -PassThru -Wait -NoNewWindow
if ($proc2.ExitCode -eq 0) {
    Log "BitLocker encryption started."
} else {
    Log "Failed to enable BitLocker. Exit Code: $($proc2.ExitCode)"
}

# 4. Get Recovery Key
Log "Retrieving Recovery Key..."
Start-Sleep -Seconds 3
$output = manage-bde -protectors -get C:
$output | Out-File "$env:USERPROFILE\Documents\BitLocker_Recovery_Key.txt"
Log "Recovery key saved to Documents."
Log "Done."

