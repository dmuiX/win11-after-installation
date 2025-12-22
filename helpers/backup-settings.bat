@echo off
setlocal enabledelayedexpansion

::--------------------------------------------------------------------------------
:: Backup VS Code & Insiders Settings to Repo
::--------------------------------------------------------------------------------

set "BACKUP_DIR=%~dp0..\vscode-config"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Export VS Code Insiders extensions (list folder names)
set "VSCODE_INSIDERS_EXT=%USERPROFILE%\.vscode-insiders\extensions"
if exist "%VSCODE_INSIDERS_EXT%" (
    echo Listing extensions from: %VSCODE_INSIDERS_EXT%
    dir /B "%VSCODE_INSIDERS_EXT%" > "%BACKUP_DIR%\vscode-insiders-extensions.txt"
    echo VS Code Insiders extensions saved.
) else (
    echo [WARNING] VS Code Insiders extensions folder not found at: %VSCODE_INSIDERS_EXT%
)

:: Copy settings files
if exist "%APPDATA%\Code - Insiders\User\settings.json" (
    copy /Y "%APPDATA%\Code - Insiders\User\settings.json" "%BACKUP_DIR%\vscode-insiders-settings.json" >nul
    echo Settings copied.
)
if exist "%APPDATA%\Code - Insiders\User\keybindings.json" (
    copy /Y "%APPDATA%\Code - Insiders\User\keybindings.json" "%BACKUP_DIR%\vscode-insiders-keybindings.json" >nul
    echo Keybindings copied.
)

:: Export Antigravity extensions (list folder names)
set "ANTIGRAVITY_EXT=%USERPROFILE%\.antigravity\extensions"
if exist "%ANTIGRAVITY_EXT%" (
    echo Listing extensions from: %ANTIGRAVITY_EXT%
    dir /B "%ANTIGRAVITY_EXT%" > "%BACKUP_DIR%\antigravity-extensions.txt"
    echo Antigravity extensions saved.
) else (
    echo [WARNING] Antigravity extensions folder not found at: %ANTIGRAVITY_EXT%
)

set "ANTIGRAVITY_USER=%APPDATA%\Antigravity\User"
set "ANTIGRAVITY_BACKUP=%BACKUP_DIR%\antigravity"

if exist "%ANTIGRAVITY_USER%" (
    if not exist "%ANTIGRAVITY_BACKUP%" mkdir "%ANTIGRAVITY_BACKUP%"
    if not exist "%ANTIGRAVITY_BACKUP%\globalStorage" mkdir "%ANTIGRAVITY_BACKUP%\globalStorage"
    
    :: Copy settings.json
    if exist "%ANTIGRAVITY_USER%\settings.json" (
        copy /Y "%ANTIGRAVITY_USER%\settings.json" "%ANTIGRAVITY_BACKUP%\settings.json" >nul
        echo Copied settings.json
    )
    
    :: Copy globalStorage/storage.json
    if exist "%ANTIGRAVITY_USER%\globalStorage\storage.json" (
        copy /Y "%ANTIGRAVITY_USER%\globalStorage\storage.json" "%ANTIGRAVITY_BACKUP%\globalStorage\storage.json" >nul
        echo Copied globalStorage/storage.json
    )
    
    echo Antigravity backup complete.
) else (
    echo [INFO] Antigravity User folder not found at: %ANTIGRAVITY_USER%
)

echo.
echo Backup Complete. Settings stored in: %BACKUP_DIR%
