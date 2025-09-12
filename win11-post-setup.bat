@echo off
setlocal enabledelayedexpansion

echo *** Windows 11 Setup Skript startet ***

:: winget Installationen
echo Installiere Programme...
winget install Mozilla.Firefox --silent --accept-package-agreements --accept-source-agreements
winget install OpenHashTab.OpenHashTab --silent --accept-package-agreements --accept-source-agreements
winget install Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements
winget install gerardog.gsudo --silent --accept-package-agreements --accept-source-agreements
winget install Starship.Starship --silent --accept-package-agreements --accept-source-agreements
winget install JetBrains.JetBrainsMonoNerdFont --silent --accept-package-agreements --accept-source-agreements
winget install coddec.teracopy --silent --accept-package-agreements --accept-source-agreements

:: Taskbar Monitor Installer
echo Lade Taskbar Monitor Installer...
set "GITHUB_API=https://api.github.com/repos/leandrosa81/taskbar-monitor/releases/latest"
set "TM_PATH=%TEMP%\TaskbarMonitorInstaller.exe"

echo Hole Informationen von GitHub API...
curl -s "%GITHUB_API%" > "%TEMP%\tm_api.json"
if not errorlevel 0 (
    echo WARNUNG: GitHub API nicht erreichbar, überspringe Taskbar Monitor
    goto :after_taskbar
)

:: Extrahiere Download-URL
set "download_url="
for /f "usebackq tokens=*" %%A in ("%TEMP%\tm_api.json") do (
    echo %%A | findstr /c:"browser_download_url" | findstr /c:"TaskbarMonitorInstaller.exe" >nul && (
        for /f "tokens=2 delims=:" %%B in ("%%A") do (
            set "temp_url=%%B"
            set "temp_url=!temp_url:"=!"
            set "temp_url=!temp_url:,=!"
            set "temp_url=!temp_url: =!"
            set "download_url=https:!temp_url!"
        )
    )
)

if "!download_url!"=="" (
    echo WARNUNG: Download-URL nicht gefunden, überspringe Taskbar Monitor
    goto :after_taskbar
)

echo Download-URL: !download_url!
curl -L -o "%TM_PATH%" "!download_url!"
if not errorlevel 0 (
    echo WARNUNG: Download fehlgeschlagen, überspringe Taskbar Monitor
    goto :after_taskbar
)

echo Installiere Taskbar Monitor...
if exist "%TM_PATH%" (
    start /wait "" "%TM_PATH%" /VERYSILENT /NORESTART
    echo Taskbar Monitor Installation abgeschlossen
)

:after_taskbar

:: OVPN Client
echo Lade OVPN Client...
set "OVPN_PATH=%TEMP%\ovpn-client.exe"
set "OVPN_URL=https://download.ovpn.com/windows/ovpn-client-latest.exe"

echo Hole SHA256 von OVPN Webseite...
curl -s "https://www.ovpn.com/en/guides/windows" > "%TEMP%\ovpn_page.html"
if not errorlevel 0 (
    echo WARNUNG: OVPN Seite nicht erreichbar, lade trotzdem herunter...
    curl -L -o "%OVPN_PATH%" "%OVPN_URL%"
    if exist "%OVPN_PATH%" (
        start /wait "" "%OVPN_PATH%" /VERYSILENT /NORESTART
        echo OVPN Installation ohne SHA256-Prüfung abgeschlossen
    )
    goto :after_ovpn
)

