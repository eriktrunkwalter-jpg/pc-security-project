$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$Shortcut = $WshShell.CreateShortcut("$DesktopPath\SecureKeyVault.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$env:USERPROFILE\Documents\SecureVault\SecureKeyVault.ps1"""
$Shortcut.Description = "Sicherheits-Tresor"
$Shortcut.IconLocation = "shell32.dll,47"
$Shortcut.Save()
Write-Host "Shortcut created at: $DesktopPath"

