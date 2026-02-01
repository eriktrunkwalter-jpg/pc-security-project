# === EXTREME RED TEAM / FORENSIC AUDIT (STATE-LEVEL SIMULATION) ===
# Purpose: Simulate Government/Police Forensics & APT Tactics
# Scope: Digital Footprint, Encryption, Advanced Persistence, Memory Safety

$ErrorActionPreference = "SilentlyContinue"

function Log-Audit($category, $status, $msg) {
    $color = if ($status -eq "SECURE") { "Green" } elseif ($status -eq "CRITICAL") { "Red" } else { "Yellow" }
    Write-Host "[$category] $status" -ForegroundColor $color
    Write-Host "   -> $msg" -ForegroundColor Gray
}

Write-Host "--- STARTING STATE-LEVEL FORENSIC AUDIT ---" -ForegroundColor Magenta

# 1. PHYSICAL SEIZURE & COLD BOOT (The "Police" Scenario)
# If they take your laptop, can they read the disk?
Write-Host "`n[PHASE 1] PHYSICAL ACCESS & ENCRYPTION" -ForegroundColor Cyan
$bitlocker = Get-BitLockerVolume -MountPoint "C:"
if ($bitlocker.ProtectionStatus -eq "On") {
    Log-Audit "Disk Encryption" "SECURE" "BitLocker is ACTIVE. Cold storage data is safe."
} else {
    Log-Audit "Disk Encryption" "CRITICAL" "BitLocker is OFF. Anyone with physical access can mount your drive and read EVERYTHING."
}

# 2. DIGITAL FORENSICS (The "Trail" You Left)
# What can an investigator see about your past activity?
Write-Host "`n[PHASE 2] DIGITAL ARTIFACTS & HISTORY" -ForegroundColor Cyan

# 2.1 PowerShell History
$psHistoryPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if (Test-Path $psHistoryPath) {
    $history = Get-Content $psHistoryPath
    if ($history.Count -gt 0) {
        Log-Audit "Command History" "CRITICAL" "Found $($history.Count) past commands in plain text. (Contains potential passwords/IPs)."
    }
} else {
    Log-Audit "Command History" "SECURE" "No PowerShell history found."
}

# 2.2 Shadow Copies (Time Machine)
# Can they recover deleted files from VSS?
$shadows = Get-CimInstance Win32_ShadowCopy
if ($shadows) {
    Log-Audit "Deleted File Recovery" "CRITICAL" "Found $($shadows.Count) Shadow Copies. Deleted files can be recovered from these snapshots."
} else {
    Log-Audit "Deleted File Recovery" "SECURE" "No Volume Shadow Copies found."
}

# 2.3 ShellBags / JumpLists (User Activity)
$recent = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent" 
if ($recent.Count -gt 5) {
    Log-Audit "User Activity" "WARNING" "Found $($recent.Count) Recent Document links. Your activity trail is visible."
}

# 3. ADVANCED PERSISTENCE (APT Tactics)
# Methods used by nation-state hackers to stay hidden
Write-Host "`n[PHASE 3] APT PERSISTENCE VECTORS" -ForegroundColor Cyan

# 3.1 WMI Event Consumers (Fileless Persistence)
$wmi = Get-WmiObject -Namespace root\subscription -Class __EventConsumer
if ($wmi) {
    Log-Audit "WMI Persistence" "WARNING" "Found WMI Event Consumers (Check if malicious)."
} else {
    Log-Audit "WMI Persistence" "SECURE" "No WMI Event Consumers found (Clean)."
}

# 3.2 DLL Hijacking Potential (Path Variables)
$pathVars = $env:Path -split ";"
$writablePaths = @()
foreach ($path in $pathVars) {
    # Check if we can write to system paths
    try { [IO.File]::Create("$path\test_hijack.dll").Close(); Remove-Item "$path\test_hijack.dll"; $writablePaths += $path } catch {}
}
if ($writablePaths) {
    Log-Audit "DLL Hijacking" "CRITICAL" "Path variable contains writable directories: $($writablePaths -join ', ')"
} else {
    Log-Audit "DLL Hijacking" "SECURE" "System PATH is secure."
}

# 4. EXFILTRATION (Getting Data Out)
# Can we bypass the Firewall via DNS Tunneling?
Write-Host "`n[PHASE 4] DATA EXFILTRATION" -ForegroundColor Cyan
try {
    $dns = Resolve-DnsName -Name "google.com" -Type A
    if ($dns) {
        Log-Audit "DNS Tunneling" "WARNING" "DNS resolution allowed. Data can be exfiltrated via DNS queries (Slow but stealthy)."
    }
} catch {
    Log-Audit "DNS Tunneling" "SECURE" "DNS resolution failed (High Security)."
}

# 5. MEMORY SAFETY
Write-Host "`n[PHASE 5] KERNEL & MEMORY" -ForegroundColor Cyan
$os = Get-WmiObject Win32_OperatingSystem
if ($os.DataExecutionPrevention_Available) {
    Log-Audit "Memory Protection" "SECURE" "DEP (Data Execution Prevention) is Active."
} else {
    Log-Audit "Memory Protection" "CRITICAL" "DEP is Missing!"
}

Write-Host "`n--- AUDIT COMPLETE ---" -ForegroundColor Magenta
