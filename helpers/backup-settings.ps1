# backup-settings.ps1 - VS Code settings backup
$BackupDir = "$PSScriptRoot\..\vscode-config"
$null = New-Item $BackupDir -ItemType Directory -Force

Write-Host "=== Backup VS Code Settings ===" -ForegroundColor Cyan

# VS Code Insiders
if (Get-Command code-insiders -EA 0) {
    code-insiders --list-extensions | Set-Content "$BackupDir\vscode-insiders-extensions.txt"
    Write-Host " [OK] Extensions exported" -ForegroundColor Green
}
$insidersUser = "$env:APPDATA\Code - Insiders\User"
if (Test-Path "$insidersUser\settings.json") { Copy-Item "$insidersUser\settings.json" "$BackupDir\vscode-insiders-settings.json" -Force }
if (Test-Path "$insidersUser\keybindings.json") { Copy-Item "$insidersUser\keybindings.json" "$BackupDir\vscode-insiders-keybindings.json" -Force }

Write-Host "`nBackup complete: $BackupDir" -ForegroundColor Green
