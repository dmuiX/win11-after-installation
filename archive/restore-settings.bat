@echo off

:: ============================
:: Restore VS Code Settings & Extensions
:: ============================
set "VSCODE_CONFIG_DIR=%~dp0..\vscode-config"

if not exist "%VSCODE_CONFIG_DIR%" (
    echo No 'vscode-config' folder found in repo. Skipping VS Code restore.
    exit /b
)

echo.
echo Restoring Editor Configuration from repo when not already there/installed...

:: --- VS Code Insiders Extensions ---
if not exist "%VSCODE_CONFIG_DIR%\vscode-insiders-extensions.txt" goto :SkipVSCodeInsidersExtensions

echo.
echo === VS Code Insiders Extensions ===
echo (Already installed extensions will be skipped by VS Code)

:: Install all extensions (VS Code handles duplicates with --force)
for /f "usebackq tokens=*" %%A in ("%VSCODE_CONFIG_DIR%\vscode-insiders-extensions.txt") do (
    if not "%%A"=="" (
        echo [INSTALL] %%A...
        cmd /c "code-insiders --install-extension %%A --force" >nul 2>&1
    )
)
echo VS Code Insiders extensions done.

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
if not exist "%VSCODE_CONFIG_DIR%\antigravity-extensions.txt" goto :SkipAntigravityExtensions

echo.
echo === Antigravity Extensions ===
echo (Already installed extensions will be skipped by Antigravity)

:: Install all extensions (Antigravity handles duplicates with --force)
for /f "usebackq tokens=*" %%A in ("%VSCODE_CONFIG_DIR%\antigravity-extensions.txt") do (
    if not "%%A"=="" (
        echo [INSTALL] %%A...
        cmd /c "antigravity --install-extension %%A --force" >nul 2>&1
    )
)
echo Antigravity extensions done.

:SkipAntigravityExtensions

:: --- Antigravity Settings ---
set "ANTIGRAVITY_BACKUP=%VSCODE_CONFIG_DIR%\antigravity"
set "ANTIGRAVITY_USER=%APPDATA%\Antigravity\User"

if exist "%ANTIGRAVITY_BACKUP%" (
    if not exist "%ANTIGRAVITY_USER%\settings.json" (
        echo Restoring Antigravity settings...
        if not exist "%ANTIGRAVITY_USER%" mkdir "%ANTIGRAVITY_USER%" >nul
        if not exist "%ANTIGRAVITY_USER%\globalStorage" mkdir "%ANTIGRAVITY_USER%\globalStorage" >nul
        
        if exist "%ANTIGRAVITY_BACKUP%\settings.json" (
            copy /Y "%ANTIGRAVITY_BACKUP%\settings.json" "%ANTIGRAVITY_USER%\settings.json" >nul
        )
        if exist "%ANTIGRAVITY_BACKUP%\globalStorage\storage.json" (
            copy /Y "%ANTIGRAVITY_BACKUP%\globalStorage\storage.json" "%ANTIGRAVITY_USER%\globalStorage\storage.json" >nul
        )
        echo Antigravity settings restored.
    ) else (
        echo Antigravity settings already exist. Skipping.
    )
)

echo.
echo Editor configuration restored.
