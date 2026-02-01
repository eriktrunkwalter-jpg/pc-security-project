# === ANONYMITY PROTOCOL AUDIT ===
$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- ANONYMITY PROTOCOL STATUS ---" -ForegroundColor Cyan

function Audit-Setting($name, $status, $details) {
    if ($status -eq "SECURE") {
        Write-Host "[$name] SECURE" -ForegroundColor Green
        Write-Host "   -> $details"
    } elseif ($status -eq "WARNING") {
        Write-Host "[$name] WARNING" -ForegroundColor Yellow
        Write-Host "   -> $details"
    } else {
        Write-Host "[$name] CRITICAL" -ForegroundColor Red
        Write-Host "   -> $details"
    }
}

# 1. TELEMETRY
$telemetry = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
if ($telemetry.AllowTelemetry -eq 0) {
    Audit-Setting "Telemetry" "SECURE" "Disabled (Security Level only)."
} else {
    Audit-Setting "Telemetry" "WARNING" "Might be sending data. Enforcing Disable..."
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
}

# 2. ADVERTISING ID
$advId = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -ErrorAction SilentlyContinue
if ($advId.Enabled -eq 0) {
    Audit-Setting "Advertising ID" "SECURE" "Disabled."
} else {
    Audit-Setting "Advertising ID" "WARNING" "Enabled. Disabling..."
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force
}

# 3. ACTIVITY FEED (Timeline)
$timeline = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -ErrorAction SilentlyContinue
if ($timeline.PublishUserActivities -eq 0) {
    Audit-Setting "Activity Feed" "SECURE" "Disabled (No history sent to MS)."
} else {
    Audit-Setting "Activity Feed" "WARNING" "Enabled. Disabling..."
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord -Force
}

# 4. LOCATION SERVICES
$location = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -ErrorAction SilentlyContinue
# This is tricky via registry, checking Service instead
$lfsvc = Get-Service "lfsvc" -ErrorAction SilentlyContinue
if ($lfsvc.StartType -eq "Disabled") {
    Audit-Setting "Location Service" "SECURE" "Service Disabled."
} else {
    Audit-Setting "Location Service" "WARNING" "Service is $($lfsvc.StartType). Disabling..."
    Stop-Service "lfsvc" -Force -ErrorAction SilentlyContinue
    Set-Service "lfsvc" -StartupType Disabled
}

# 5. DIAG TRACK SERVICE
$diag = Get-Service "DiagTrack" -ErrorAction SilentlyContinue
if ($diag.StartType -eq "Disabled") {
    Audit-Setting "DiagTrack" "SECURE" "Disabled."
} else {
    Audit-Setting "DiagTrack" "WARNING" "Running. Disabling..."
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled
}

# 6. DNS CONFIGURATION
$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses.Count -gt 0 }
if ($dns) {
    $servers = $dns.ServerAddresses -join ", "
    if ($servers -like "1.1.1.1*" -or $servers -like "1.0.0.1*" -or $servers -like "9.9.9.9*") {
        Audit-Setting "DNS Privacy" "SECURE" "Using Secure DNS ($servers)."
    } elseif ($servers -like "8.8.8.8*" -or $servers -like "8.8.4.4*") {
        Audit-Setting "DNS Privacy" "WARNING" "Using Google DNS ($servers). Logs exist."
    } else {
        Audit-Setting "DNS Privacy" "WARNING" "Using Standard/ISP DNS ($servers). Not anonymous."
        Write-Host "   -> [ACTION] Suggest switching to Cloudflare (1.1.1.1) or Quad9 (9.9.9.9)."
    }
} else {
    Audit-Setting "DNS Privacy" "WARNING" "Could not detect DNS."
}

# 7. SPOTIFY EXCEPTION VERIFICATION
# Ensure we didn't block Spotify in our zeal for anonymity
$firewall = Get-NetFirewallRule -DisplayName "Allow Spotify Final" -ErrorAction SilentlyContinue
if ($firewall.Enabled -eq "True" -and $firewall.Action -eq "Allow") {
    Audit-Setting "Spotify Anonymity" "SECURE" "Traffic allowed but isolated via Firewall Rule."
} else {
    Audit-Setting "Spotify Anonymity" "WARNING" "Firewall rule missing. Re-creating..."
    New-NetFirewallRule -DisplayName "Allow Spotify Final" -Direction Outbound -Program "$env:APPDATA\Spotify\Spotify.exe" -Action Allow -Profile Any -Force
}

Write-Host "--- AUDIT COMPLETE ---" -ForegroundColor Magenta
