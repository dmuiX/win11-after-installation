@echo off
setlocal enabledelayedexpansion

echo *** Windows 11 Setup Skript startet ***

:: winget Quellen aktualisieren
echo Konfiguriere winget Quellen...
winget source update

:: winget Installationen
echo Installiere Programme...
winget install Mozilla.Firefox --silent --accept-package-agreements --accept-source-agreements
winget install openhashtab--silent --accept-package-agreements --accept-source-agreements
winget install Microsoft.VisualStudioCode.Insiders --silent --accept-package-agreements --accept-source-agreements
winget install gerardog.gsudo --silent --accept-package-agreements --accept-source-agreements
winget install Starship.Starship --silent --accept-package-agreements --accept-source-agreements
winget install chrisant996.Clink --silent --accept-package-agreements --accept-source-agreements
winget install DEVCOM.JetBrainsMonoNerdFont --silent --accept-package-agreements --accept-source-agreements
winget install CodeSector.TeraCopy --silent --accept-package-agreements --accept-source-agreements
winget install Valve.Steam --silent --accept-package-agreements --accept-source-agreements
winget install 7zip --silent --accept-package-agreements --accept-source-agreements
winget install treesizefree --silent --accept-package-agreements --accept-source-agreements
winget install xp8jnqfbqh6pvf --silent --accept-package-agreements --accept-source-agreements ::Perplexity MSStore
winget install veeam.veeamagent --silent --accept-package-agreements --accept-source-agreements
winget install vim.vim --silent --accept-package-agreements --accept-source-agreements
winget install git.git --silent --accept-package-agreements --accept-source-agreements
winget install 9pktq5699m62 --accept-package-agreements --accept-source-agreements ::Apple iCloud MSStore
winget install Microsoft.PowerToys --accept-package-agreements --accept-source-agreements
winget install kubectl --accept-package-agreements --accept-source-agreements
winget install Helm.Helm --accept-package-agreements --accept-source-agreements
winget install hashicorp.terraform --accept-package-agreements --accept-source-agreements
winget install autohotkey.autohotkey --accept-package-agreements --accept-source-agreements
winget install sharkdp.bat --accept-package-agreements --accept-source-agreements
winget install lsd-rs.lsd --accept-package-agreements --accept-source-agreements
winget install autohotkey.autohotkey --accept-package-agreements --accept-source-agreements


:: starship config
echo Erstelle Starship Konfiguration...
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


:: setup aliases
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

set "AUTORUN_COMMAND=""%CLINK_PATH%" inject --profile "%LOCALAPPDATA%\clink" && doskey /macrofile="%ALIASES_FILE%""

reg add "HKCU\Software\Microsoft\Command Processor" /v Autorun /t REG_SZ /d %AUTORUN_COMMAND% /f

if %errorlevel% equ 0 (
    echo Successfully updated the registry for Autorun.
) else (
    echo Failed to update the registry. Please run this script as an administrator.
)

echo.
echo Setup complete. Please open a new Command Prompt to see the changes.

:: add .vimrc

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
    echo if has('win32') ^&^& empty(glob('~/vimfiles/autoload/plug.vim'))
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

:: add macos-hotkeys.ahk

REM Define the full path for the AutoHotkey script file on the user's Desktop
set "AHK_FILE=%USERPROFILE%\Desktop\macos-hotkeys.ahk"

