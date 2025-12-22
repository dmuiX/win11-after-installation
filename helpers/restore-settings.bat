@echo off
setlocal enabledelayedexpansion

:: ============================
:: Restore VS Code Settings & Extensions
:: ============================
set "VSCODE_CONFIG_DIR=%~dp0..\vscode-config"

if not exist "%VSCODE_CONFIG_DIR%" (
    echo No 'vscode-config' folder found in repo. Skipping VS Code restore.
    exit /b
)

echo.
echo Restoring VS Code Configuration from repo...

:: --- VS Code Insiders Extensions ---
if not exist "%VSCODE_CONFIG_DIR%\vscode-insiders-extensions.txt" goto :SkipVSCodeInsidersExtensions

echo Installing VS Code Insiders Extensions...

:: Find VS Code Insiders CLI
set "CODE_INSIDERS_CMD="
where code-insiders >nul 2>nul
if !errorlevel! equ 0 set "CODE_INSIDERS_CMD=code-insiders"

if not defined CODE_INSIDERS_CMD (
    if exist "%LOCALAPPDATA%\Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd" (
        set "CODE_INSIDERS_CMD=%LOCALAPPDATA%\Programs\Microsoft VS Code Insiders\bin\code-insiders.cmd"
    )
)

if defined CODE_INSIDERS_CMD (
    :: Parse folder names to extract extension IDs (format: publisher.name-version)
    for /f "usebackq tokens=*" %%A in ("%VSCODE_CONFIG_DIR%\vscode-insiders-extensions.txt") do (
        for /f "tokens=1,2 delims=-" %%B in ("%%A") do (
            echo Installing %%B...
            call "!CODE_INSIDERS_CMD!" --install-extension %%B --force >nul 2>&1
        )
    )
    echo VS Code Insiders extensions installed.
) else (
    echo [WARNING] VS Code Insiders not found. Skipping extension installation.
)

:SkipVSCodeInsidersExtensions

:: --- VS Code Insiders Settings ---
if exist "%VSCODE_CONFIG_DIR%\vscode-insiders-settings.json" (
    if not exist "%APPDATA%\Code - Insiders\User\settings.json" (
        echo Restoring VS Code Insiders Settings...
        if not exist "%APPDATA%\Code - Insiders\User" mkdir "%APPDATA%\Code - Insiders\User" >nul
        copy /Y "%VSCODE_CONFIG_DIR%\vscode-insiders-settings.json" "%APPDATA%\Code - Insiders\User\settings.json" >nul
    ) else (
        echo VS Code Insiders settings already exist. Skipping.
    )
)
if exist "%VSCODE_CONFIG_DIR%\vscode-insiders-keybindings.json" (
    if not exist "%APPDATA%\Code - Insiders\User\keybindings.json" (
        copy /Y "%VSCODE_CONFIG_DIR%\vscode-insiders-keybindings.json" "%APPDATA%\Code - Insiders\User\keybindings.json" >nul
    )
)

:: --- Antigravity Extensions ---
if exist "%VSCODE_CONFIG_DIR%\antigravity-extensions.txt" (
    echo Installing Antigravity Extensions...
    
    :: Antigravity uses same CLI as VS Code
    set "ANTIGRAVITY_CMD="
    where antigravity >nul 2>nul
    if !errorlevel! equ 0 set "ANTIGRAVITY_CMD=antigravity"
    
    if not defined ANTIGRAVITY_CMD (
        if exist "%LOCALAPPDATA%\Programs\Antigravity\bin\antigravity.cmd" (
            set "ANTIGRAVITY_CMD=%LOCALAPPDATA%\Programs\Antigravity\bin\antigravity.cmd"
        )
    )
    
    if defined ANTIGRAVITY_CMD (
        :: Parse folder names to extract extension IDs (format: publisher.name-version)
        for /f "usebackq tokens=*" %%A in ("%VSCODE_CONFIG_DIR%\antigravity-extensions.txt") do (
            :: Extract publisher.name by removing -version suffix
            for /f "tokens=1,2 delims=-" %%B in ("%%A") do (
                echo Installing %%B...
                call "!ANTIGRAVITY_CMD!" --install-extension %%B --force >nul 2>&1
            )
        )
        echo Antigravity extensions installed.
    ) else (
        echo [WARNING] Antigravity not found. Skipping extension installation.
    )
)

:: --- Antigravity Settings ---
set "ANTIGRAVITY_BACKUP=%VSCODE_CONFIG_DIR%\antigravity"
set "ANTIGRAVITY_USER=%APPDATA%\Antigravity\User"

if exist "%ANTIGRAVITY_BACKUP%" (
    if not exist "%ANTIGRAVITY_USER%\settings.json" (
        echo Restoring Antigravity...
        if not exist "%ANTIGRAVITY_USER%" mkdir "%ANTIGRAVITY_USER%" >nul
        if not exist "%ANTIGRAVITY_USER%\globalStorage" mkdir "%ANTIGRAVITY_USER%\globalStorage" >nul
        
        :: Restore settings.json
        if exist "%ANTIGRAVITY_BACKUP%\settings.json" (
            copy /Y "%ANTIGRAVITY_BACKUP%\settings.json" "%ANTIGRAVITY_USER%\settings.json" >nul
            echo Restored settings.json
        )
        
        :: Restore globalStorage/storage.json
        if exist "%ANTIGRAVITY_BACKUP%\globalStorage\storage.json" (
            copy /Y "%ANTIGRAVITY_BACKUP%\globalStorage\storage.json" "%ANTIGRAVITY_USER%\globalStorage\storage.json" >nul
            echo Restored globalStorage/storage.json
        )
        
        echo Antigravity restored.
    ) else (
        echo Antigravity settings already exist. Skipping.
    )
) else (
    echo [INFO] No Antigravity backup folder found.
)

echo.
echo VS Code configuration restored.
