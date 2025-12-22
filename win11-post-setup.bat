@echo off
setlocal disableDelayedExpansion

::--------------------------------------------------------------------------------
:: Self-Elevation: Request admin rights if not already elevated
::--------------------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrative privileges.
) else (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" %*' -Verb runAs"
    exit /b
)

echo *** Start Win 11 setup script ***

:: =====================
:: update winget sources
:: =====================

echo Konfiguriere winget Quellen...
"%WINGET_CMD%" source update

:: =====================
:: update winget sources
:: =====================

echo Konfiguriere winget Quellen...
winget source update

:: =====================
:: winget installations
:: =====================

echo Installing programs (skipping already installed)...

:: Helper: Install only if not already installed
:: Usage: call :winget_install "package.id"
call :winget_install Microsoft.WindowsTerminal
call :winget_install Mozilla.Firefox
call :winget_install openhashtab
call :winget_install Microsoft.VisualStudioCode.Insiders
call :winget_install gerardog.gsudo
call :winget_install Starship.Starship
call :winget_install chrisant996.Clink
call :winget_install DEVCOM.JetBrainsMonoNerdFont
call :winget_install CodeSector.TeraCopy
call :winget_install Valve.Steam
call :winget_install 7zip.7zip
call :winget_install JAMSoftware.TreeSize.Free
echo [INSTALL] Perplexity (MS Store)...
winget install XP8JNQFBQH6PVF --silent --accept-package-agreements --accept-source-agreements
call :winget_install veeam.veeamagent
call :winget_install vim.vim
call :winget_install Git.Git
echo [INSTALL] iCloud Drive (MS Store)...
winget install 9PKTQ5699M62 --silent --accept-package-agreements --accept-source-agreements
call :winget_install sharkdp.bat
call :winget_install lsd-rs.lsd
call :winget_install AutoHotkey.AutoHotkey
call :winget_install Google.GoogleDrive
call :winget_install dandavison.delta
call :winget_install Google.Antigravity

goto :after_winget_helper

:winget_install
winget list --id %1 >nul 2>&1
if %errorlevel% equ 0 (
    echo [SKIP] %1 already installed.
) else (
    echo [INSTALL] %1...
    winget install --id %1 --silent --accept-package-agreements --accept-source-agreements
    if %errorlevel% neq 0 echo [ERROR] Failed to install %1
)
exit /b

:after_winget_helper

:: =================
:: fix git, vim, starship path
:: =================

@REM echo [FIX] PATH bereinigen...
@REM powershell -Command "$p=[Environment]::GetEnvironmentVariable('Path','User'); $cleanP=($p.Split(';') | ? { $_ -notmatch 'Git\\\\usr\\\\bin' } | ? { $_ } ) -join ';'; $v=(gci 'C:\Program Files\Vim' -Filter vim.exe -R -EA 0 | select -First 1).DirectoryName; $g='C:\Program Files\Git\cmd'; $s='C:\Program Files\starship\bin'; [Environment]::SetEnvironmentVariable('Path', $cleanP + ';' + $v + ';' + $g + ';' + $s, 'User'); Write-Host \"✅ Vim: $v | Git: $g | Starship: $s\""

:: ===============
:: starship config
:: ===============

echo Create starship config...
if not exist "%LOCALAPPDATA%\clink" mkdir "%LOCALAPPDATA%\clink"
if not exist "%USERPROFILE%\.config" mkdir "%USERPROFILE%\.config"

echo load(io.popen('starship init cmd'):read("*a"))() > "%LOCALAPPDATA%\clink\starship.lua"

echo Lade Gruvbox Rainbow Preset von starship.rs...
curl -L -o "%USERPROFILE%\.config\starship.toml" "https://starship.rs/presets/toml/gruvbox-rainbow.toml"

if exist "%USERPROFILE%\.config\starship.toml" (
    echo Starship Konfiguration erfolgreich heruntergeladen
) else (
    echo WARNUNG: Starship Konfiguration Download fehlgeschlagen
)

:: =============
:: setup aliases
:: =============

REM Define the path for the aliases file
set "ALIASES_FILE=%LOCALAPPDATA%\clink\aliases"

REM Create the directory if it doesn't exist
if not exist "%LOCALAPPDATA%\clink" mkdir "%LOCALAPPDATA%\clink"

