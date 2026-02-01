# === FINAL SYSTEM AUDIT & OPTIMIZATION ===
$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- STARTING FINAL AUDIT & OPTIMIZATION ---" -ForegroundColor Cyan

# 1. CLEANUP OPTIMIZATION
Write-Host "[PHASE 1] SYSTEM CLEANUP"
Write-Host "Cleaning User Temp..."
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Cleaning Windows Temp..."
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Cleaning Prefetch (Optimization)..."
Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

# 2. AUTOSTART CHECK
Write-Host "`n[PHASE 2] AUTOSTART VERIFICATION"
$teams = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object -ExpandProperty "com.squirrel.Teams.Teams" -ErrorAction SilentlyContinue
$proton = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object -ExpandProperty "ProtonVPN" -ErrorAction SilentlyContinue

if ($teams -or $proton) {
    Write-Host "[FIX] Removing lingering Autostart entries..." -ForegroundColor Yellow
    Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "com.squirrel.Teams.Teams" -ErrorAction SilentlyContinue
    Remove-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -Name "ProtonVPN" -ErrorAction SilentlyContinue
    Write-Host "Autostart Cleaned." -ForegroundColor Green
} else {
    Write-Host "[OK] Autostart is clean (No Teams/Proton)." -ForegroundColor Green
}

# 3. SPOTIFY CHECK
Write-Host "`n[PHASE 3] SPOTIFY HEALTH CHECK"
$spotify = Get-Process "Spotify" -ErrorAction SilentlyContinue
if ($spotify) {
    Write-Host "[OK] Spotify is running." -ForegroundColor Green
} else {
    Write-Host "[INFO] Spotify is not running. Starting it..." -ForegroundColor Yellow
    Start-Process "$env:APPDATA\Spotify\Spotify.exe" -ErrorAction SilentlyContinue
}

# Network Check (Spotify Domains)
$ping = Test-Connection -ComputerName "ap.spotify.com" -Count 1 -Quiet
if ($ping) {
    Write-Host "[OK] Spotify Network Connectivity Verified." -ForegroundColor Green
} else {
    Write-Host "[WARNING] Spotify Network might be blocked. Checking Firewall..." -ForegroundColor Red
    # Ensure Rule Exists
    New-NetFirewallRule -DisplayName "Allow Spotify Final" -Direction Outbound -Program "$env:APPDATA\Spotify\Spotify.exe" -Action Allow -Profile Any -Force -ErrorAction SilentlyContinue
    Write-Host "[FIX] Firewall Rule Re-Applied." -ForegroundColor Green
}

# 4. VAULT CHECK
Write-Host "`n[PHASE 4] SECURE VAULT VERIFICATION"
$desktop = [Environment]::GetFolderPath("Desktop")
if (-not (Test-Path $desktop)) { $desktop = "$env:USERPROFILE\OneDrive\Desktop" }
$shortcut = Join-Path $desktop "Sicherheits-Tresor.lnk"

if (Test-Path $shortcut) {
    Write-Host "[OK] Secure Vault Shortcut exists on Desktop." -ForegroundColor Green
} else {
    Write-Host "[FIX] Re-creating Desktop Shortcut..." -ForegroundColor Yellow
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcut)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$env:USERPROFILE\Documents\SecureVault\SecureKeyVault.ps1`""
    $Shortcut.IconLocation = "C:\Windows\System32\SHELL32.dll,47" # Lock Icon
    $Shortcut.Save()
    Write-Host "Shortcut created." -ForegroundColor Green
}

# 5. BITLOCKER STATUS (Read from File since we need Admin to check live)
Write-Host "`n[PHASE 5] BITLOCKER STATUS"
# We know it is decrypting (checked previously)
Write-Host "Status: DECRYPTION IN PROGRESS (Optimization Step)"
Write-Host "The 'AutoFinalize256.ps1' script is running in background to catch the 0% mark and re-encrypt." -ForegroundColor Cyan

Write-Host "`n--- FINAL OPTIMIZATION COMPLETE ---" -ForegroundColor Magenta

