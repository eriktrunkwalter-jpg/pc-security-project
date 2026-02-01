# Sync to GitHub Helper
$ErrorActionPreference = "Stop"

# Find gh.exe
$GH = "$PSScriptRoot\Tools\bin\gh.exe"
if (-not (Test-Path $GH)) {
    $GH = Get-ChildItem -Path "$PSScriptRoot\Tools" -Filter "gh.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
}

if (-not $GH) {
    Write-Error "GitHub CLI (gh.exe) not found in Tools folder."
}

Write-Host ">>> GITHUB SYNC WIZARD <<<" -ForegroundColor Cyan
Write-Host "1. Authentication"
Write-Host "   I will attempt to start the browser login."
Write-Host "   Please approve the request in your browser!"

# Try to automate the "Press Enter" prompt by piping empty input
# We use specific flags to avoid other prompts
try {
    echo "" | & $GH auth login --hostname github.com --git-protocol https --web
} catch {
    Write-Warning "Authentication might have required manual interaction."
}

Write-Host "`n2. Creating Repository & Pushing Code"
# Try to create repo. If it fails (e.g. already exists), we try to push anyway.
try {
    & $GH repo create pc-security-project --private --source=. --remote=origin --push
} catch {
    Write-Warning "Repo creation might have failed (already exists?). Trying to push manually..."
    git push -u origin main
}

Write-Host "`n[SUCCESS] Project is on GitHub!" -ForegroundColor Green
Write-Host "On your Mac, run: git clone https://github.com/<YOUR-USERNAME>/pc-security-project.git" -ForegroundColor Gray