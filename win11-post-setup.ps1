# Requires -Version 7.0
$ErrorActionPreference = "Stop"
$ScriptRoot ??= $PSScriptRoot

# --- Helpers ---
function Show-Header ([string]$t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Show-OK ([string]$t) { Write-Host " [OK] $t" -ForegroundColor Green }
function Show-Error ([string]$t) { Write-Host " [ERROR] $t" -ForegroundColor Red }

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Show-Error "Administrative privileges required."; exit 1
}

Show-Header "Win 11 Setup (PS7 Refined)"

# =========================
# update winget sources
# =========================
Show-Header "Configuring winget..."
try { winget source update 2>$null } catch {}

# =====================
# winget installations
# =====================
Show-Header "Installing programs..."
$packages = @(
    "Microsoft.WindowsTerminal", "Mozilla.Firefox", "openhashtab", "Microsoft.VisualStudioCode.Insiders",
    "gerardog.gsudo", "Starship.Starship", "chrisant996.Clink", "DEVCOM.JetBrainsMonoNerdFont",
    "CodeSector.TeraCopy", "Valve.Steam", "7zip.7zip", "JAMSoftware.TreeSize.Free",
    "veeam.veeamagent", "vim.vim", "Git.Git", "sharkdp.bat", "lsd-rs.lsd", "AutoHotkey.AutoHotkey",
    "Google.GoogleDrive", "dandavison.delta", "aria2.aria2", "Google.Antigravity", "marha.VcXsrv",
    "XP8JNQFBQH6PVF", "9PKTQ5699M62"
)

$installed = (winget list --accept-source-agreements | Out-String)
foreach ($id in $packages) {
    if ($installed -match [regex]::Escape($id)) {
        Write-Host " [SKIP] $id" -ForegroundColor DarkGray
    } else {
        Write-Host " [INSTALL] $id..."
        winget install --id $id --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { Show-OK $id } else { Show-Error $id }
    }
}

# ===========================
# fix git, vim, starship path
# ===========================
Show-Header "Fixing PATH Environment Variable"
$path = [Environment]::GetEnvironmentVariable('Path', 'User')
$vimSearch = Get-ChildItem 'C:\Program Files\Vim' -Filter vim.exe -Recurse -EA 0 | Select-Object -First 1
$v = $vimSearch ? $vimSearch.DirectoryName : $null

if ($v) { Write-Host " [DEBUG] Vim found at: $v" -ForegroundColor DarkGray }
else { Write-Host " [WARN] Vim not found in C:\Program Files\Vim" -ForegroundColor Yellow }

$targets = @($v, 'C:\Program Files\Git\cmd', 'C:\Program Files\starship\bin') | Where-Object { $_ -and (Test-Path $_) }

$clean = $path -split ';' | Where-Object { $_ -and ($_ -notmatch 'Git\\usr\\bin') -and ($targets -notcontains $_) }
$newPath = ($clean + $targets) -join ';'

if ($path -ne $newPath) {
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    # Refresh current session PATH
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $newPath
    Show-OK "PATH updated and refreshed."
} else {
    Write-Host " [SKIP] PATH already correct." -ForegroundColor DarkGray
}

# ===============
# starship config
# ===============
Show-Header "Configuring Starship..."
$clinkDir = "$env:LOCALAPPDATA\clink"; $configDir = "$env:USERPROFILE\.config"
$null = New-Item -Path $clinkDir, $configDir -ItemType Directory -Force

