# restore-settings.ps1 - VS Code settings restore
$ConfigDir = "$PSScriptRoot\..\vscode-config"

if (-not (Test-Path $ConfigDir)) {
    Write-Host "No vscode-config folder found. Skipping." -ForegroundColor Yellow
    exit
}

Write-Host "=== Restore Editor Settings ===" -ForegroundColor Cyan

# VS Code Insiders Extensions (parallel install)
$extFile = "$ConfigDir\vscode-insiders-extensions.txt"
if ((Test-Path $extFile) -and (Get-Command code-insiders -EA 0)) {
    Write-Host "`n--- VS Code Insiders Extensions ---"
    $installed = (code-insiders --list-extensions) -join "`n"
    $extensions = Get-Content $extFile | Where-Object { $_ -and ($installed -notmatch "^$([regex]::Escape($_))$") }
    
    if ($extensions.Count -gt 0) {
        $extensions | ForEach-Object -Parallel {
            Write-Host " [INSTALL] $_"
            code-insiders --install-extension $_ --force 2>$null | Out-Null
        } -ThrottleLimit 4
    }
    Write-Host " [OK] Extensions done" -ForegroundColor Green
}

# VS Code Insiders Settings
$insidersUser = "$env:APPDATA\Code - Insiders\User"
$null = New-Item $insidersUser -ItemType Directory -Force -EA 0
if ((Test-Path "$ConfigDir\vscode-insiders-settings.json") -and (-not (Test-Path "$insidersUser\settings.json"))) {
    Copy-Item "$ConfigDir\vscode-insiders-settings.json" "$insidersUser\settings.json" -Force
    Write-Host " [OK] Settings restored" -ForegroundColor Green
} elseif (Test-Path "$insidersUser\settings.json") {
    Write-Host " [SKIP] Settings already exist" -ForegroundColor DarkGray
}
if ((Test-Path "$ConfigDir\vscode-insiders-keybindings.json") -and (-not (Test-Path "$insidersUser\keybindings.json"))) {
    Copy-Item "$ConfigDir\vscode-insiders-keybindings.json" "$insidersUser\keybindings.json" -Force
    Write-Host " [OK] Keybindings restored" -ForegroundColor Green
} elseif (Test-Path "$insidersUser\keybindings.json") {
    Write-Host " [SKIP] Keybindings already exist" -ForegroundColor DarkGray
}

Write-Host "`nRestore complete!" -ForegroundColor Green
