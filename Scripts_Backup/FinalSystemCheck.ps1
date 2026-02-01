# Final System Check - Verification Only
$ErrorActionPreference = "SilentlyContinue"

Write-Host ">>> FINAL SYSTEM VERIFICATION <<<" -ForegroundColor Cyan

# 1. DNS Check
$dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -ExpandProperty ServerAddresses
if ($dns -contains "1.1.1.1" -or $dns -contains "9.9.9.9") {
    Write-Host "[OK] DNS is Secure (Cloudflare/Quad9): $dns" -ForegroundColor Green
} else {
    Write-Host "[FAIL] DNS is NOT Secure: $dns" -ForegroundColor Red
}

# 2. BitLocker Check
$blPolicy = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\FVE" -Name "EncryptionMethodWithXtsOs"
if ($blPolicy.EncryptionMethodWithXtsOs -eq 7) {
    Write-Host "[OK] BitLocker Policy: XTS-AES 256 Enforced" -ForegroundColor Green
} else {
    Write-Host "[FAIL] BitLocker Policy NOT Set Correctly" -ForegroundColor Red
}

# 3. Telemetry Check
$telemetry = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"
if ($telemetry.AllowTelemetry -eq 0) {
    Write-Host "[OK] Telemetry Disabled" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Telemetry NOT Disabled" -ForegroundColor Red
}

# 4. Spotify Check (Firewall)
$rules = Get-NetFirewallRule -DisplayName "Spotify-Isolation"
if ($rules) {
    Write-Host "[OK] Spotify Isolation Rule Exists" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Spotify Isolation Rule Missing" -ForegroundColor Red
}

# 5. Shadow Copies Check
# Needs Admin to list, so we might just check if vssadmin works or returns nothing
$shadows = vssadmin list shadows
if ($shadows -match "No items found") {
    Write-Host "[OK] No Shadow Copies Found" -ForegroundColor Green
} else {
    Write-Host "[INFO] Shadow Copies might exist or Access Denied (Run as Admin to verify)" -ForegroundColor Yellow
}

Write-Host ">>> VERIFICATION COMPLETE <<<" -ForegroundColor Cyan