REM Create the aliases file. The first line uses > to create a new file.
(
    echo ls=lsd -l
    echo ll=lsd -la --size=short --date=relative
    echo llrt=lsd -lart
    echo llrs=ll -lars
    echo vi=vim $*
    echo k=kubectl $*
    echo mv=move
    echo rm=del $*
    echo cat=bat $*
) > "%ALIASES_FILE%"

echo Alias file created at %ALIASES_FILE%
echo.

REM Set the Autorun registry key
REM This command tells cmd.exe to first inject Clink, then load the aliases using doskey.
REM Note: This assumes Clink is installed in the default location. Adjust the path if necessary.
set "CLINK_PATH=C:\Program Files (x86)\clink\clink.bat"
if exist "%ProgramFiles(x86)%\clink\clink.bat" (
    set "CLINK_PATH=%ProgramFiles(x86)%\clink\clink.bat"
) else if exist "%ProgramW6432%\clink\clink.bat" (
    set "CLINK_PATH=%ProgramW6432%\clink\clink.bat"
)

set "AUTORUN_COMMAND=\"%CLINK_PATH%\" inject --profile \"%LOCALAPPDATA%\clink\" ^&^& doskey /macrofile=\"%ALIASES_FILE%\""

reg add "HKCU\Software\Microsoft\Command Processor" /v Autorun /t REG_SZ /d "%AUTORUN_COMMAND%" /f

if %errorlevel% equ 0 (
    echo Successfully updated the registry for Autorun.
) else (
    echo Failed to update the registry. Please run this script as an administrator.
)

echo.
echo Setup complete. Please open a new Command Prompt to see the changes.

:: ==========
:: add .vimrc
:: ==========

REM Define the full path for the .vimrc file
set "VIMRC_FILE=%USERPROFILE%\.vimrc"

REM This block writes the entire multiline content to the file.
REM The `>` operator creates the file or overwrites it if it already exists.
REM Special characters like |, <, >, and & are escaped with a caret (^).
(
    echo " ============================================================================
    echo " Standard vim settings
    echo " ============================================================================
    echo.
    echo set number
    echo nnoremap ^<F3^> :set number!^<CR^>
    echo set smartindent
    echo set autoindent
    echo set shiftwidth=2
    echo set tabstop=2
    echo set pastetoggle=^<F2^>
    echo set expandtab
    echo set backspace=indent,eol,start
    echo set clipboard=unnamedplus
    echo set termguicolors
    echo.
    echo " ============================================================================
    echo " Syntax Highlighting
    echo " ============================================================================
    echo.
    echo syntax on
    echo highlight Normal ctermbg=None
    echo highlight LineNr ctermfg=DarkGrey
    echo.
    echo " ============================================================================
    echo " vim-plug Plugin Manager Setup
    echo " ============================================================================
    echo.
    echo " Auto-install vim-plug for Windows if not found
    echo if has('win32') ^&^& empty^(glob^('~/vimfiles/autoload/plug.vim'^)^)
    echo   " Define the PowerShell command to download and place plug.vim
    echo   let s:command = 'powershell -Command "iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim ^| ni $HOME/vimfiles/autoload/plug.vim -Force"'
    echo.  
    echo   " Execute the command
    echo   call system(s:command)
    echo.  
    echo   " Automatically run PlugInstall and re-source the vimrc after installation
    echo   autocmd VimEnter * PlugInstall --sync ^| source $MYVIMRC
    echo endif
    echo.
    echo call plug#begin('~/.vim/plugged')
    echo     Plug 'vim-airline/vim-airline'
    echo     Plug 'vim-airline/vim-airline-themes'
    echo     Plug 'farmergreg/vim-lastplace'
    echo     Plug 'elzr/vim-json'
    echo call plug#end()
    echo.
    echo " ============================================================================
    echo " Plugin Configuration
    echo " ============================================================================
    echo.
    echo " Airline
    echo let g:airline_powerline_fonts = 1
    echo let g:kite_auto_complete=1
    echo let g:airline#extensions#tabline#enabled = 1
    echo.
    echo " Lastplace config
    echo let g:lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit"
    echo let g:lastplace_ignore_buftype = "quickfix,nofile,help"
    echo let g:lastplace_open_folds = 0
) > "%VIMRC_FILE%"

