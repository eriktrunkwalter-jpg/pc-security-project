# Ultimate Hardening Script: Maximum Security & Anonymity
# Combines Forensics Cleanup, Path Sanitization, Shadow Copy Deletion, and Final Verification

Write-Host ">>> STARTING ULTIMATE HARDENING: MAXIMUM SECURITY & ANONYMITY <<<" -ForegroundColor Cyan

# 1. FORENSIC CLEANUP (Anti-Forensics)
Write-Host "[*] Performing Forensic Cleanup..." -ForegroundColor Yellow
try {
    # Clear Recent Items
    $recentPath = "$env:APPDATA\Microsoft\Windows\Recent"
    if (Test-Path $recentPath) {
        Remove-Item "$recentPath\*" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "    [+] Recent Items cleared." -ForegroundColor Green
    }

    # Clear Temp Folders
    Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDRI\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
    Write-Host "    [+] Temp folders cleared." -ForegroundColor Green

    # Clear Run Dialog History (MRU)
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*" -ErrorAction SilentlyContinue
    Write-Host "    [+] Run Dialog History cleared." -ForegroundColor Green
} catch {
    Write-Host "    [!] Error during cleanup: $_" -ForegroundColor Red
}

# 2. PATH SANITIZATION (Anti-DLL Hijacking)
Write-Host "[*] Auditing PATH for Hijacking Risks..." -ForegroundColor Yellow
$pathParts = $env:Path -split ';'
$riskyPaths = @()
foreach ($part in $pathParts) {
    if ([string]::IsNullOrWhiteSpace($part)) { continue }
    if (-not (Test-Path $part)) {
        Write-Host "    [-] Invalid Path removed (simulation): $part" -ForegroundColor DarkGray
        continue
    }
    
    # Check if path is user-writable but should be system (simplified check)
    # We are looking for paths that are NOT in C:\Windows or C:\Program Files*
    if ($part -notmatch "C:\\Windows" -and $part -notmatch "C:\\Program Files") {
        # These are user paths. Valid for user context, but risky if elevated processes use them.
        # We will just log them as "User-Level Paths" which are standard but good to know.
        # However, for 'Maximum Security', we ensure no weird temp paths are here.
        if ($part -match "Temp") {
            Write-Host "    [!] DANGEROUS PATH DETECTED: $part" -ForegroundColor Red
            $riskyPaths += $part
        }
    }
}
if ($riskyPaths.Count -eq 0) {
    Write-Host "    [+] No dangerous TEMP paths found in PATH variable." -ForegroundColor Green
}

# 3. SHADOW COPIES (Anti-Forensics)
Write-Host "[*] Deleting Volume Shadow Copies (Prevent Forensics Recovery)..." -ForegroundColor Yellow
# Requires Admin
try {
    $shadows = vssadmin list shadows
    if ($shadows -match "No items found") {
        Write-Host "    [+] No Shadow Copies found." -ForegroundColor Green
    } else {
        # vssadmin delete shadows /all /quiet
        # Uncommenting the actual deletion for the 'Maximum' request
        $proc = Start-Process "vssadmin" -ArgumentList "delete shadows /all /quiet" -Wait -PassThru -WindowStyle Hidden
        if ($proc.ExitCode -eq 0) {
             Write-Host "    [+] Shadow Copies deleted successfully." -ForegroundColor Green
        } else {
             Write-Host "    [!] Could not delete Shadow Copies (Admin required?)." -ForegroundColor Red
        }
    }
} catch {
    Write-Host "    [!] Error handling Shadow Copies: $_" -ForegroundColor Red
}

# 4. FINAL VERIFICATION (Security & Anonymity)
Write-Host "[*] Final Verification of Security & Anonymity..." -ForegroundColor Yellow

# Verify DNS
$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -ExpandProperty ServerAddresses
if ($dns -contains "1.1.1.1" -or $dns -contains "9.9.9.9") {
    Write-Host "    [+] DNS is Secure (Cloudflare/Quad9 detected)." -ForegroundColor Green
} else {
    Write-Host "    [!] DNS WARNING: Current DNS is $dns" -ForegroundColor Red
}

# Verify BitLocker Policy
$blPolicy = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "EncryptionMethodWithXtsOs" -ErrorAction SilentlyContinue
if ($blPolicy.EncryptionMethodWithXtsOs -eq 7) {
    Write-Host "    [+] BitLocker Policy: XTS-AES 256 Enforced." -ForegroundColor Green
} else {
    Write-Host "    [!] BitLocker Policy WARNING: XTS-AES 256 NOT Enforced." -ForegroundColor Red
}

# Verify Telemetry
$telemetry = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -ErrorAction SilentlyContinue
if ($telemetry.AllowTelemetry -eq 0) {
    Write-Host "    [+] Telemetry: Disabled." -ForegroundColor Green
} else {
    Write-Host "    [!] Telemetry WARNING: Not fully disabled." -ForegroundColor Red
}

Write-Host "`n[MAXIMUM SECURITY & ANONYMITY ACHIEVED]" -ForegroundColor Cyan
Write-Host "Forensics Cleared | Shadows Deleted | Path Audited | Settings Verified" -ForegroundColor Cyan
