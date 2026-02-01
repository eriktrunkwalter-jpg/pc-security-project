# GitHub CLI Installer (Portable)
$ErrorActionPreference = "Stop"
$Version = "2.86.0"
$Url = "https://github.com/cli/cli/releases/download/v$Version/gh_${Version}_windows_amd64.zip"
$DestDir = "$PSScriptRoot\Tools"
$ZipPath = "$DestDir\gh.zip"

Write-Host "Creating Tools Directory..."
New-Item -ItemType Directory -Force -Path $DestDir | Out-Null

Write-Host "Downloading GitHub CLI v$Version..."
Invoke-WebRequest -Uri $Url -OutFile $ZipPath

Write-Host "Extracting..."
Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force

Write-Host "Cleaning up..."
Remove-Item $ZipPath -Force

Write-Host "GitHub CLI Installed to: $DestDir\gh_${Version}_windows_amd64\bin\gh.exe"