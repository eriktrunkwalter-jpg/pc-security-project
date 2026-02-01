# === MASTER SECURITY & OPTIMIZATION SCRIPT ===
# Run as ADMINISTRATOR
# Version: 2.0 (Final Hardening)

Write-Host "--- STARTING MASTER SECURITY OPTIMIZATION ---" -ForegroundColor Cyan

# 1. CHECK ADMIN
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host "ERROR: PLEASE RUN AS ADMINISTRATOR!" -ForegroundColor Red
    Start-Sleep -s 5
    exit
}

# 2. ENABLE LSA PROTECTION (RunAsPPL)
Write-Host "[+] Enabling LSA Protection..." -ForegroundColor Green
$lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
if (!(Test-Path $lsaPath)) { New-Item $lsaPath -Force | Out-Null }
Set-ItemProperty -Path $lsaPath -Name "RunAsPPL" -Value 1 -Type DWord
Set-ItemProperty -Path $lsaPath -Name "LsaCfgFlags" -Value 1 -Type DWord -ErrorAction SilentlyContinue # UEFI lock optional

# 3. DISABLE TELEMETRY & DATA COLLECTION
Write-Host "[+] Disabling Telemetry..." -ForegroundColor Green
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (!(Test-Path $telemetryPath)) { New-Item $telemetryPath -Force | Out-Null }
Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord

# 4. HARDEN NETWORK STACK (Disable NetBIOS/LLMNR)
Write-Host "[+] Hardening Network Stack..." -ForegroundColor Green
# Disable NetBIOS over TCP/IP
$interfaces = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
foreach ($interface in $interfaces) {
    $interface.SetTcpipNetbios(2) | Out-Null # 2 = Disabled
}
# Disable LLMNR
$llmnrPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $llmnrPath)) { New-Item $llmnrPath -Force | Out-Null }
Set-ItemProperty -Path $llmnrPath -Name "EnableMulticast" -Value 0 -Type DWord

# 5. BLOCK DANGEROUS PORTS (Firewall)
Write-Host "[+] Blocking Dangerous Ports (SMB/RPC/NetBIOS)..." -ForegroundColor Green
$profiles = @("Domain", "Private", "Public")
foreach ($profile in $profiles) {
    New-NetFirewallRule -DisplayName "Block_SMB_445_$profile" -Direction Inbound -LocalPort 445 -Protocol TCP -Action Block -Profile $profile -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Block_RPC_135_$profile" -Direction Inbound -LocalPort 135 -Protocol TCP -Action Block -Profile $profile -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Block_NetBIOS_139_$profile" -Direction Inbound -LocalPort 139 -Protocol TCP -Action Block -Profile $profile -ErrorAction SilentlyContinue
}

# 6. OPTIMIZE PERFORMANCE (TCP/Services)
Write-Host "[+] Optimizing System Performance..." -ForegroundColor Green
# TCP Optimization
netsh int tcp set global autotuninglevel=normal
netsh int tcp set global congestionprovider=ctcp
# Disable unused services (Careful selection)
Stop-Service "DiagTrack" -ErrorAction SilentlyContinue # Telemetry
Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service "XblAuthManager" -ErrorAction SilentlyContinue # Xbox
Set-Service "XblAuthManager" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service "XblGameSave" -ErrorAction SilentlyContinue # Xbox
Set-Service "XblGameSave" -StartupType Disabled -ErrorAction SilentlyContinue

# 7. CLEANUP
Write-Host "[+] Cleaning Temp Files..." -ForegroundColor Green
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "--- OPTIMIZATION COMPLETE! PLEASE REBOOT ---" -ForegroundColor Cyan
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