REM This block writes the multiline content to the file.
REM The > operator creates the file or overwrites it if it already exists.
REM The caret character (^) is escaped by doubling it (^^) so batch treats it literally.
(
    echo #Requires AutoHotkey v2.0
    echo #SingleInstance Force
    echo.
    echo ; --- Universal Shortcuts ---
    echo $!x::Send("^^x")         ; Alt+X -> Ctrl+X (Cut)
    echo $!c::Send("^^c")         ; Alt+C -> Ctrl+C (Copy)
    echo $!v::Send("^^v")         ; Alt+V -> Ctrl+V (Paste)
    echo $!s::Send("^^s")         ; Alt+S -> Ctrl+S (Save)
    echo $!a::Send("^^a")         ; Alt+A -> Ctrl+A (Select All)
    echo $!z::Send("^^z")         ; Alt+Z -> Ctrl+Z (Undo)
    echo $!+z::Send("^^y")        ; Alt+Shift+Z -> Ctrl+Y (Redo)
    echo $!w::Send("^^w")         ; Alt+W -> Ctrl+W (Close Window/Tab)
    echo $!f::Send("^^f")         ; Alt+F -> Ctrl+F (Find)
    echo $!n::Send("^^n")         ; Alt+N -> Ctrl+N (New)
    echo $!q::Send("!{f4}")      ; Alt+Q -> Alt+F4 (Quit App)
    echo $!r::Send("^^({f5})")      ; Alt+R -> Ctrl+F5 (Hard Refresh)
    echo $!m::Send("#d")         ; Alt+D -> Win+D (Show Desktop / Minimize All)
    echo $!`::Send("{Alt Down}{Shift Down}{Tab}{Shift Up}") ; Alt+` -> Cycle backwards through windows of an app
    echo.
    echo ; --- Quick Switch Tab shortcuts ---
    echo $!1::Send("^^1")
    echo $!2::Send("^^2")
    echo $!3::Send("^^3")
    echo $!4::Send("^^4")
    echo $!5::Send("^^5")
    echo $!6::Send("^^6")
    echo $!7::Send("^^7")
    echo $!8::Send("^^8")
    echo $!9::Send("^^9")
    echo $!0::Send("^^0")
    echo.
    echo ; --- Browser/Tab-based App shortcuts ---
    echo $!t::Send("^^t")         ; Alt+T -> Ctrl+T (New Tab)
    echo $!+t::Send("^^+t")       ; Alt+Shift+T -> Re-open Closed Tab
    echo $!+]::Send("^^({Tab})")   ; Alt+] -> Ctrl+Tab (Next Tab)
    echo $!+[::Send("^^+({Tab})")  ; Alt+[ -> Ctrl+Shift+Tab (Previous Tab)
    echo $!l::Send("^^l")         ; Alt+L -> Focus Address Bar
    echo.
    echo ; --- Text Navigation and Selection ---
    echo $!Left::Send("{Home}")
    echo $!Right::Send("{End}")
    echo $!Up::Send("^^({Home})")
    echo $!Down::Send("^^({End})")
    echo.
    echo $!+Left::Send("+{Home}")
    echo $!+Right::Send("+{End}")
    echo $!+Up::Send("^^+{Home}")
    echo $!+Down::Send("^^+{End}")
    echo.
    echo #Left::Send("^^({Left})")
    echo #Right::Send("^^({Right})")
    echo #+Left::Send("^^+({Left})")
    echo #+Right::Send("^^+({Right})")
    echo #BS::Send("^^({BS})")     ; Win+Backspace -> Ctrl+Backspace (Delete previous word)
) > "%AHK_FILE%"

echo.
echo File '%AHK_FILE%' was created successfully on your Desktop.

:: ==============
:: winget Update
:: ==============

echo Update aller Programme...
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

:: gsudo konfigurieren
echo Konfiguriere gsudo...
gsudo config PathPrecedence True 2>nul || echo WARNUNG: gsudo Konfiguration fehlgeschlagen

:: OneDrive und Teams entfernen
echo Deinstalliere OneDrive und Teams...
winget uninstall Microsoft.OneDrive --silent 2>nul || echo OneDrive bereits deinstalliert
winget uninstall Microsoft.Teams --silent 2>nul || echo Teams bereits deinstalliert

:: Datenschutz Registry
echo Setze Datenschutzeinstellungen...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestContacts" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v "HarvestTyping" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Speech_OneCore\Preferences" /v "HasAccepted" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul

:: Taskbar links
echo Setze Taskbar auf links...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAl" /t REG_DWORD /d 0 /f >nul

:: Dunkles Theme
echo Setze dunkles Theme...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "AppsUseLightTheme" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "SystemUsesLightTheme" /t REG_DWORD /d 0 /f >nul

:: Explorer Einstellungen
echo Setze Explorer Einstellungen...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSuperHidden" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableXamlStartMenu" /t REG_

:: Start Debloater
irm "https://win11debloat.raphi.re/" | iex
