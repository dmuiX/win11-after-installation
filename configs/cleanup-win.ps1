# cleanup-win.ps1 - System maintenance and cleanup
# Requires -RunAsAdministrator

# Require admin (run inline; no auto-elevation window)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script must be run as Administrator. Right-click and choose 'Run as administrator'." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$Host.UI.RawUI.WindowTitle = "Windows Maintenance"
Clear-Host

param(
    [switch]$Ask
)

function Invoke-IfSelected {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    if (-not $Ask) {
        & $Action
        return $true
    }

    $choice = Read-Host "$Label (y/N)"
    if ($choice -match '^(y|yes)$') {
        & $Action
        return $true
    }

    Write-Host " ⏭️  Skipped: $Label" -ForegroundColor DarkGray
    return $false
}

Write-Host "`n╔═══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Windows Maintenance & Cleanup Script   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray

# Part 1: DISM Image Repair
Write-Host "━━━ Part 1: DISM Image Repair ━━━" -ForegroundColor Cyan
Invoke-IfSelected "DISM CheckHealth" {
    Write-Host " [1/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Checking component store health..."
    DISM /Online /Cleanup-Image /CheckHealth
}

Invoke-IfSelected "DISM ScanHealth" {
    Write-Host " [2/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Scanning for corruption..."
    DISM /Online /Cleanup-Image /ScanHealth
}

Invoke-IfSelected "DISM RestoreHealth" {
    Write-Host " [3/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Repairing Windows image..."
    DISM /Online /Cleanup-Image /RestoreHealth
}

# Part 2: Component Cleanup
Write-Host "`n━━━ Part 2: Component Store Cleanup ━━━" -ForegroundColor Cyan
Invoke-IfSelected "DISM AnalyzeComponentStore" {
    Write-Host " [4/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Analyzing component store..."
    DISM /Online /Cleanup-Image /AnalyzeComponentStore
}

Invoke-IfSelected "DISM StartComponentCleanup" {
    Write-Host " [5/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Standard cleanup..."
    DISM /Online /Cleanup-Image /StartComponentCleanup
}

Invoke-IfSelected "DISM StartComponentCleanup /ResetBase" {
    Write-Host " [6/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Aggressive cleanup (ResetBase)..."
    DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
}

Invoke-IfSelected "DISM SPSuperseded" {
    Write-Host " [7/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Removing superseded components..."
    DISM /Online /Cleanup-Image /SPSuperseded
}

# Part 3: SFC
Write-Host "`n━━━ Part 3: System File Check ━━━" -ForegroundColor Cyan
Invoke-IfSelected "SFC /scannow" {
    Write-Host " [8/8] " -NoNewline -ForegroundColor Yellow; Write-Host "Verifying system files..."
    sfc /scannow
}

# Part 4: Disk Cleanup
Write-Host "`n━━━ Part 4: Disk Cleanup ━━━" -ForegroundColor Cyan
Invoke-IfSelected "Disk Cleanup (cleanmgr /sagerun:1)" {
    Write-Host " ⏳ " -NoNewline -ForegroundColor Yellow; Write-Host "Launching Disk Cleanup utility..."
    Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait
    Write-Host " ✓ " -NoNewline -ForegroundColor Green; Write-Host "Disk Cleanup complete"
}

# Part 5: Deep Cleaning
Write-Host "`n━━━ Part 5: Deep System Cleaning ━━━" -ForegroundColor Cyan
Invoke-IfSelected "Clear temporary files" {
    Write-Host " [1/3] " -NoNewline -ForegroundColor Yellow; Write-Host "Clearing temporary files..."
    Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0
    Remove-Item "$env:WINDIR\Temp\*" -Recurse -Force -EA 0
    Write-Host "       ✓ Temporary files cleared" -ForegroundColor DarkGreen
}

Invoke-IfSelected "Clear Windows Update cache" {
    Write-Host " [2/3] " -NoNewline -ForegroundColor Yellow; Write-Host "Clearing Windows Update cache..."
    Stop-Service wuauserv, bits -Force -EA 0
    Remove-Item "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -EA 0
    Start-Service wuauserv, bits -EA 0
    Write-Host "       ✓ Update cache cleared" -ForegroundColor DarkGreen
}

Invoke-IfSelected "Flush DNS cache" {
    Write-Host " [3/3] " -NoNewline -ForegroundColor Yellow; Write-Host "Flushing DNS cache..."
    Clear-DnsClientCache
    Write-Host "       ✓ DNS cache flushed" -ForegroundColor DarkGreen
}

Write-Host "`n╔═══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        ✓ Maintenance Complete!           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host "Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor DarkGray
Read-Host "Press Enter to exit"
