@echo off
cd /d "%~dp0"

:: Self-elevate if not admin
net session >nul 2>&1 || (powershell -Command "Start-Process cmd '/c \"%~f0\"' -Verb RunAs" & exit /b)

:: Find or install PowerShell 7
where pwsh >nul 2>&1 || if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (set "PWSH=%ProgramFiles%\PowerShell\7\pwsh.exe") else (
    echo [INFO] Downloading PowerShell 7...
    curl -L -o "%TEMP%\pwsh.msi" "https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4-win-x64.msi"
    msiexec /i "%TEMP%\pwsh.msi" /qn /norestart
    timeout /t 3 >nul
)

:: Run script
if defined PWSH ("%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "win11-post-setup.ps1") else (pwsh -NoProfile -ExecutionPolicy Bypass -File "win11-post-setup.ps1")

:: Refresh PATH and exit
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "PATH=%%b;%PATH%"
pause
