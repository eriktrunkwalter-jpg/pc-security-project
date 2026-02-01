# Deep Security & Anonymity Scan
$ErrorActionPreference = "SilentlyContinue"
$report = @{}

function Get-Status($test, $good, $bad) {
    if ($test) { return $good } else { return $bad }
}

# 1. Admin Privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$report["Admin_Rights"] = Get-Status $isAdmin "YES (Can apply system fixes)" "NO (Standard User - requires elevation for fixes)"

# 2. LSA Protection
$lsa = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL"
$report["LSA_Protection"] = Get-Status ($lsa.RunAsPPL -eq 1) "Enabled (Secure)" "DISABLED (Critical Gap)"

# 3. Firewall (Public Profile)
$fw = Get-NetFirewallProfile -Profile Public
$report["Firewall_Public"] = Get-Status ($fw.Enabled) "Enabled" "DISABLED"

# 4. Dangerous Ports (SMB/NetBIOS check) - Simple check if listening
$ports = Get-NetTCPConnection -State Listen -LocalPort 445, 139, 135
if ($ports) {
    $report["Open_Dangerous_Ports"] = "YES (Ports 445/139/135 listening - Risk!)"
} else {
    $report["Open_Dangerous_Ports"] = "No (Good)"
}

# 5. Anonymity Tools Check
$tools = @{
    "Tor" = "$env:USERPROFILE\OneDrive\Desktop\Tor Browser\Browser\TorBrowser\Tor\tor.exe"
    "RiseupVPN" = "C:\Program Files (x86)\RiseupVPN\riseup-vpn.exe"
    "WARP" = "C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe"
    "Psiphon" = "$env:USERPROFILE\.gemini\antigravity\scratch\psiphon3.exe"
}

foreach ($tool in $tools.Keys) {
    $exists = Test-Path $tools[$tool]
    $report["Tool_$tool"] = Get-Status $exists "Installed" "MISSING"
}

# 6. Windows Update Status
$wua = Get-Service wuauserv
$report["Windows_Update_Service"] = "$($wua.Status) ($($wua.StartType))"

# 7. Telemetry (Basic Check)
$telemetry = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry"
$report["Telemetry_Policy"] = Get-Status ($telemetry.AllowTelemetry -eq 0) "Disabled (Good)" "Default/Enabled"

# Output
$report | ConvertTo-Json -Depth 2

