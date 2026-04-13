# Requires -Version 7.0
param(
    [switch]$FixWinget,      # fix AD profile path + reset winget sources
    [switch]$InstallPackages, # install packages via winget
    [switch]$FixPath,        # fix git, vim, starship path
    [switch]$StarshipConfig, # starship config
    [switch]$Aliases,        # setup aliases
    [switch]$Vimrc,          # add .vimrc
    [switch]$MacosHotkeys,   # add macos-hotkeys.ahk
    [switch]$Cleanup,        # configure disk cleanup
    [switch]$Maintenance,    # schedule maintenance tasks
    [switch]$RestoreVsCode,  # restore VS Code settings & extensions
    [switch]$WingetUpdate,   # upgrade all installed packages
    [switch]$Privacy,        # privacy & UI registry tweaks
    [switch]$Fonts,          # install Meslo NF fonts
    [switch]$RSAT,           # install RSAT tools
    [switch]$GitConfig,      # configure SSH agent & git
    [switch]$MailStore,      # install MailStore Home
    [switch]$RdpSuspend,     # RDP auto-suspend scheduled task
    [switch]$Debloat,        # run win11 debloater
    [switch]$Network,        # disable IPv6 + join domain
    [switch]$OnlyConfig      # shorthand: FixPath+StarshipConfig+Aliases+Vimrc+MacosHotkeys
)
if ($OnlyConfig) { $FixPath = $StarshipConfig = $Aliases = $Vimrc = $MacosHotkeys = $true }
# If any switch is passed, only run the flagged sections; otherwise run everything.
$selective = $FixWinget -or $InstallPackages -or $FixPath -or $StarshipConfig -or $Aliases -or $Vimrc -or $MacosHotkeys -or
             $Cleanup -or $Maintenance -or $RestoreVsCode -or $WingetUpdate -or $Privacy -or $Fonts -or
             $RSAT -or $GitConfig -or $MailStore -or $RdpSuspend -or $Debloat -or $Network

$ErrorActionPreference = "Stop"
$ScriptRoot ??= $PSScriptRoot
$restartRequired = $false
$clinkDir = "$env:LOCALAPPDATA\clink"

