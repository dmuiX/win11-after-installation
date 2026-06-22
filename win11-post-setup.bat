@echo off
cd /d "%~dp0"

:: Self-elevate if not admin
net session >nul 2>&1 || (
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" %*' -Verb RunAs"
    exit /b
)

:: Find PowerShell 7
where pwsh >nul 2>&1 && goto :run
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" goto :run

:: Install PowerShell 7 via GitHub (no winget dependency)
echo [INFO] Installing PowerShell 7...
powershell -NoProfile -Command "& {$m=Join-Path $env:TEMP 'pwsh.msi'; $u=(Invoke-RestMethod 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest').assets|?{$_.name -like '*win-x64.msi'}|Select -Exp browser_download_url; iwr $u -OutFile $m -UseBasicParsing; Start-Process msiexec -ArgumentList ('/i',$m,'/qn','/norestart') -Wait}"
if not exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
    echo [ERROR] PowerShell 7 installation failed.
    pause
    exit /b 1
)

:run
:: Prefer full path, fall back to pwsh from PATH
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
    "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0win11-post-setup.ps1" %*
) else (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0win11-post-setup.ps1" %*
)

:: Refresh PATH and exit
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "PATH=%%b;%PATH%"
pause