# backup-settings.ps1 - Fast VS Code & Antigravity settings backup
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

# Antigravity
if (Get-Command antigravity -EA 0) {
    antigravity --list-extensions | Set-Content "$BackupDir\antigravity-extensions.txt"
    Write-Host " [OK] Antigravity extensions exported" -ForegroundColor Green
}
$agUser = "$env:APPDATA\Antigravity\User"
$agBackup = "$BackupDir\antigravity"
if (Test-Path $agUser) {
    $null = New-Item "$agBackup\globalStorage" -ItemType Directory -Force
    if (Test-Path "$agUser\settings.json") { Copy-Item "$agUser\settings.json" "$agBackup\settings.json" -Force }
    if (Test-Path "$agUser\globalStorage\storage.json") { Copy-Item "$agUser\globalStorage\storage.json" "$agBackup\globalStorage\storage.json" -Force }
}

Write-Host "`nBackup complete: $BackupDir" -ForegroundColor Green
