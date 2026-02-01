$path = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
Remove-Item -Path $path -Recurse -Force
New-Item -Path $path -Force
Set-ItemProperty -Path $path -Name "UseAdvancedStartup" -Value 1 -Type DWord
Set-ItemProperty -Path $path -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord
# Restart BDESVC
Restart-Service BDESVC -Force
