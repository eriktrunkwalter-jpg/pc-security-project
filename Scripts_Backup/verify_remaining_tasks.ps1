$results = @{}

# 1. Check BitLocker Status
try {
    $bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
    if ($bitlocker) {
        $results["BitLocker"] = "Status: $($bitlocker.VolumeStatus), Protection: $($bitlocker.ProtectionStatus)"
    } else {
        $results["BitLocker"] = "Not Enabled or Access Denied (Run as Admin)"
    }
} catch {
    $results["BitLocker"] = "Error checking (Module not found?)"
}

# 2. Check LSA Protection (RunAsPPL)
try {
    $lsa = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RunAsPPL" -ErrorAction SilentlyContinue
    if ($lsa -and $lsa.RunAsPPL -eq 1) {
        $results["LSA_Protection"] = "Enabled (1)"
    } else {
        $results["LSA_Protection"] = "Disabled or Not Set"
    }
} catch {
    $results["LSA_Protection"] = "Error checking registry"
}

# 3. Check Admin Status
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [System.Security.Principal.WindowsPrincipal]$currentUser
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    $results["User_Account"] = "Running as Administrator (Recommendation: Use Standard User)"
} else {
    $results["User_Account"] = "Running as Standard User (Good)"
}

# 4. Check Windows Update Service
try {
    $wua = Get-Service wuauserv -ErrorAction SilentlyContinue
    $results["Windows_Update"] = "Status: $($wua.Status), StartType: $($wua.StartType)"
} catch {
    $results["Windows_Update"] = "Error checking service"
}

# Output Results
$results | Out-String | Write-Host
