# Remove Teams and Proton VPN from Autostart
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$targets = @("Teams", "Proton VPN")

Write-Host "--- REMOVING AUTOSTART ENTRIES ---" -ForegroundColor Cyan

foreach ($target in $targets) {
    $exists = Get-ItemProperty -Path $registryPath -Name $target -ErrorAction SilentlyContinue
    if ($exists) {
        Remove-ItemProperty -Path $registryPath -Name $target -ErrorAction SilentlyContinue
        Write-Host "[+] Removed '$target' from Autostart." -ForegroundColor Green
    } else {
        Write-Host "[-] '$target' not found in Autostart (Registry)." -ForegroundColor Yellow
    }
}

# Double check specific "Teams" entry which sometimes appears as "com.squirrel.Teams.Teams"
$squirrel = "com.squirrel.Teams.Teams"
$existsSquirrel = Get-ItemProperty -Path $registryPath -Name $squirrel -ErrorAction SilentlyContinue
if ($existsSquirrel) {
    Remove-ItemProperty -Path $registryPath -Name $squirrel -ErrorAction SilentlyContinue
    Write-Host "[+] Removed '$squirrel' from Autostart." -ForegroundColor Green
}

Write-Host "--- DONE ---" -ForegroundColor Cyan
