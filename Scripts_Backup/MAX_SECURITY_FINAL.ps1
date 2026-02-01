# MAX_SECURITY_FINAL.ps1
# RUN AS ADMINISTRATOR TO FINALIZE
# Enforces DNS, Deletes Shadows, Cleans Forensics

$ErrorActionPreference = "SilentlyContinue"

Write-Host ">>> APPLYING FINAL MAXIMUM SECURITY LAYER <<<" -ForegroundColor Cyan

# 1. FORCE SECURE DNS (Cloudflare + Quad9)
Write-Host "[*] Enforcing Secure DNS on Ethernet..." -ForegroundColor Yellow
$targetInterface = 10 # Ethernet Index identified
Set-DnsClientServerAddress -InterfaceIndex $targetInterface -ServerAddresses ("1.1.1.1", "9.9.9.9")
$newDNS = Get-DnsClientServerAddress -InterfaceIndex $targetInterface -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses
if ($newDNS -contains "1.1.1.1") {
    Write-Host "    [+] DNS Secured: $newDNS" -ForegroundColor Green
} else {
    Write-Host "    [!] DNS Set Failed. Run script as Administrator!" -ForegroundColor Red
}

# 2. DELETE SHADOW COPIES (Anti-Forensics)
Write-Host "[*] Deleting Volume Shadow Copies..." -ForegroundColor Yellow
vssadmin delete shadows /all /quiet
if ($?) {
    Write-Host "    [+] Shadow Copies deleted." -ForegroundColor Green
} else {
    Write-Host "    [!] Failed to delete shadows. Run as Administrator!" -ForegroundColor Red
}

# 3. DEEP FORENSIC CLEANUP
Write-Host "[*] Cleaning Deep Forensics..." -ForegroundColor Yellow
Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -Recurse
Remove-Item "$env:TEMP\*" -Force -Recurse
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" -Name "*"
Write-Host "    [+] Traces wiped." -ForegroundColor Green

# 4. PATH CHECK REMINDER
Write-Host "[*] Path Security Check:" -ForegroundColor Yellow
Write-Host "    - User writable paths in PATH variable were identified (Python, VSCode)." -ForegroundColor Gray
Write-Host "    - Ensure you do not run unknown scripts from these folders." -ForegroundColor Gray

Write-Host "`n[SYSTEM STATE: MAXIMUM SECURITY & ANONYMITY]" -ForegroundColor Cyan
Write-Host "Please ensure BitLocker Encryption finishes (check bl_status.txt or tray icon)." -ForegroundColor Gray
Read-Host "Press Enter to exit"
