@echo off

::--------------------------------------------------------------------------------
:: Daily Winget Update Script
:: Runs silently and safely (pins AppInstaller to prevent self-update loops)
::--------------------------------------------------------------------------------

echo Starting Daily Winget Update...
date /t & time /t

REM Pin AppInstaller to prevent self-update loops/restarts
winget pin list --id Microsoft.AppInstaller >nul 2>&1
if %errorlevel% neq 0 (
    echo Pinning AppInstaller...
    winget pin add --id Microsoft.AppInstaller --blocking >nul 2>&1
) else (
    echo AppInstaller already pinned.
)

REM Upgrade all packages silently
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

REM Unpin AppInstaller
winget pin remove --id Microsoft.AppInstaller >nul 2>&1

echo Update Complete.
timeout /t 5 >nul
exit