echo.
echo File '%VIMRC_FILE%' was created successfully.


:: =====================
:: add macos-hotkeys.ahk
:: =====================

REM Define the full path for the AutoHotkey script file on the user's Desktop
set "AHK_FILE=%USERPROFILE%\Desktop\macos-hotkeys.ahk"

REM This block writes the multiline content to the file.
REM The > operator creates the file or overwrites it if it already exists.
REM The caret character (^) is escaped by doubling it (^^) so batch treats it literally.
echo.
echo Copying 'macos-hotkeys.ahk' to Desktop...
copy /Y "%~dp0helpers\macos-hotkeys.ahk" "%AHK_FILE%" >nul
if exist "%AHK_FILE%" (
    echo File '%AHK_FILE%' was copied successfully.
) else (
    echo FAILURE: Could not copy '%AHK_FILE%'.
)


:: ============================
:: Configure Disk Cleanup (SageRun:1)
:: ============================
echo Configuring Disk Cleanup profile...
REM Set StateFlags0001 = 2 (Selected) / 0 (Not Selected)
REM User Goal: Remove everything EXCEPT Downloads and Recycle Bin

:: --- EXCLUDED (Keep these) ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin" /v StateFlags0001 /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\DownloadsFolder" /v StateFlags0001 /t REG_DWORD /d 0 /f >nul

:: --- INCLUDED (Delete these) ---
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\D3D Shader Cache" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old Chkdsk Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files" /v StateFlags0001 /t REG_DWORD /d 2 /f >nul

:: ============================
:: add a cleanup-win.bat script
:: ============================

set "OUT_FILE=%USERPROFILE%\cleanup-win.bat"

echo.
echo Creating the maintenance script at: %OUT_FILE%
echo Please wait...

echo.
echo Copying 'cleanup-win.bat' to home folder...
copy /Y "%~dp0helpers\cleanup-win.bat" "%OUT_FILE%" >nul
if exist "%OUT_FILE%" (
    echo File '%OUT_FILE%' was copied successfully.
) else (
    echo FAILURE: Could not copy '%OUT_FILE%'.
)

echo.
echo The script 'cleanup-win.bat' has been created successfully!
echo You can find it in your home folder: %USERPROFILE%

:: Schedule the cleanup task weekly
echo Scheduling cleanup task...
schtasks /create /tn "WeeklyCleanup" /tr "\"%OUT_FILE%\"" /sc WEEKLY /st 12:00 /rl HIGHEST /f >nul
if %errorlevel% equ 0 (
    echo Task 'WeeklyCleanup' scheduled successfully.
) else (
    echo Failed to schedule 'WeeklyCleanup' task.
)


:: ============================
:: Setup Daily Winget Update
:: ============================
set "UPDATE_SCRIPT=%USERPROFILE%\daily-update.bat"

echo.
echo Copying 'daily-update.bat' to home folder...
copy /Y "%~dp0helpers\daily-update.bat" "%UPDATE_SCRIPT%" >nul

echo Scheduling daily update task...
schtasks /create /tn "DailyWingetUpdate" /tr "\"%UPDATE_SCRIPT%\"" /sc DAILY /st 13:00 /rl HIGHEST /f >nul
if %errorlevel% equ 0 (
    echo Task 'DailyWingetUpdate' scheduled successfully.
) else (
    echo Failed to schedule 'DailyWingetUpdate' task.
)

:: ============================
:: Restore VS Code Settings & Extensions
:: ============================
echo.
echo Running restore settings script...
call "%~dp0helpers\restore-settings.bat"


:: ==============
:: winget Update
:: ==============

echo Update all Programs...
winget pin add --id Microsoft.AppInstaller --blocking >nul 2>&1
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
winget pin remove --id Microsoft.AppInstaller >nul 2>&1


:: ===============
:: configure gsudo
:: ===============

echo Konfiguriere gsudo...
gsudo config PathPrecedence True 2>nul || echo WARNUNG: gsudo Konfiguration fehlgeschlagen


:: =========================
:: remove OneDrive and Teams
:: ==========================

