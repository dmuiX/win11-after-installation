# daily-update.ps1 - Daily Winget Update
# Requires -RunAsAdministrator

# Self-elevate if not admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$Host.UI.RawUI.WindowTitle = "Daily Update"
Clear-Host

Write-Host "`n╔══════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Daily Winget Update       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════╝" -ForegroundColor Cyan
Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray

# Pin AppInstaller to prevent self-update loops
Write-Host "⚙️  Preparing..." -ForegroundColor Yellow
$pinned = winget pin list --id Microsoft.AppInstaller 2>$null
if (-not $pinned) {
    Write-Host "   → Pinning AppInstaller" -ForegroundColor DarkGray
    winget pin add --id Microsoft.AppInstaller --blocking 2>$null
} else {
    Write-Host "   → AppInstaller already pinned" -ForegroundColor DarkGray
}

# Upgrade all
Write-Host "`n📦 Upgrading packages...`n" -ForegroundColor Yellow
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

# Unpin
Write-Host "`n🔓 Cleanup..." -ForegroundColor Yellow
winget pin remove --id Microsoft.AppInstaller 2>$null

Write-Host "`n╔══════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✓ Update Complete!        ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════╝" -ForegroundColor Green
Write-Host "$(Get-Date -Format 'HH:mm:ss')`n" -ForegroundColor DarkGray
Start-Sleep 3
