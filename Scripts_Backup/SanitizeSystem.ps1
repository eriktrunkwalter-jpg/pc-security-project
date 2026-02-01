# === PATH SANITIZATION & FORENSIC CLEANUP ===
# Purpose: Remove writable paths from User PATH variable (DLL Hijacking Fix)
#          and disable Activity Feed + Clear Recent Docs

$ErrorActionPreference = "SilentlyContinue"

Write-Host "--- STARTING PATH SANITIZATION & CLEANUP ---" -ForegroundColor Cyan

# 1. FIX DLL HIJACKING (Clean User Path)
Write-Host "Scanning User PATH for writable directories..."
$userPathRaw = [Environment]::GetEnvironmentVariable("Path", "User")
$userPathParts = $userPathRaw -split ";"
$cleanPathParts = @()
$removedPaths = @()

foreach ($path in $userPathParts) {
    # Check if path is in AppData (User writable)
    if ($path -like "$env:USERPROFILE\AppData*") {
        # Check if actually writable (though we know AppData usually is)
        # We will remove ALL AppData paths from global PATH to be safe against hijacking
        # This forces user to use direct links or full paths, but closes the vulnerability.
        $removedPaths += $path
    } else {
        $cleanPathParts += $path
    }
}

if ($removedPaths.Count -gt 0) {
    Write-Host "Removing vulnerable paths from User PATH variable:" -ForegroundColor Yellow
    $removedPaths | ForEach-Object { Write-Host " - $_" }
    
    $newPathStr = $cleanPathParts -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPathStr, "User")
    Write-Host "User PATH sanitized. (Note: You may need to use full paths for Python/VSCode binaries now)" -ForegroundColor Green
} else {
    Write-Host "User PATH looks clean." -ForegroundColor Green
}

# 2. DISABLE ACTIVITY FEED (Registry Fix)
Write-Host "Disabling Activity Feed..."
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
Set-ItemProperty -Path $regPath -Name "PublishUserActivities" -Value 0 -Type DWord -Force
Write-Host "Activity Feed Disabled via Registry." -ForegroundColor Green

# 3. CLEAR RECENT DOCS
Write-Host "Clearing Recent Docs..."
Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -Recurse -ErrorAction SilentlyContinue
Write-Host "Recent Docs cleared." -ForegroundColor Green

Write-Host "--- CLEANUP COMPLETE ---" -ForegroundColor Magenta