:: SHA256 Extraktion
set "OVPN_SHA="
for /f "usebackq tokens=*" %%A in ("%TEMP%\ovpn_page.html") do (
    echo %%A | findstr /c:"SHA256 (64-bit)" >nul && (
        for /f "tokens=*" %%B in ("%%A") do (
            set "line=%%B"
            for /f "tokens=1,2,3,4,5,6,7" %%C in ("!line!") do (
                echo %%I | findstr /r "^[0-9a-fA-F][0-9a-fA-F]*$" >nul && set "OVPN_SHA=%%I"
                if "!OVPN_SHA!"=="" echo %%H | findstr /r "^[0-9a-fA-F][0-9a-fA-F]*$" >nul && set "OVPN_SHA=%%H"
                if "!OVPN_SHA!"=="" echo %%G | findstr /r "^[0-9a-fA-F][0-9a-fA-F]*$" >nul && set "OVPN_SHA=%%G"
                if "!OVPN_SHA!"=="" echo %%F | findstr /r "^[0-9a-fA-F][0-9a-fA-F]*$" >nul && set "OVPN_SHA=%%F"
                if "!OVPN_SHA!"=="" echo %%E | findstr /r "^[0-9a-fA-F][0-9a-fA-F]*$" >nul && set "OVPN_SHA=%%E"
                if "!OVPN_SHA!"=="" echo %%D | findstr /r "^[0-9a-fA-F][0-9a-fA-F]*$" >nul && set "OVPN_SHA=%%D"
            )
        )
    )
)

curl -L -o "%OVPN_PATH%" "%OVPN_URL%"
if not errorlevel 0 (
    echo WARNUNG: OVPN Download fehlgeschlagen
    goto :after_ovpn
)

if "!OVPN_SHA!"=="" (
    echo WARNUNG: SHA256 nicht gefunden, installiere ohne Prüfung...
    start /wait "" "%OVPN_PATH%" /VERYSILENT /NORESTART
    echo OVPN Installation ohne SHA256-Prüfung abgeschlossen
    goto :after_ovpn
)

echo SHA256: !OVPN_SHA!
echo Prüfe OVPN SHA256...
certutil -hashfile "%OVPN_PATH%" SHA256 > "%TEMP%\ovpn_hash.txt"
findstr /i "!OVPN_SHA!" "%TEMP%\ovpn_hash.txt" >nul
if errorlevel 1 (
    echo WARNUNG: SHA256 stimmt nicht überein, installiere trotzdem...
    start /wait "" "%OVPN_PATH%" /VERYSILENT /NORESTART
    echo OVPN Installation mit SHA256-Warnung abgeschlossen
) else (
    echo SHA256 OK - installiere OVPN...
    start /wait "" "%OVPN_PATH%" /VERYSILENT /NORESTART
    echo OVPN Installation erfolgreich abgeschlossen
)

:after_ovpn

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
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableXamlStartMenu" /t REG_DWORD /d 0 /f >nul

:: Starship Konfiguration
echo Erstelle Starship Konfiguration...
if not exist "%LOCALAPPDATA%\clink" mkdir "%LOCALAPPDATA%\clink"
if not exist "%USERPROFILE%\.config" mkdir "%USERPROFILE%\.config"

echo load(io.popen('starship init cmd'):read("*a"))() > "%LOCALAPPDATA%\clink\starship.lua"

