@echo off

::--------------------------------------------------------------------------------
:: Backup VS Code & Insiders Settings to Repo
::--------------------------------------------------------------------------------

set "BACKUP_DIR=%~dp0..\vscode-config"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Export VS Code Insiders extensions using CLI
echo Exporting VS Code Insiders extensions...
cmd /c "code-insiders --list-extensions" > "%BACKUP_DIR%\vscode-insiders-extensions.txt" 2>nul
echo VS Code Insiders extensions saved.

:: Copy settings files
if exist "%APPDATA%\Code - Insiders\User\settings.json" (
    copy /Y "%APPDATA%\Code - Insiders\User\settings.json" "%BACKUP_DIR%\vscode-insiders-settings.json" >nul
    echo Settings copied.
)
if exist "%APPDATA%\Code - Insiders\User\keybindings.json" (
    copy /Y "%APPDATA%\Code - Insiders\User\keybindings.json" "%BACKUP_DIR%\vscode-insiders-keybindings.json" >nul
    echo Keybindings copied.
)

:: Export Antigravity extensions using CLI
echo Exporting Antigravity extensions...
cmd /c "antigravity --list-extensions" > "%BACKUP_DIR%\antigravity-extensions.txt" 2>nul
echo Antigravity extensions saved.

set "ANTIGRAVITY_USER=%APPDATA%\Antigravity\User"
set "ANTIGRAVITY_BACKUP=%BACKUP_DIR%\antigravity"

if exist "%ANTIGRAVITY_USER%" (
    if not exist "%ANTIGRAVITY_BACKUP%" mkdir "%ANTIGRAVITY_BACKUP%"
    if not exist "%ANTIGRAVITY_BACKUP%\globalStorage" mkdir "%ANTIGRAVITY_BACKUP%\globalStorage"
    
    if exist "%ANTIGRAVITY_USER%\settings.json" (
        copy /Y "%ANTIGRAVITY_USER%\settings.json" "%ANTIGRAVITY_BACKUP%\settings.json" >nul
        echo Copied settings.json
    )
    
    if exist "%ANTIGRAVITY_USER%\globalStorage\storage.json" (
        copy /Y "%ANTIGRAVITY_USER%\globalStorage\storage.json" "%ANTIGRAVITY_BACKUP%\globalStorage\storage.json" >nul
        echo Copied globalStorage/storage.json
    )
    
    echo Antigravity backup complete.
)

echo.
echo Backup Complete. Settings stored in: %BACKUP_DIR%