"load(io.popen('starship init cmd'):read(`"*a`"))()" | Set-Content "$clinkDir\starship.lua" -Force

$display = "$ScriptRoot\configs\clink_display.lua"
if (Test-Path $display) { Copy-Item $display "$clinkDir\display.lua" -Force }

# Copy starship.toml from configs (or download if missing)
$starshipSrc = "$ScriptRoot\configs\starship.toml"
if (Test-Path $starshipSrc) {
    Copy-Item $starshipSrc "$configDir\starship.toml" -Force
    Show-OK "Starship preset copied."
} else {
    try {
        Invoke-WebRequest "https://starship.rs/presets/toml/gruvbox-rainbow.toml" -OutFile "$configDir\starship.toml" -UseBasicParsing
        Show-OK "Starship preset downloaded."
    } catch { Write-Host " [WARN] Starship preset failed." -ForegroundColor Yellow }
}

# =============
# setup aliases
# =============
$aliasesSrc = "$ScriptRoot\configs\aliases"
$aliasesDst = "$clinkDir\aliases"
if (Test-Path $aliasesSrc) {
    Copy-Item $aliasesSrc $aliasesDst -Force
    Show-OK "Aliases copied."
} else {
    # Fallback: generate inline
    @("ls=lsd -l", "ll=lsd -la --size=short --date=relative", "vi=vim $*", "cat=bat $*") | Set-Content $aliasesDst
    Show-OK "Aliases generated."
}

$clinkBat = (Test-Path "${env:ProgramFiles(x86)}\clink\clink.bat") ? "${env:ProgramFiles(x86)}\clink\clink.bat" : ((Test-Path "${env:ProgramW6432}\clink\clink.bat") ? "${env:ProgramW6432}\clink\clink.bat" : $null)
if ($clinkBat) {
    $cmd = "`"$clinkBat`" inject --profile `"$clinkDir`" && doskey /macrofile=`"$aliasesDst`""
    reg add "HKCU\Software\Microsoft\Command Processor" /v Autorun /t REG_SZ /d $cmd /f | Out-Null
    Show-OK "Clink Autorun configured."
}

# ==========
# add .vimrc
# ==========
Show-Header "Setting up .vimrc"
$vimrcSrc = "$ScriptRoot\configs\.vimrc"
if (Test-Path $vimrcSrc) {
    Copy-Item $vimrcSrc "$env:USERPROFILE\.vimrc" -Force; Show-OK ".vimrc installed."
} else {
    Show-Error ".vimrc source not found."
}

# =====================
# add macos-hotkeys.ahk
# =====================
$ahkSrc = "$ScriptRoot\configs\macos-hotkeys.ahk"
if (Test-Path $ahkSrc) { Copy-Item $ahkSrc "$env:USERPROFILE\Desktop\macos-hotkeys.ahk" -Force; Show-OK "Hotkey script copied." }

# ============================
# Configure Disk Cleanup
# ============================
Show-Header "Configuring Cleanup..."
$regCleanup = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$caches = @("Active Setup Temp Folders", "BranchCache", "D3D Shader Cache", "Delivery Optimization Files", "Downloaded Program Files", "Internet Cache Files", "Memory Dump Files", "Old Chkdsk Files", "Setup Log Files", "System error memory dump files", "Temporary Files", "Temporary Setup Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files", "Windows Defender", "Windows Error Reporting Files")
$caches | % { reg add "$regCleanup\$_" /v StateFlags0001 /t REG_DWORD /d 2 /f | Out-Null }
reg add "$regCleanup\Recycle Bin" /v StateFlags0001 /t REG_DWORD /d 0 /f | Out-Null
reg add "$regCleanup\DownloadsFolder" /v StateFlags0001 /t REG_DWORD /d 0 /f | Out-Null
Show-OK "Disk Cleanup configured."

# ============================
# Maintenance Scripts & Tasks
# ============================
@(@{Src="cleanup-win.bat"; TN="WeeklyCleanup"; Sch="WEEKLY"}, @{Src="daily-update.bat"; TN="DailyWingetUpdate"; Sch="DAILY"}) | % {
    $src = "$ScriptRoot\configs\$($_.Src)"
    if (Test-Path $src) {
        Copy-Item $src "$env:USERPROFILE\$($_.Src)" -Force
        schtasks /create /tn $_.TN /tr "`"$env:USERPROFILE\$($_.Src)`"" /sc $_.Sch /st 12:00 /rl HIGHEST /f | Out-Null
    }
}
Show-OK "Maintenance tasks scheduled."

# =====================================
# Restore VS Code Settings & Extensions
# =====================================
$restore = "$ScriptRoot\helpers\restore-settings.ps1"
if (Test-Path $restore) { & $restore; Show-OK "VS Code restored." }

# ==============
# winget Update
# ==============
Show-Header "System Update..."
winget pin add --id Microsoft.AppInstaller --blocking *>$null 2>&1
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
winget pin remove --id Microsoft.AppInstaller *>$null 2>&1
Show-OK "Software updated."