:: Starship TOML
(
echo "$schema" = 'https://starship.rs/config-schema.json'
echo format = """
echo [](color_orange^)\
echo $os\
echo $username\
echo [](bg:color_yellow fg:color_orange^)\
echo $directory\
echo [](fg:color_yellow bg:color_aqua^)\
echo $git_branch\
echo $git_status\
echo [](fg:color_aqua bg:color_blue^)\
echo $c\
echo $cpp\
echo $rust\
echo $golang\
echo $nodejs\
echo $php\
echo $java\
echo $kotlin\
echo $haskell\
echo $python\
echo [](fg:color_blue bg:color_bg3^)\
echo $docker_context\
echo $conda\
echo $pixi\
echo [](fg:color_bg3 bg:color_bg1^)\
echo $time\
echo [ ](fg:color_bg1^)\
echo $line_break$character"""
echo palette = 'gruvbox_dark'
echo [palettes.gruvbox_dark]
echo color_fg0 = '#fbf1c7'
echo color_bg1 = '#3c3836'
echo color_bg3 = '#665c54'
echo color_blue = '#458588'
echo color_aqua = '#689d6a'
echo color_green = '#98971a'
echo color_orange = '#d65d0e'
echo color_purple = '#b16286'
echo color_red = '#cc241d'
echo color_yellow = '#d79921'
echo [os]
echo disabled = false
echo style = "bg:color_orange fg:color_fg0"
echo [os.symbols]
echo Windows = "󰍲"
echo Ubuntu = "󰕈"
echo SUSE = ""
echo Raspbian = "󰐿"
echo Mint = "󰣭"
echo Macos = "󰀵"
echo Manjaro = ""
echo Linux = "󰌽"
echo Gentoo = "󰣨"
echo Fedora = "󰣛"
echo Alpine = ""
echo Amazon = ""
echo Android = ""
echo Arch = "󰣇"
echo Artix = "󰣇"
echo EndeavourOS = ""
echo CentOS = ""
echo Debian = "󰣚"
echo Redhat = "󱄛"
echo RedHatEnterprise = "󱄛"
echo Pop = ""
echo [username]
echo show_always = true
echo style_user = "bg:color_orange fg:color_fg0"
echo style_root = "bg:color_orange fg:color_fg0"
echo format = '[ $user ]($style^)'
echo [directory]
echo style = "fg:color_fg0 bg:color_yellow"
echo format = "[ $path ]($style^)"
echo truncation_length = 3
echo truncation_symbol = "…/"
echo [directory.substitutions]
echo "Documents" = "󰈙 "
echo "Downloads" = " "
echo "Music" = "󰝚 "
echo "Pictures" = " "
echo "Developer" = "󰲋 "
echo [git_branch]
echo symbol = ""
echo style = "bg:color_aqua"
echo format = '[[ $symbol $branch ](fg:color_fg0 bg:color_aqua^)]($style^)'
echo [git_status]
echo style = "bg:color_aqua"
echo format = '[[($all_status$ahead_behind ^)](fg:color_fg0 bg:color_aqua^)]($style^)'
echo [nodejs]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [c]
echo symbol = " "
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [cpp]
echo symbol = " "
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [rust]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [golang]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [php]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [java]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [kotlin]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [haskell]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [python]
echo symbol = ""
echo style = "bg:color_blue"
echo format = '[[ $symbol( $version^) ](fg:color_fg0 bg:color_blue^)]($style^)'
echo [docker_context]
echo symbol = ""
echo style = "bg:color_bg3"
echo format = '[[ $symbol( $context^) ](fg:#83a598 bg:color_bg3^)]($style^)'
echo [conda]
echo style = "bg:color_bg3"
echo format = '[[ $symbol( $environment^) ](fg:#83a598 bg:color_bg3^)]($style^)'
echo [pixi]
echo style = "bg:color_bg3"
echo format = '[[ $symbol( $version^)( $environment^) ](fg:color_fg0 bg:color_bg3^)]($style^)'
echo [time]
echo disabled = false
echo time_format = "%%R"
echo style = "bg:color_bg1"
echo format = '[[  $time ](fg:color_fg0 bg:color_bg1^)]($style^)'
echo [line_break]
echo disabled = false
echo [character]
echo disabled = false
echo success_symbol = '[](bold fg:color_green^)'
echo error_symbol = '[](bold fg:color_red^)'
echo vimcmd_symbol = '[](bold fg:color_green^)'
echo vimcmd_replace_one_symbol = '[](bold fg:color_purple^)'
echo vimcmd_replace_symbol = '[](bold fg:color_purple^)'
echo vimcmd_visual_symbol = '[](bold fg:color_yellow^)'
) > "%USERPROFILE%\.config\starship.toml"

:: Aufräumen
del "%TEMP%\tm_api.json" 2>nul
del "%TEMP%\tm_hash.txt" 2>nul
del "%TEMP%\ovpn_page.html" 2>nul
del "%TEMP%\ovpn_hash.txt" 2>nul

echo.
echo *** Setup erfolgreich abgeschlossen! ***
echo.
echo Registry-Einstellungen aktiv, Neustart empfohlen.
echo Starship Shell-Konfiguration angelegt.
echo.
pause
