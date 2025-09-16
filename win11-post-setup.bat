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
winget install Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements
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

:: winget Update
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
