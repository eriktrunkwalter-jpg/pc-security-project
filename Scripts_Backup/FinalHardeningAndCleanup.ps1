# === FINAL HARDENING & FORENSIC CLEANUP ===
# Run as ADMINISTRATOR
# Purpose: Deep system cleaning, removing usage traces, and ensuring security integrity.

Write-Host "--- STARTING FINAL HARDENING & CLEANUP ---" -ForegroundColor Cyan

# 1. FORENSIC CLEANUP
Write-Host "[+] Performing Forensic Cleanup..." -ForegroundColor Green

# Clear Event Logs (Privacy/Anonymity)
$logs = Get-EventLog -List
foreach ($log in $logs) {
    try {
        Clear-EventLog -LogName $log.Log -ErrorAction SilentlyContinue
        Write-Host "   -> Cleared Log: $($log.Log)" -ForegroundColor Gray
    } catch {}
}

# Clear PowerShell History
Write-Host "   -> Clearing PowerShell History..." -ForegroundColor Gray
Clear-History
$historyPath = (Get-PSReadlineOption).HistorySavePath
if (Test-Path $historyPath) { Remove-Item $historyPath -Force -ErrorAction SilentlyContinue }

# Clear Temp Files
Write-Host "   -> Clearing Temp Files..." -ForegroundColor Gray
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clear Prefetch (Optimization/Privacy)
Write-Host "   -> Clearing Prefetch..." -ForegroundColor Gray
Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

# 2. SYSTEM INTEGRITY & SHADOW COPIES
Write-Host "[+] Securing System Integrity..." -ForegroundColor Green

# Delete Shadow Copies (Remove potential unencrypted snapshots)
Write-Host "   -> Deleting Shadow Copies..." -ForegroundColor Gray
vssadmin delete shadows /all /quiet

# 3. AUTOSTART VERIFICATION
Write-Host "[+] Verifying Autostart Cleanup..." -ForegroundColor Green
$regPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $regPaths) {
    $keys = Get-ItemProperty $path -ErrorAction SilentlyContinue
    foreach ($property in $keys.PSObject.Properties) {
        if ($property.Name -match "Teams" -or $property.Name -match "Proton") {
            Remove-ItemProperty -Path $path -Name $property.Name -Force -ErrorAction SilentlyContinue
            Write-Host "   -> REMOVED residual autostart: $($property.Name)" -ForegroundColor Yellow
        }
    }
}

# 4. PATH SANITIZATION
Write-Host "[+] Sanitizing Environment PATH..." -ForegroundColor Green
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPathParts = @()
foreach ($part in $currentPath -split ";") {
    if ($part -and (Test-Path $part)) {
        $newPathParts += $part
    }
}
$newPath = $newPathParts -join ";"
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
Write-Host "   -> PATH sanitized (removed invalid entries)." -ForegroundColor Gray

# 5. SPOTIFY CHECK
Write-Host "[+] Final Spotify Connectivity Check..." -ForegroundColor Green
if (Get-NetFirewallRule -DisplayName "Spotify_In_Allow" -ErrorAction SilentlyContinue) {
    Write-Host "   -> Spotify Firewall Rule: ACTIVE" -ForegroundColor Green
} else {
    Write-Host "   -> Spotify Firewall Rule: MISSING (Re-adding...)" -ForegroundColor Red
    $spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"
    if (Test-Path $spotifyPath) {
        New-NetFirewallRule -DisplayName "Spotify_In_Allow" -Direction Inbound -Program $spotifyPath -Action Allow -Profile Any -Force
        New-NetFirewallRule -DisplayName "Spotify_Out_Allow" -Direction Outbound -Program $spotifyPath -Action Allow -Profile Any -Force
    }
}

Write-Host "--- ALL TASKS COMPLETED. SYSTEM READY FOR REBOOT ---" -ForegroundColor Cyan
