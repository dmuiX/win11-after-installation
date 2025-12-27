# cleanup-win.ps1 - System maintenance and cleanup
# Requires -RunAsAdministrator

# Self-elevate if not admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh -ArgumentList "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$Host.UI.RawUI.WindowTitle = "Windows Maintenance"
Clear-Host

Write-Host "`n╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Windows Maintenance & Cleanup Script   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray

# Part 1: DISM Image Repair
Write-Host "━━━ Part 1: DISM Image Repair ━━━" -ForegroundColor Cyan
Write-Host " [1/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Checking component store health..."
DISM /Online /Cleanup-Image /CheckHealth

Write-Host " [2/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Scanning for corruption..."
DISM /Online /Cleanup-Image /ScanHealth

Write-Host " [3/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Repairing Windows image..."
DISM /Online /Cleanup-Image /RestoreHealth

# Part 2: Component Cleanup
Write-Host "`n━━━ Part 2: Component Store Cleanup ━━━" -ForegroundColor Cyan
Write-Host " [4/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Analyzing component store..."
DISM /Online /Cleanup-Image /AnalyzeComponentStore

Write-Host " [5/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Standard cleanup..."
DISM /Online /Cleanup-Image /StartComponentCleanup

Write-Host " [6/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Aggressive cleanup (ResetBase)..."
DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase

Write-Host " [7/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Removing superseded components..."
DISM /Online /Cleanup-Image /SPSuperseded

# Part 3: SFC
Write-Host "`n━━━ Part 3: System File Check ━━━" -ForegroundColor Cyan
Write-Host " [8/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Verifying system files..."
sfc /scannow

# Part 4: Disk Cleanup
Write-Host "`n━━━ Part 4: Disk Cleanup ━━━" -ForegroundColor Cyan
Write-Host " ⏳ " -NoNewline -ForegroundColor Yellow; Write-Host "Launching Disk Cleanup utility..."
Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait
Write-Host " ✓ " -NoNewline -ForegroundColor Green; Write-Host "Disk Cleanup complete"

# Part 5: Deep Cleaning
Write-Host "`n━━━ Part 5: Deep System Cleaning ━━━" -ForegroundColor Cyan
Write-Host " [1/3] " -NoNewline -ForegroundColor Yellow; Write-Host "Clearing temporary files..."
Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0
Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -EA 0
Write-Host "       ✓ Temporary files cleared" -ForegroundColor DarkGreen

Write-Host " [2/3] " -NoNewline -ForegroundColor Yellow; Write-Host "Clearing Windows Update cache..."
Stop-Service wuauserv, bits -Force -EA 0
Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -EA 0
Start-Service wuauserv, bits -EA 0
Write-Host "       ✓ Update cache cleared" -ForegroundColor DarkGreen

Write-Host " [3/3] " -NoNewline -ForegroundColor Yellow; Write-Host "Flushing DNS cache..."
Clear-DnsClientCache
Write-Host "       ✓ DNS cache flushed" -ForegroundColor DarkGreen

Write-Host "`n╔═══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        ✓ Maintenance Complete!           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray
Read-Host "Press Enter to exit"
