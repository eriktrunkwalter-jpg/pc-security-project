# Safety_Patch.ps1
# AUTOMATICALLY DISABLES DANGEROUS COMMANDS (Shutdown, Restart) in the current folder and subfolders.
# Run this once on your PC to secure the project.

$files = Get-ChildItem -Recurse -Include *.ps1, *.txt

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $newContent = $content

    # 1. Disable Stop-Computer
    if ($content -match "Stop-Computer") {
        Write-Host "Disabling Shutdown in: $($file.Name)" -ForegroundColor Yellow
        $newContent = $newContent -replace "Stop-Computer", "Write-Host 'DISABLED: Stop-Computer' -ForegroundColor Yellow # Stop-Computer"
    }

    # 2. Disable Restart-Computer
    if ($content -match "Restart-Computer") {
        Write-Host "Disabling Restart in: $($file.Name)" -ForegroundColor Yellow
        $newContent = $newContent -replace "Restart-Computer", "Write-Host 'DISABLED: Restart-Computer' -ForegroundColor Yellow # Restart-Computer"
    }

    # 3. Disable shutdown.exe
    if ($content -match "shutdown.exe") {
        Write-Host "Disabling shutdown.exe in: $($file.Name)" -ForegroundColor Yellow
        $newContent = $newContent -replace "shutdown.exe", "Write-Host 'DISABLED: shutdown.exe' -ForegroundColor Yellow # shutdown.exe"
    }

    if ($content -ne $newContent) {
        Set-Content -Path $file.FullName -Value $newContent
        Write-Host "SECURED: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "DONE. Project is safe." -ForegroundColor Green
Read-Host "Press Enter to exit"