# ============================
# Privacy & UI Registry Tweaks
# ============================
Show-Header "Privacy & UI Tweaks"
$tw = @(
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; N="SubscribedContent-338388Enabled"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; N="SubscribedContent-338389Enabled"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; N="SubscribedContent-338393Enabled"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; N="SubscribedContent-353694Enabled"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; N="SubscribedContent-353696Enabled"; V=0},
    @{P="HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"; N="HarvestContacts"; V=0},
    @{P="HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"; N="HarvestTyping"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"; N="BingSearchEnabled"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings"; N="CortanaConsent"; V=0},
    @{P="HKCU:\Software\Microsoft\Speech_OneCore\Preferences"; N="HasAccepted"; V=0},
    @{P="HKCU:\Software\Microsoft\InputPersonalization"; N="RestrictImplicitTextCollection"; V=1},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; N="TaskbarAl"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"; N="AppsUseLightTheme"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; N="HideFileExt"; V=0},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; N="Hidden"; V=1},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; N="ShowSuperHidden"; V=1},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; N="LaunchTo"; V=1},
    @{P="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; N="EnableXamlStartMenu"; V=0},
    @{P="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; N="AllowTelemetry"; V=0},
    @{P="HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"; N="DisabledByGroupPolicy"; V=1},
    @{P="HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; N="DisableWindowsConsumerFeatures"; V=1},
    @{P="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; N="DisableLocation"; V=1},
    @{P="HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"; N="DisableLocationScripting"; V=1},
    @{P="HKCU:\Software\Policies\Microsoft\Windows\CloudContent"; N="DisableTailoredExperiencesWithDiagnosticData"; V=1}
)
foreach ($t in $tw) { if (-not (Test-Path $t.P)) { New-Item $t.P -Force | Out-Null }; Set-ItemProperty $t.P $t.N $t.V -Force }
Show-OK "Privacy tweaks applied."

# ======================
# Download & Install Meslo Font
# ======================
Show-Header "Installing Fonts..."
$fontPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\MesloLGS NF Regular.ttf"
$fontPathSystem = "C:\Windows\Fonts\MesloLGS NF Regular.ttf"
if ((Test-Path $fontPath) -or (Test-Path $fontPathSystem)) {
    Write-Host " [SKIP] Fonts already installed" -ForegroundColor DarkGray
} else {
    $links = @("Regular", "Bold", "Italic", "Bold%20Italic") | % { "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20$_.ttf" }
    $dl = "$env:TEMP\Fonts"; $null = New-Item $dl -ItemType Directory -Force
    $links | ForEach-Object -Parallel { Invoke-WebRequest $_ -OutFile "$using:dl\$(($_ -split '/')[-1])" -UseBasicParsing } -ThrottleLimit 4
    $s = (New-Object -Com Shell.Application).Namespace(0x14)
    Get-ChildItem $dl -Filter *.ttf | ForEach-Object { $s.CopyHere($_.FullName) }
    Show-OK "Fonts installed."
}

# ============================
# Install RSAT Tools
# ============================
Show-Header "Installing RSAT Tools..."
$rsatFeatures = @(
    "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0",
    "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0",
    "Rsat.Dns.Tools~~~~0.0.1.0",
    "Rsat.ServerManager.Tools~~~~0.0.1.0"
)
foreach ($feature in $rsatFeatures) {
    $state = Get-WindowsCapability -Online -Name $feature -EA 0
    if ($state.State -eq "Installed") {
        Write-Host " [SKIP] $($feature.Split('.')[1])" -ForegroundColor DarkGray
    } else {
        Write-Host " [INSTALL] $($feature.Split('.')[1])..."
        Add-WindowsCapability -Online -Name $feature -EA 0 | Out-Null
    }
}
Show-OK "RSAT tools configured."

# ============================
# SSH Agent & Git Config
# ============================
if (Get-Service ssh-agent -EA 0) { Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent }
if (-not (git config --global user.name)) { git config --global user.name (Read-Host "Git Name"); git config --global user.email (Read-Host "Git Email") }
git config --global core.pager "delta"; git config --global delta.navigate true; Show-OK "SSH & Git configured."

# ======================
# Install MailStore Home
# ======================
if (-not (Test-Path "${env:ProgramFiles(x86)}\MailStore\MailStore Home\MailStoreHome.exe")) {
    $ms = "$env:USERPROFILE\Downloads\MailStoreHomeSetup.exe"
    Start-Process aria2c "-x 16 -s 16 -d `"$env:USERPROFILE\Downloads`" -o MailStoreHomeSetup.exe https://my.mailstore.com/Downloads/Home" -Wait
    if (Test-Path $ms) { Start-Process $ms -Wait }
}

# ============================
# RDP Auto-Suspend (Optional)
# ============================
# Suspends VM on Linux host when RDP disconnects
$autoSuspendTask = "AutoSuspend-RDP"
$existingTask = schtasks /query /tn $autoSuspendTask 2>&1
if ($existingTask -match "ERROR|does not exist") {
    $LinuxHost = "192.168.1.5"
    $LinuxUser = "nasadmin"
    $VMName = "Win11"
    
    # Create suspend script
    $SuspendScript = "$env:ProgramData\rdp-suspend.ps1"
    "ssh ${LinuxUser}@${LinuxHost} `"virsh -c qemu:///system suspend ${VMName}`"" | Set-Content $SuspendScript
    
    # Create scheduled task
    schtasks /create /tn $autoSuspendTask `
        /tr "pwsh.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$SuspendScript`"" `
        /sc ONEVENT /ec "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" `
        /mo "*[System[Provider[@Name='Microsoft-Windows-TerminalServices-LocalSessionManager'] and (EventID=24)]]" `
        /ru "$env:USERDOMAIN\$env:USERNAME" /it /f | Out-Null
    
    if ($LASTEXITCODE -eq 0) { Show-OK "Auto-Suspend task created." }
    else { Show-Error "Auto-Suspend task failed." }
} else {
    Write-Host " [SKIP] Auto-Suspend task exists" -ForegroundColor DarkGray
}

# ======================
# Start Debloater script
# ======================
$debloatMarker = "$env:USERPROFILE\.debloat-done"
if (-not (Test-Path $debloatMarker)) {
    Show-Header "Launching Debloater"
    Start-Process powershell -ArgumentList "irm `"https://win11debloat.raphi.re/`" | iex"
    $null = New-Item $debloatMarker -ItemType File -Force
} else {
    Write-Host " [SKIP] Debloater already run" -ForegroundColor DarkGray
}

Show-Header "Setup Complete!"
Read-Host "Press Enter to exit"
