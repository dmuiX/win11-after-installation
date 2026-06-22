@echo off

::--------------------------------------------------------------------------------
:: Part 0: Admin check (no auto-elevation; runs inline)
::--------------------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrative privileges.
) else (
    echo This script must be run as Administrator. Right-click and choose "Run as administrator".
    pause
    exit /b 1
)

:: --- The main script starts here, now running as Administrator ---

:: Mode: default runs all; use /ask to confirm each step
set "ASK=0"
if /I "%~1"=="/ask" set "ASK=1"

:: Prompt helper
goto :main
:confirm
setlocal
set "label=%~1"
if "%ASK%"=="0" (
    endlocal & exit /b 0
)
choice /M "%label%" /C YN
if errorlevel 2 (
    echo Skipped: %label%
    endlocal & exit /b 1
) else (
    endlocal & exit /b 0
)

:main
echo Starting comprehensive DISM repair, cleanup, SFC scan, and Disk Cleanup...
echo.
REM ====================================================================
REM  Part 1: Repairing the Windows Image
REM ====================================================================

call :confirm "DISM CheckHealth" && (
    echo [1/8] Checking for component store corruption...
    DISM /Online /Cleanup-Image /CheckHealth
)
echo.
call :confirm "DISM ScanHealth" && (
    echo [2/8] Scanning for component store corruption...
    DISM /Online /Cleanup-Image /ScanHealth
)
echo.
call :confirm "DISM RestoreHealth" && (
    echo [3/8] Repairing the Windows image...
    DISM /Online /Cleanup-Image /RestoreHealth
)
echo.
REM ====================================================================
REM  Part 2: Comprehensive Component Store Cleanup
REM ====================================================================

call :confirm "DISM AnalyzeComponentStore" && (
    echo [4/8] Analyzing the component store...
    DISM /Online /Cleanup-Image /AnalyzeComponentStore
)
echo.
call :confirm "DISM StartComponentCleanup" && (
    echo [5/8] Performing standard component cleanup...
    DISM /Online /Cleanup-Image /StartComponentCleanup
)
echo.
call :confirm "DISM StartComponentCleanup /ResetBase" && (
    echo [6/8] Performing aggressive component cleanup...
    DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
)
echo.
call :confirm "DISM SPSuperseded" && (
    echo [7/8] Removing superseded service pack components...
    DISM /Online /Cleanup-Image /SPSuperseded
)
echo.
REM ====================================================================
REM  Part 3: System File Checker
REM ====================================================================

call :confirm "SFC /scannow" && (
    echo [8/8] Running System File Checker...
    sfc /scannow
)
echo.
REM ====================================================================
REM  Part 4: Automated Disk Cleanup
REM ====================================================================

call :confirm "Disk Cleanup (cleanmgr /sagerun:1)" && (
    echo Running pre-configured Disk Cleanup...
    cleanmgr /sagerun:1
)
echo.
REM ====================================================================
REM  Part 5: Deep System Cleaning
REM ====================================================================
echo.
call :confirm "Clear temporary files" && (
    echo [1/3] Clearing Temporary Files...
    del /q /f /s "%TEMP%\*" >nul 2>&1
    rd /s /q "%TEMP%" >nul 2>&1
    if not exist "%TEMP%" mkdir "%TEMP%" >nul 2>&1

    del /q /f /s "%WINDIR%\Temp\*" >nul 2>&1
    rd /s /q "%WINDIR%\Temp" >nul 2>&1
    if not exist "%WINDIR%\Temp" mkdir "%WINDIR%\Temp" >nul 2>&1
)

call :confirm "Clear Windows Update cache" && (
    echo [2/3] Clearing Windows Update Cache...
    net stop wuauserv >nul 2>&1
    net stop bits >nul 2>&1
    rd /s /q "%WINDIR%\SoftwareDistribution\Download" >nul 2>&1
    mkdir "%WINDIR%\SoftwareDistribution\Download" >nul 2>&1
    net start wuauserv >nul 2>&1
    net start bits >nul 2>&1
)

call :confirm "Flush DNS cache" && (
    echo [3/3] Flushing DNS Cache...
    ipconfig /flushdns >nul
)

echo.
REM ====================================================================
echo  Script Complete
REM ====================================================================
echo.
echo The comprehensive maintenance script has finished.
pause