# --- Helpers ---
function Show-Header ([string]$t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
function Show-OK ([string]$t) { Write-Host " [OK] $t" -ForegroundColor Green }
function Show-Error ([string]$t) { Write-Host " [ERROR] $t" -ForegroundColor Red }

function Reset-WindowsUpdate {
    Write-Host " [FIX] Resetting Windows Update & Killing Stuck Processes..." -ForegroundColor Yellow

    # Kill stuck processes
    "TiWorker","wusa","dism","trustedinstaller" | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    # Stop Services
    "wuauserv","bits","cryptsvc","msiserver" | ForEach-Object {
        Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
    }

    # Clear Cache (Aggressive)
    $sd = "C:\Windows\SoftwareDistribution"
    if (Test-Path $sd) {
        Rename-Item -Path $sd -NewName "SoftwareDistribution.old.$(Get-Date -Format 'HHmmss')" -Force -ErrorAction SilentlyContinue
    }

    # Restart Services
    "wuauserv","bits","cryptsvc","msiserver" | ForEach-Object {
        Start-Service -Name $_ -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 5
}

# --- Admin Check ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Show-Error "Administrative privileges required."; exit 1
}

Show-Header "Win 11 Setup (PS7 Refined)"

# Resolve winget path whenever any winget-related section will run.
if (-not $selective -or $FixWinget -or $InstallPackages -or $WingetUpdate) {

# When elevated on AD, $env:LOCALAPPDATA may resolve to the wrong profile.
# Use the logged-on user's profile explicitly via the registry.
$loggedOnUser = (Get-CimInstance Win32_ComputerSystem).UserName  # DOMAIN\username
$loggedOnSID  = (New-Object System.Security.Principal.NTAccount($loggedOnUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$loggedOnLocalAppData = (Get-ItemProperty "Registry::HKEY_USERS\$loggedOnSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name "Local AppData" -EA 0)."Local AppData"
if (-not $loggedOnLocalAppData) { $loggedOnLocalAppData = $env:LOCALAPPDATA }  # fallback

$wingetPath = "$loggedOnLocalAppData\Microsoft\WindowsApps\winget.exe"
if (Test-Path $wingetPath) {
    Set-Alias -Name winget -Value $wingetPath -Force
} else {
    Write-Error "winget.exe not found at $wingetPath — open ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
    exit 1
}

} # end winget path resolution

# =========================
# AD winget fix
# =========================
if (-not $selective -or $FixWinget) {

Show-Header "Configuring winget..."
try {
    winget source reset --force *>$null
    winget source add --name winget https://winget.azureedge.net/cache *>$null
    winget source update 2>$null
} catch {}
Show-OK "winget sources refreshed."

} # end FixWinget

# =====================
# winget installations
# =====================
if (-not $selective -or $InstallPackages) {

Show-Header "Installing programs..."
$packages = @(
    "Mozilla.Firefox", "namazso.OpenHashTab", "Microsoft.VisualStudioCode.Insiders",
    "gerardog.gsudo", "Starship.Starship", "chrisant996.Clink", "DEVCOM.JetBrainsMonoNerdFont",
    "CodeSector.TeraCopy", "Valve.Steam", "7zip.7zip", "JAMSoftware.TreeSize.Free",
    "veeam.veeamagent", "vim.vim", "Git.Git", "sharkdp.bat", "lsd-rs.lsd", "AutoHotkey.AutoHotkey",
    "Google.GoogleDrive", "dandavison.delta", "aria2.aria2", "Google.Antigravity", "marha.VcXsrv",
    "XP8JNQFBQH6PVF", "9PKTQ5699M62"
)

# --scope machine: forces system-wide install, avoids per-user/elevated token confusion on AD.
# Check per-package with --id rather than bulk-parsing the full list (unreliable when elevated).
foreach ($id in $packages) {
    $check = winget list --id $id --accept-source-agreements 2>$null | Out-String
    if ($check -match [regex]::Escape($id)) {
        Write-Host " [SKIP] $id" -ForegroundColor DarkGray
    } else {
        Write-Host " [INSTALL] $id..."
        winget install --id $id --silent --scope machine --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { Show-OK $id } else { Show-Error "$id (exit $LASTEXITCODE)" }
    }
}

} # end InstallPackages

# ===========================
# fix git, vim, starship path
# ===========================
if (-not $selective -or $FixPath) {

Show-Header "Fixing PATH Environment Variable"
$path = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not $path) { $path = "" }
$vimSearch = Get-ChildItem 'C:\Program Files\Vim' -Filter vim.exe -Recurse -EA 0 | Select-Object -First 1
$v = $vimSearch ? $vimSearch.DirectoryName : $null

if ($v) { Write-Host " [DEBUG] Vim found at: $v" -ForegroundColor DarkGray }
else { Write-Host " [WARN] Vim not found in C:\Program Files\Vim" -ForegroundColor Yellow }

$targets = @($v, 'C:\Program Files\Git\cmd', 'C:\Program Files\starship\bin') | Where-Object { $_ -and (Test-Path $_) }

$mustKeep = @("$env:LOCALAPPDATA\Microsoft\WindowsApps")
$pathParts = $path -split ';' | Where-Object { $_ }
$clean = $pathParts | Where-Object { ($_ -notmatch 'Git\\usr\\bin') -and ($targets -notcontains $_) }
foreach ($p in $mustKeep) { if ($p -and ($clean -notcontains $p)) { $clean += $p } }

$combined = @()
foreach ($p in ($clean + $targets)) { if ($p -and ($combined -notcontains $p)) { $combined += $p } }
$newPath = $combined -join ';'

if ($path -ne $newPath) {
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    # Refresh current session PATH
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + $newPath
    Show-OK "PATH updated and refreshed."
} else {
    Write-Host " [SKIP] PATH already correct." -ForegroundColor DarkGray
}

} # end FixPath

# ===============
# starship config
# ===============
if (-not $selective -or $StarshipConfig) {

Show-Header "Configuring Starship..."
$configDir = "$env:USERPROFILE\.config"
$null = New-Item -Path $clinkDir, $configDir -ItemType Directory -Force

"load(io.popen('starship init cmd'):read(`"*a`"))()" | Set-Content "$clinkDir\starship.lua" -Force

$display = "$ScriptRoot\configs\clink_display.lua"
if (Test-Path $display) { Copy-Item $display "$clinkDir\display.lua" -Force }

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

} # end StarshipConfig

# =============
# setup aliases
# =============
if (-not $selective -or $Aliases) {

$aliasesSrc = "$ScriptRoot\configs\aliases"
$aliasesDst = "$clinkDir\aliases"
if (Test-Path $aliasesSrc) {
    Copy-Item $aliasesSrc $aliasesDst -Force
    Show-OK "Aliases copied."
} else {
    @("ls=lsd -l", "ll=lsd -la --size=short --date=relative", "vi=vim $*", "cat=bat $*") | Set-Content $aliasesDst
    Show-OK "Aliases generated."
}

$clinkBat = (Test-Path "${env:ProgramFiles(x86)}\clink\clink.bat") ? "${env:ProgramFiles(x86)}\clink\clink.bat" : ((Test-Path "${env:ProgramW6432}\clink\clink.bat") ? "${env:ProgramW6432}\clink\clink.bat" : $null)
if ($clinkBat) {
    $cmd = "`"$clinkBat`" inject --profile `"$clinkDir`" && doskey /macrofile=`"$aliasesDst`""
    reg add "HKCU\Software\Microsoft\Command Processor" /v Autorun /t REG_SZ /d $cmd /f | Out-Null
    Show-OK "Clink Autorun configured."
}

} # end Aliases

# ==========
# add .vimrc
# ==========
if (-not $selective -or $Vimrc) {

Show-Header "Setting up .vimrc"
$vimrcSrc = "$ScriptRoot\configs\.vimrc"
if (Test-Path $vimrcSrc) {
    Copy-Item $vimrcSrc "$env:USERPROFILE\.vimrc" -Force; Show-OK ".vimrc installed."
} else {
    Show-Error ".vimrc source not found."
}

} # end Vimrc

# =====================
# add macos-hotkeys.ahk
# =====================
if (-not $selective -or $MacosHotkeys) {

$ahkSrc = "$ScriptRoot\configs\macos-hotkeys.ahk"
if (Test-Path $ahkSrc) { Copy-Item $ahkSrc "$env:USERPROFILE\Desktop\macos-hotkeys.ahk" -Force; Show-OK "Hotkey script copied." }

} # end MacosHotkeys

# ============================
# Configure Disk Cleanup
# ============================
if (-not $selective -or $Cleanup) {

Show-Header "Configuring Cleanup..."
$regCleanup = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$caches = @("Active Setup Temp Folders", "BranchCache", "D3D Shader Cache", "Delivery Optimization Files", "Downloaded Program Files", "Internet Cache Files", "Memory Dump Files", "Old Chkdsk Files", "Setup Log Files", "System error memory dump files", "Temporary Files", "Temporary Setup Files", "Thumbnail Cache", "Update Cleanup", "Upgrade Discarded Files", "Windows Defender", "Windows Error Reporting Files")
$caches | % { reg add "$regCleanup\$_" /v StateFlags0001 /t REG_DWORD /d 2 /f | Out-Null }
reg add "$regCleanup\Recycle Bin" /v StateFlags0001 /t REG_DWORD /d 0 /f | Out-Null
reg add "$regCleanup\DownloadsFolder" /v StateFlags0001 /t REG_DWORD /d 0 /f | Out-Null
Show-OK "Disk Cleanup configured."

} # end Cleanup

# ============================
# Maintenance Scripts & Tasks
# ============================
if (-not $selective -or $Maintenance) {

@(@{Src="cleanup-win.bat"; TN="WeeklyCleanup"; Sch="WEEKLY"}, @{Src="daily-update.bat"; TN="DailyWingetUpdate"; Sch="DAILY"}) | % {
    $src = "$ScriptRoot\configs\$($_.Src)"
    if (Test-Path $src) {
        Copy-Item $src "$env:USERPROFILE\$($_.Src)" -Force
        schtasks /create /tn $_.TN /tr "`"$env:USERPROFILE\$($_.Src)`"" /sc $_.Sch /st 12:00 /rl HIGHEST /f | Out-Null
    }
}
Show-OK "Maintenance tasks scheduled."

} # end Maintenance

# =====================================
# Restore VS Code Settings & Extensions
# =====================================
if (-not $selective -or $RestoreVsCode) {

$restore = "$ScriptRoot\helpers\restore-settings.ps1"
if (Test-Path $restore) { & $restore; Show-OK "VS Code restored." }

} # end RestoreVsCode

# ==============
# winget Update
# ==============
if (-not $selective -or $WingetUpdate) {

Show-Header "System Update..."
winget pin add --id Microsoft.AppInstaller --blocking *>$null 2>&1
# --scope machine skips MSIX/Store packages (they fail with 0x80070005 when elevated on AD)
winget upgrade --all --silent --scope machine --accept-package-agreements --accept-source-agreements
winget pin remove --id Microsoft.AppInstaller *>$null 2>&1
Show-OK "Software updated."

} # end WingetUpdate

# ============================
# Privacy & UI Registry Tweaks
# ============================
if (-not $selective -or $Privacy) {

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

} # end Privacy

# ===========================
# Download & Install Meslo Font
# ===========================
if (-not $selective -or $Fonts) {

$fontsInstalled = $false

# Strategy 1: Registry Check (Fastest)
$fontRegUser = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
$fontRegSystem = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
if ((Test-Path $fontRegUser) -and (Get-ItemProperty $fontRegUser -Name "*MesloLGS NF*" -ErrorAction SilentlyContinue)) { $fontsInstalled = $true }
if (-not $fontsInstalled -and (Test-Path $fontRegSystem) -and (Get-ItemProperty $fontRegSystem -Name "*MesloLGS NF*" -ErrorAction SilentlyContinue)) { $fontsInstalled = $true }

# Strategy 2: Physical File Check (Wildcard)
if (-not $fontsInstalled) {
    if (Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\*MesloLGS NF*") { $fontsInstalled = $true }
    if (Test-Path "C:\Windows\Fonts\*MesloLGS NF*") { $fontsInstalled = $true }
}

# Strategy 3: .NET GDI Check (Most Accurate but slower)
if (-not $fontsInstalled) {
    try {
        Add-Type -AssemblyName System.Drawing
        $installedFonts = (New-Object System.Drawing.Text.InstalledFontCollection).Families
        if ($installedFonts | Where-Object { $_.Name -like "MesloLGS NF*" }) { $fontsInstalled = $true }
    } catch {}
}

if ($fontsInstalled) {
    Write-Host " [SKIP] Meslo Fonts already registered." -ForegroundColor DarkGray
} else {
    $links = @("Regular", "Bold", "Italic", "Bold%20Italic") | % { "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20$_.ttf" }
    $dl = "$env:TEMP\Fonts"; $null = New-Item $dl -ItemType Directory -Force
    $links | ForEach-Object -Parallel { Invoke-WebRequest $_ -OutFile "$using:dl\$(($_ -split '/')[-1])" -UseBasicParsing } -ThrottleLimit 4
    $s = (New-Object -Com Shell.Application).Namespace(0x14)
    Get-ChildItem $dl -Filter *.ttf | ForEach-Object { $s.CopyHere($_.FullName) }
    Show-OK "Fonts installed."
}

} # end Fonts

# ============================
# Install RSAT Tools (Separate Window)
# ============================
if (-not $selective -or $RSAT) {

Show-Header "Launching RSAT Tools Installation in New Window..."

$rsatWorker = "$env:TEMP\Install-RSAT-Worker.ps1"
$rsatContent = @'
    $ErrorActionPreference = "Stop"

    # --- Embedded Helpers ---
    function Show-Header ([string]$t) { Write-Host "`n=== $t ===" -ForegroundColor Cyan }
    function Show-OK ([string]$t) { Write-Host " [OK] $t" -ForegroundColor Green }
    function Show-Error ([string]$t) { Write-Host " [ERROR] $t" -ForegroundColor Red }

    function Reset-WindowsUpdate {
        Write-Host " [FIX] Resetting Windows Update & Killing Stuck Processes..." -ForegroundColor Yellow

        "TiWorker","wusa","dism","trustedinstaller" | ForEach-Object {
            Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        "wuauserv","bits","cryptsvc","msiserver" | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
        }

        $sd = "C:\Windows\SoftwareDistribution"
        if (Test-Path $sd) {
             # Rename with timestamp to avoid collision
            Rename-Item -Path $sd -NewName "SoftwareDistribution.old.$(Get-Date -Format 'HHmmss')" -Force -ErrorAction SilentlyContinue
        }

        "wuauserv","bits","cryptsvc","msiserver" | ForEach-Object {
            Start-Service -Name $_ -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        Start-Sleep -Seconds 5
    }

    Show-Header "RSAT Tools Installation"
    Write-Host "This window will stay open so you can review the results." -ForegroundColor Gray

    $rsatFeatures = @(
        "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0",
        "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0",
        "Rsat.Dns.Tools~~~~0.0.1.0",
        "Rsat.ServerManager.Tools~~~~0.0.1.0"
    )

    # Preemptive cleanup if any are missing
    $missingRsat = $rsatFeatures | Where-Object {
        (Get-WindowsCapability -Online -Name $_ -ErrorAction SilentlyContinue).State -ne 'Installed'
    }
    if ($missingRsat) {
        Write-Host " [PRE-FIX] Detected missing RSAT tools. Running preemptive cleanup..." -ForegroundColor Yellow
        Reset-WindowsUpdate
    }

    foreach ($feature in $rsatFeatures) {
        try {
            $state = Get-WindowsCapability -Online -Name $feature -ErrorAction SilentlyContinue
            $shortName = $feature.Split('.')[1]

            if ($state.State -eq "Installed") {
                Write-Host " [SKIP] $shortName" -ForegroundColor DarkGray
            } else {
                Write-Host " [INSTALL] $shortName..."

                try {
                    Add-WindowsCapability -Online -Name $feature -ErrorAction Stop
                    Show-OK "$shortName installed."
                } catch {
                     Show-Error "First attempt failed. Retrying..."
                     Reset-WindowsUpdate
                     try {
                        Add-WindowsCapability -Online -Name $feature -ErrorAction Stop
                        Show-OK "$shortName installed/repaired."
                     } catch {
                        Show-Error "Failed to install ${shortName}: $_"
                     }
                }
            }
        } catch {
             Show-Error "Exception checking $($feature): $_"
        }
    }
    Show-OK "RSAT Installation Process Finished."
    Write-Host "You can close this window now." -ForegroundColor Cyan
'@

Set-Content -Path $rsatWorker -Value $rsatContent -Force
try {
    Start-Process powershell -ArgumentList "-NoProfile", "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "$rsatWorker" -WindowStyle Normal -ErrorAction Stop
    Write-Host " [INFO] RSAT installation spawned in a new window." -ForegroundColor Gray
} catch {
    Show-Error "Failed to spawn RSAT window: $_"
}

} # end RSAT

# ============================
# SSH Agent & Git Config
# ============================
if (-not $selective -or $GitConfig) {

if (Get-Service ssh-agent -EA 0) { Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent }
if (-not (git config --global user.name)) { git config --global user.name (Read-Host "Git Name"); git config --global user.email (Read-Host "Git Email") }
git config --global core.pager "delta"; git config --global delta.navigate true; Show-OK "SSH & Git configured."

} # end GitConfig

# ======================
# Install MailStore Home
# ======================
if (-not $selective -or $MailStore) {

if (-not (Test-Path "${env:ProgramFiles(x86)}\MailStore\MailStore Home\MailStoreHome.exe")) {
    $ms = "$env:USERPROFILE\Downloads\MailStoreHomeSetup.exe"
    Start-Process aria2c "-x 16 -s 16 -d `"$env:USERPROFILE\Downloads`" -o MailStoreHomeSetup.exe https://my.mailstore.com/Downloads/Home" -Wait
    if (Test-Path $ms) { Start-Process $ms -Wait }
}

} # end MailStore

# ============================
# RDP Auto-Suspend
# ============================
if (-not $selective -or $RdpSuspend) {

$autoSuspendTask = "AutoSuspend-RDP"
$existingTask = schtasks /query /tn $autoSuspendTask 2>&1
if ($existingTask -match "ERROR|does not exist") {
    $LinuxHost = "192.168.1.5"
    $LinuxUser = "nasadmin"
    $VMName = "Win11"

    $SuspendScript = "$env:ProgramData\rdp-suspend.ps1"
    "ssh ${LinuxUser}@${LinuxHost} `"virsh -c qemu:///system suspend ${VMName}`"" | Set-Content $SuspendScript

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

} # end RdpSuspend

# ======================
# Debloater
# ======================
if (-not $selective -or $Debloat) {

$debloatMarker = "$env:USERPROFILE\.debloat-done"
if (-not (Test-Path $debloatMarker)) {
    Show-Header "Launching Debloater"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "irm https://win11debloat.raphi.re/ | iex"
    $null = New-Item $debloatMarker -ItemType File -Force
} else {
    Write-Host " [SKIP] Debloater already run" -ForegroundColor DarkGray
}

} # end Debloat

# ============================
# Network & Domain Configuration
# ============================
if (-not $selective -or $Network) {

Show-Header "Network & Domain Config"

# 1. IPv6 Nuclear Option
$ipv6Key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
$ipv6Val = "DisabledComponents"
$ipv6Data = 0xFF # 255 - Completely disable IPv6
$regVal = (Get-ItemProperty $ipv6Key -Name $ipv6Val -ErrorAction SilentlyContinue).$ipv6Val

if ($regVal -ne $ipv6Data) {
    if (-not (Test-Path $ipv6Key)) { New-Item $ipv6Key -Force | Out-Null }
    Set-ItemProperty -Path $ipv6Key -Name $ipv6Val -Value $ipv6Data -Type DWord -Force
    Show-OK "IPv6 Registry updated to 0xFF."
    $restartRequired = $true
} else {
    Write-Host " [OK] IPv6 Registry is correctly set to 0xFF." -ForegroundColor Green
}

# 2. Join Domain
$domain = "h-lab.org"
$compSys = Get-CimInstance Win32_ComputerSystem
if ($compSys.PartOfDomain -and ($compSys.Domain -eq $domain)) {
    Write-Host " [SKIP] Already joined to $domain" -ForegroundColor DarkGray
} else {
    Write-Host " [DOMAIN] Joining $domain..."
    try {
        Add-Computer -DomainName $domain -ErrorAction Stop
        Show-OK "Joined $domain. One final reboot required."
        $restartRequired = $true
    } catch {
        Show-Error "Failed to join domain: $_"
        Write-Host "Please check connectivity, credentials, or IPv6 status." -ForegroundColor Yellow
    }
}

} # end Network

Show-Header "Setup Complete!"

if (-not $selective -or $Network) {
    if ($restartRequired) {
        Write-Host "RESTART REQUIRED: IPv6 disabled or Domain Join performed." -ForegroundColor Red
        $response = Read-Host "Restart now? (y/n)"
        if ($response -match "^y") { Restart-Computer -Force }
    } else {
        Write-Host "No critical system changes requiring restart were applied." -ForegroundColor Green
    }
}
if (-not $selective -or $RSAT) {
    Write-Host "Make sure to check the RSAT window for completion!" -ForegroundColor Cyan
}
Read-Host "Press Enter to exit"
