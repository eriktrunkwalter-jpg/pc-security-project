$path = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
if (!(Test-Path $path)) { New-Item -Path $path -Force }
Set-ItemProperty -Path $path -Name "UseAdvancedStartup" -Value 1 -Type DWord
Set-ItemProperty -Path $path -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord
Set-ItemProperty -Path $path -Name "UseTPM" -Value 0 -Type DWord
Set-ItemProperty -Path $path -Name "UseTPMPIN" -Value 0 -Type DWord
Set-ItemProperty -Path $path -Name "UseTPMKey" -Value 0 -Type DWord
Set-ItemProperty -Path $path -Name "UseTPMKeyPIN" -Value 0 -Type DWord

# Restart BDESVC
Restart-Service BDESVC -Force
