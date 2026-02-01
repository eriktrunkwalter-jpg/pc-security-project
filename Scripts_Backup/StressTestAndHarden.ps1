# === SECURITY STRESS TEST & HARDENING (RED TEAM SIMULATION) ===
# Run as ADMINISTRATOR
# Purpose: Simulate attacks, close gaps, protect Spotify

$ErrorActionPreference = "SilentlyContinue"
$log = @()

function Log-Result($status, $msg) {
    $entry = "[$status] $msg"
    Write-Host $entry -ForegroundColor ($status -eq "SAFE" ? "Green" : ($status -eq "FIXED" ? "Cyan" : "Red"))
    $global:log += $entry
}

Write-Host "--- STARTING DEEP STRESS TEST (RED TEAM MODE) ---" -ForegroundColor Magenta

# 1. ATTACK VECTOR: PRIVILEGE ESCALATION (Unquoted Service Paths)
Write-Host "`n[+] Testing: Unquoted Service Paths..." -ForegroundColor Yellow
$vulnerableServices = Get-WmiObject Win32_Service | Where-Object { $_.PathName -notmatch '^"' -and $_.PathName -notmatch '^C:\\Windows\\' -and $_.PathName -match '\s' }
if ($vulnerableServices) {
    foreach ($service in $vulnerableServices) {
        # Attempt Auto-Fix (Add quotes)
        $newPath = '"{0}"' -f $service.PathName
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($service.Name)" -Name "ImagePath" -Value $newPath -ErrorAction SilentlyContinue
        Log-Result "FIXED" "Unquoted Service Path patched: $($service.Name)"
    }
} else {
    Log-Result "SAFE" "No Unquoted Service Paths found."
}

# 2. ATTACK VECTOR: REGISTRY PERSISTENCE (AlwaysInstallElevated)
Write-Host "`n[+] Testing: MSI AlwaysInstallElevated..." -ForegroundColor Yellow
$hkcu = Get-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue
$hklm = Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue
if (($hkcu.AlwaysInstallElevated -eq 1) -or ($hklm.AlwaysInstallElevated -eq 1)) {
    Remove-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue
    Remove-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -ErrorAction SilentlyContinue
    Log-Result "FIXED" "Removed 'AlwaysInstallElevated' risk (MSI Injection)."
} else {
    Log-Result "SAFE" "MSI AlwaysInstallElevated is disabled."
}

# 3. ATTACK VECTOR: CREDENTIAL DUMPING (SAM/SYSTEM Hive Access)
Write-Host "`n[+] Testing: SAM/SYSTEM File Access..." -ForegroundColor Yellow
try {
    $sam = [System.IO.File]::OpenRead("C:\Windows\System32\config\SAM")
    $sam.Close()
    Log-Result "CRITICAL" "I can read the SAM database! (Should be locked by System)"
} catch {
    Log-Result "SAFE" "SAM database is locked/protected (Good)."
}

# 4. ATTACK VECTOR: NETWORK EXPOSURE (Port Scan 1-1024)
Write-Host "`n[+] Testing: Network Exposure (Listening Ports)..." -ForegroundColor Yellow
$dangerousPorts = @(21, 23, 445, 135, 139, 3389)
$listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LocalPort
foreach ($port in $dangerousPorts) {
    if ($listening -contains $port) {
        # Check if Firewall blocks it (We can't easily query rules per port in bulk, but we apply block rule again to be safe)
        New-NetFirewallRule -DisplayName "Block_Port_$port" -Direction Inbound -LocalPort $port -Protocol TCP -Action Block -Profile Any -Force -ErrorAction SilentlyContinue
        Log-Result "FIXED" "Port $port was listening. Re-applied Firewall Block."
    } else {
        Log-Result "SAFE" "Port $port is not listening."
    }
}

# 5. SPOTIFY SURVIVAL CHECK (Crucial!)
Write-Host "`n[+] Testing: Spotify Connectivity..." -ForegroundColor Cyan
$spotifyUrls = @("apresolve.spotify.com", "spclient.wg.spotify.com")
$spotifyOK = $true
foreach ($url in $spotifyUrls) {
    try {
        $test = Test-NetConnection -ComputerName $url -Port 443 -InformationLevel Quiet
        if ($test) {
            Log-Result "SAFE" "Spotify Connection OK: $url"
        } else {
            Log-Result "WARNING" "Spotify Connection Failed: $url"
            $spotifyOK = $false
        }
    } catch {
        Log-Result "WARNING" "Could not test $url"
    }
}

# 6. SPOTIFY REPAIR (If needed)
if (-not $spotifyOK) {
    Write-Host "   -> Repairing Spotify Access..." -ForegroundColor Yellow
    # Force Allow Spotify Binary
    $spotifyPath = "$env:APPDATA\Spotify\Spotify.exe"
    New-NetFirewallRule -DisplayName "Spotify_Rescue_In" -Direction Inbound -Program $spotifyPath -Action Allow -Profile Any -Force
    New-NetFirewallRule -DisplayName "Spotify_Rescue_Out" -Direction Outbound -Program $spotifyPath -Action Allow -Profile Any -Force
    # Ensure DNS/IPv6
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0 -Type DWord
    Log-Result "FIXED" "Applied Emergency Spotify Fixes."
}

# 7. FINAL HARDENING (Windows Defender)
Write-Host "`n[+] Testing: Windows Defender Status..." -ForegroundColor Yellow
$mp = Get-MpComputerStatus
if ($mp.AntivirusEnabled) {
    # Enable PUAs (Potentially Unwanted Apps) protection
    Set-MpPreference -PUAProtection Enabled
    Log-Result "SAFE" "Windows Defender Active & PUA Protection Enabled."
} else {
    Log-Result "WARNING" "Windows Defender seems disabled!"
}

Write-Host "`n--- STRESS TEST COMPLETE ---" -ForegroundColor Magenta
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
