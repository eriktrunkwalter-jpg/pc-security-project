# Install-Tor.ps1
$ErrorActionPreference = "Continue"
$toolsDir = "$PSScriptRoot\..\Tools"
$torDir = "$toolsDir\Tor"
$torZip = "$toolsDir\tor.tar.gz"

$versions = @("14.0.4", "14.0.3", "14.0.1", "13.5.9", "13.0.10")
$baseUrl = "https://dist.torproject.org/torbrowser"

if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir | Out-Null }

$downloaded = $false

foreach ($ver in $versions) {
    $url = "$baseUrl/$ver/tor-expert-bundle-$ver-windows-x86_64.tar.gz"
    Write-Host "Versuche Download Version $ver..." -ForegroundColor Cyan
    try {
        # User-Agent setzen, um Blockierung zu vermeiden
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        $wc.DownloadFile($url, $torZip)
        $downloaded = $true
        Write-Host "Download erfolgreich!" -ForegroundColor Green
        break
    } catch {
        Write-Warning "Download fehlgeschlagen. Versuche Alternative..."
        try {
             # Alternativer Mirror / Methode
             Invoke-WebRequest -Uri $url -OutFile $torZip -UserAgent "Mozilla/5.0" -ErrorAction Stop
             $downloaded = $true
             Write-Host "Download erfolgreich!" -ForegroundColor Green
             break
        } catch {
             Write-Warning "Version $ver nicht gefunden."
        }
    }
}

if (-not $downloaded) {
    Write-Error "Konnte Tor nicht herunterladen. Bitte manuell prüfen."
    exit 1
}

Write-Host "Entpacke Tor..." -ForegroundColor Cyan
if (-not (Test-Path $torDir)) { New-Item -ItemType Directory -Path $torDir | Out-Null }

# Tar entpacken
tar -xf $torZip -C $torDir

# Cleanup Structure
if (Test-Path "$torDir\tor\tor.exe") {
    Move-Item "$torDir\tor\*" "$torDir" -Force
    Remove-Item "$torDir\tor" -Recurse -Force
}

if (Test-Path "$torDir\tor.exe") {
    Write-Host "Tor erfolgreich installiert." -ForegroundColor Green
    Remove-Item $torZip -Force
} else {
    Write-Error "Tor Executable nicht gefunden."
}
