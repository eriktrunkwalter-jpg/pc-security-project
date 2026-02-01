# === ULTIMA RATIO RED TEAM AUDIT (BRUTAL MODE) ===
# Purpose: The FINAL, UNFORGIVING test of system security.
# Scenarios: Physical Seizure, Advanced Forensics, Kernel Exploits, Network Isolation.
$ErrorActionPreference = "SilentlyContinue"

function Log-Audit($category, $status, $msg) {
    $color = if ($status -eq "SECURE") { "Green" } elseif ($status -eq "CRITICAL") { "Red" } else { "Yellow" }
    Write-Host "[$category] $status" -ForegroundColor $color
    Write-Host "   -> $msg" -ForegroundColor Gray
}

Write-Host "--- ULTIMA RATIO: BRUTAL SYSTEM AUDIT ---" -ForegroundColor Magenta

# 1. ENCRYPTION STRENGTH (Not just "On", but "HOW STRONG?")
Write-Host "`n[PHASE 1] CRYPTOGRAPHIC INTEGRITY" -ForegroundColor Cyan
$bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue

# Helper to check status if cmdlet fails or returns Off (sometimes needs elevation)
$isEncrypted = $false
$method = "Unknown"

if ($bitlocker.ProtectionStatus -eq "On") {
    $isEncrypted = $true
    $method = $bitlocker.EncryptionMethod
} else {
    # Fallback: manage-bde parsing
    # First try cached admin status if available
    if (Test-Path "$env:USERPROFILE\Documents\trae_projects\pc\bl_status.txt") {
        $bdeOutput = Get-Content "$env:USERPROFILE\Documents\trae_projects\pc\bl_status.txt" | Out-String
    } else {
        $bdeOutput = manage-bde -status C: | Out-String
    }
    
    if ($bdeOutput -match "Schutz ist aktiviert" -or $bdeOutput -match "Protection On") {
        $isEncrypted = $true
        if ($bdeOutput -match "XTS-AES 256") { $method = "XtsAes256" }
        elseif ($bdeOutput -match "XTS-AES 128") { $method = "XtsAes128" }
        else { $method = "Standard/Unknown" }
    }
}

if ($isEncrypted) {
    if ($method -like "*XtsAes256*") {
        Log-Audit "BitLocker Strength" "SECURE" "Algorithm is XTS-AES 256 (Military Grade)."
    } else {
        Log-Audit "BitLocker Strength" "WARNING" "Algorithm is $method. Secure, but XTS-AES 256 is stronger."
    }
} else {
    Log-Audit "BitLocker" "CRITICAL" "DRIVE IS UNENCRYPTED. GAME OVER."
}

# 2. ASR (ATTACK SURFACE REDUCTION) VERIFICATION
Write-Host "`n[PHASE 2] ATTACK SURFACE (ASR) CHECK" -ForegroundColor Cyan
$mp = Get-MpPreference
$asrRules = $mp.AttackSurfaceReductionRules_Ids
$asrActions = $mp.AttackSurfaceReductionRules_Actions
if ($asrRules) {
    Log-Audit "ASR Rules" "SECURE" "ASR Rules are loaded in Defender."
    # Check for specific "Block Office Child Processes" GUID
    if ($asrRules -contains "d4f940ab-401b-4efc-aadc-ad5f3c50688a") {
         Log-Audit "Office Hardening" "SECURE" "Office apps blocked from creating child processes."
    }
} else {
    Log-Audit "ASR Rules" "CRITICAL" "No Attack Surface Reduction rules active!"
}

# 3. FORENSIC ARTIFACTS (DEEP DIVE)
Write-Host "`n[PHASE 3] DEEP FORENSIC ARTIFACTS" -ForegroundColor Cyan
# 3.1 Recent Docs
$recent = Get-ChildItem "$env:APPDATA\Microsoft\Windows\Recent"
if ($recent.Count -eq 0) {
    Log-Audit "Recent Files" "SECURE" "Recent history is empty."
} else {
    Log-Audit "Recent Files" "CRITICAL" "Found $($recent.Count) recent file traces."
}
# 3.2 User Activity Feed
$timeline = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -ErrorAction SilentlyContinue
if ($timeline.PublishUserActivities -eq 0) {
    Log-Audit "Activity Timeline" "SECURE" "Windows Activity Feed is DISABLED."
} else {
    Log-Audit "Activity Timeline" "WARNING" "Activity Feed might be logging metadata."
}

# 4. NETWORK ISOLATION & SPOTIFY
Write-Host "`n[PHASE 4] NETWORK SEGMENTATION" -ForegroundColor Cyan
# 4.1 SMB (Port 445) - Should be blocked or stealth
$smbCheck = Test-NetConnection -ComputerName 127.0.0.1 -Port 445 -WarningAction SilentlyContinue
if ($smbCheck.TcpTestSucceeded) {
    Log-Audit "SMB Port 445" "WARNING" "SMB Port is OPEN locally. Ensure it's blocked from internet."
} else {
    Log-Audit "SMB Port 445" "SECURE" "SMB Port is CLOSED/FILTERED."
}
# 4.2 Spotify Check (Must work)
$spotify = Get-Process spotify -ErrorAction SilentlyContinue
if ($spotify) {
    Log-Audit "Spotify Functionality" "SECURE" "Spotify process is running."
} else {
    Log-Audit "Spotify Functionality" "INFO" "Spotify not running (Start to verify)."
}

# 5. LOLBINS (Living Off The Land Binaries)
Write-Host "`n[PHASE 5] LOLBIN PERMISSIONS" -ForegroundColor Cyan
$certutil = Get-Acl "C:\Windows\System32\certutil.exe"
# We just check if it exists and warns user to be aware. Removing it breaks system updates.
Log-Audit "CertUtil" "INFO" "CertUtil exists. Monitor for unauthorized downloads."

# 6. DLL HIJACKING (PATH CHECK REDUX)
Write-Host "`n[PHASE 6] DLL HIJACKING VULNERABILITY" -ForegroundColor Cyan
$pathVars = $env:Path -split ";"
$writablePaths = @()
foreach ($path in $pathVars) {
    if (Test-Path $path) {
        try { 
            $testFile = "$path\test_audit.tmp"
            [IO.File]::Create($testFile).Close()
            Remove-Item $testFile
            $writablePaths += $path 
        } catch {}
    }
}
if ($writablePaths) {
    Log-Audit "PATH Security" "CRITICAL" "Writable PATHs found: $($writablePaths -join ', ')"
} else {
    Log-Audit "PATH Security" "SECURE" "No writable directories in System PATH."
}

Write-Host "`n--- AUDIT COMPLETE ---" -ForegroundColor Magenta