echo Deinstall OneDrive and Teams...
winget uninstall Microsoft.OneDrive --silent 2>nul || echo OneDrive bereits deinstalliert
winget uninstall Microsoft.Teams --silent 2>nul || echo Teams bereits deinstalliert

:: ============================
:: Privacy registry entries
:: ============================

echo Setze Datenschutzeinstellungen...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestTyping" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Speech_OneCore\Preferences" /v "HasAccepted" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul

:: =============
:: Taskbar links
:: =============
echo Setze Taskbar auf links...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d 0 /f >nul

:: ==========
:: Dark Theme
:: ==========

echo Set dark Theme...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f >nul

:: ============================
:: Extended Privacy Settings
:: ============================
echo Disabling Telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul

echo Disabling Advertising ID...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul

echo Disabling Windows Consumer Features (Start Menu Ads)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul

echo Disabling Location Tracking...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocation" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v "DisableLocationScripting" /t REG_DWORD /d 1 /f >nul

echo Disabling Tailored Experiences...
reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiencesWithDiagnosticData" /t REG_DWORD /d 1 /f >nul

echo Disabling Settings Suggestions...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f >nul


:: ======================
:: Explorer settings
:: ======================
echo Setup explorer...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSuperHidden" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableXamlStartMenu" /t REG_DWORD /d 0 /f >nul


:: ======================
:: Download & Install Meslo Font
:: ======================
echo.
echo Checking Meslo LG S Nerd Font...

:: Check if any Meslo font file exists in Windows Fonts folder
if exist "C:\Windows\Fonts\MesloLGS NF Regular.ttf" (
    echo Meslo LG S Nerd Font is already installed. Skipping.
    goto :SkipMesloInstall
)
if exist "%LOCALAPPDATA%\Microsoft\Windows\Fonts\MesloLGS NF Regular.ttf" (
    echo Meslo LG S Nerd Font is already installed ^(user fonts^). Skipping.
    goto :SkipMesloInstall
)

echo Downloading Meslo LG S Nerd Font...
mkdir "%USERPROFILE%\Downloads\MesloFont" 2>nul
curl -L -o "%USERPROFILE%\Downloads\MesloFont\MesloLGS NF Regular.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%%20NF%%20Regular.ttf"
curl -L -o "%USERPROFILE%\Downloads\MesloFont\MesloLGS NF Bold.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%%20NF%%20Bold.ttf"
curl -L -o "%USERPROFILE%\Downloads\MesloFont\MesloLGS NF Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%%20NF%%20Italic.ttf"
curl -L -o "%USERPROFILE%\Downloads\MesloFont\MesloLGS NF Bold Italic.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%%20NF%%20Bold%%20Italic.ttf"

echo Installing fonts...
powershell -Command "$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14); Get-ChildItem '%USERPROFILE%\Downloads\MesloFont\*.ttf' | ForEach-Object { Write-Host ('Installing ' + $_.Name + '...'); $fonts.CopyHere($_.FullName) }"
echo Font installation complete.

:SkipMesloInstall

:: ============================
:: SSH Agent Setup
:: ============================
echo.
echo Setting up OpenSSH Agent...
powershell -Command "if (Get-Service ssh-agent -ErrorAction SilentlyContinue) { Set-Service -Name ssh-agent -StartupType Automatic; Start-Service ssh-agent; Write-Host 'SSH Agent has been set to Automatic and Started.' } else { Write-Host 'SSH Agent service not found.' }"

:: ============================
:: Git Configuration
:: ============================
echo.
echo Configuring Git...

:: Check if git user.name is set
git config --global user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo Git user.name not set. Please enter details:
    set /p GIT_NAME="Enter your Name: "
    set /p GIT_EMAIL="Enter your Email: "
    
    :: Use 'call' to ensure variables are expanded correctly if we were in a block (though we aren't here)
    git config --global user.name "%GIT_NAME%"
    git config --global user.email "%GIT_EMAIL%"
    echo Git identity set.
) else (
    echo Git identity already configured.
)

:: Configure Delta as pager
echo Configuring Delta as git pager...
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global merge.conflictstyle diff3
git config --global diff.colorMoved default

echo Git configuration complete.

:: ======================
:: Start Debloater script
:: ======================

start "Win11Debloat" powershell -Command "irm \"https://win11debloat.raphi.re/\" | iex"
