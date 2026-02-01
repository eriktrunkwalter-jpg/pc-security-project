# === ULTIMATE RED TEAM SIMULATION (MAXIMUM AGGRESSION) ===
# Purpose: Test system resilience against a simulated advanced attacker
# Target: Local Endpoint (Self)
# Rules: No actual damage, no data exfiltration, safe checks only.

$ErrorActionPreference = "SilentlyContinue"
$report = @()

function Log-Attack($name, $result, $detail) {
    $color = if ($result -eq "BLOCKED/SAFE") { "Green" } elseif ($result -eq "VULNERABLE") { "Red" } else { "Yellow" }
    Write-Host "[$name] $result" -ForegroundColor $color
    if ($detail) { Write-Host "   -> $detail" -ForegroundColor Gray }
}

Write-Host "--- INITIALIZING CYBER KILL CHAIN SIMULATION ---" -ForegroundColor Magenta

# PHASE 1: RECONNAISSANCE (Local)
Write-Host "`n[PHASE 1] RECONNAISSANCE" -ForegroundColor Cyan

# 1.1 Clipboard Monitoring
# Attackers often watch clipboard for copied passwords
Add-Type -AssemblyName System.Windows.Forms
$clipboard = [System.Windows.Forms.Clipboard]::GetText()
if ($clipboard) {
    Log-Attack "Clipboard Sniffing" "VULNERABLE" "I can read your clipboard: '$($clipboard.Substring(0, [math]::Min($clipboard.Length, 20)))...'"
} else {
    Log-Attack "Clipboard Sniffing" "SAFE" "Clipboard is empty or inaccessible."
}

# 1.2 Network Enumeration (The "Spotify Leak" Check)
# Can I see other devices despite the hardening?
$arp = Get-NetNeighbor -AddressFamily IPv4 | Where-Object { $_.State -eq "Reachable" }
if ($arp.Count -gt 1) {
    Log-Attack "Network Visibility" "WARNING" "I can still see $($arp.Count) neighbors (Gateway/Router is normal)."
} else {
    Log-Attack "Network Visibility" "BLOCKED/SAFE" "Network is dark. No neighbors visible."
}

# PHASE 2: WEAPONIZATION & DELIVERY
Write-Host "`n[PHASE 2] PERSISTENCE & PRIVILEGE" -ForegroundColor Cyan

# 2.1 Persistence (Registry Run Key)
$testKey = "TraeRedTeamSim"
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $testKey -Value "cmd.exe /c echo hacked" -ErrorAction Stop
    Log-Attack "Registry Persistence" "VULNERABLE" "I successfully wrote to the Startup Registry."
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $testKey
} catch {
    Log-Attack "Registry Persistence" "BLOCKED/SAFE" "Registry write failed (Access Denied)."
}

# 2.2 Service Creation (Needs Admin)
try {
    New-Service -Name "TraeMalware" -BinaryPathName "C:\Windows\System32\calc.exe" -ErrorAction Stop | Out-Null
    Log-Attack "Service Injection" "VULNERABLE" "I created a malicious system service."
    Remove-Service "TraeMalware"
} catch {
    Log-Attack "Service Injection" "BLOCKED/SAFE" "Service creation denied."
}

# PHASE 3: EXPLOITATION & CREDENTIAL ACCESS
Write-Host "`n[PHASE 3] DATA & CREDENTIAL THEFT" -ForegroundColor Cyan

# 3.1 Browser Data Theft (Chrome/Brave/Edge)
$browsers = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data",
    "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Login Data",
    "$env:APPDATA\Mozilla\Firefox\Profiles"
)
foreach ($path in $browsers) {
    if (Test-Path $path) {
        # Try to copy it (Simulate theft)
        try {
            Copy-Item $path -Destination "$env:TEMP\stolen_creds" -ErrorAction Stop
            Log-Attack "Browser Theft ($([IO.Path]::GetFileName($path)))" "VULNERABLE" "I copied your Password Database to TEMP."
            Remove-Item "$env:TEMP\stolen_creds" -Force
        } catch {
            Log-Attack "Browser Theft" "BLOCKED/SAFE" "Could not access browser file."
        }
    }
}

# 3.2 WiFi Password Extraction
try {
    $profiles = netsh wlan show profiles | Select-String "All User Profile"
    if ($profiles) {
        Log-Attack "WiFi Harvesting" "VULNERABLE" "I can list all your saved WiFi networks."
        # Note: Getting the cleartext key requires admin, checking that now
        $testProfile = ($profiles[0] -split ":")[1].Trim()
        $key = netsh wlan show profile name="$testProfile" key=clear | Select-String "Key Content"
        if ($key) {
             Log-Attack "WiFi Key Dump" "CRITICAL" "I extracted the WiFi password for '$testProfile'."
        }
    }
} catch {
    Log-Attack "WiFi Harvesting" "SAFE" "WLAN Command failed."
}

# PHASE 4: APP VULNERABILITIES
Write-Host "`n[PHASE 4] APPLICATION WEAKNESSES" -ForegroundColor Cyan

# 4.1 Spotify Piggybacking
# Can I use Spotify's ports for my own data?
try {
    # Try to bind to Spotify's UDP port 5353
    $listener = [System.Net.Sockets.UdpClient]::new(5353)
    Log-Attack "Port Hijacking (5353)" "VULNERABLE" "I successfully bound to the Spotify Discovery Port."
    $listener.Close()
} catch {
    Log-Attack "Port Hijacking (5353)" "BLOCKED/SAFE" "Port 5353 is locked or in use (Good)."
}

# 4.2 Installed Software Check (Basic)
$apps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion
$riskApps = $apps | Where-Object { $_.DisplayName -match "Java|Flash|Adobe Reader|QuickTime" }
if ($riskApps) {
    foreach ($app in $riskApps) {
        Log-Attack "Legacy Software" "WARNING" "Found risky app: $($app.DisplayName) ($($app.DisplayVersion))"
    }
} else {
    Log-Attack "Legacy Software" "SAFE" "No obvious legacy bloatware found."
}

Write-Host "`n--- HACKER SIMULATION COMPLETE ---" -ForegroundColor Magenta
