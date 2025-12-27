@echo off

::--------------------------------------------------------------------------------
:: Part 0: Self-Elevation
:: This block checks for admin rights and re-launches the script as admin if needed.
::--------------------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrative privileges.
) else (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" %*'" -Verb runAs
    exit /b
)

:: --- The main script starts here, now running as Administrator ---

echo Starting comprehensive DISM repair, cleanup, SFC scan, and Disk Cleanup...
echo.
REM ====================================================================
REM  Part 1: Repairing the Windows Image
REM ====================================================================

echo [1/8] Checking for component store corruption...
DISM /Online /Cleanup-Image /CheckHealth
echo.
echo [2/8] Scanning for component store corruption...
DISM /Online /Cleanup-Image /ScanHealth
echo.
echo [3/8] Repairing the Windows image...
DISM /Online /Cleanup-Image /RestoreHealth
echo.
REM ====================================================================
REM  Part 2: Comprehensive Component Store Cleanup
REM ====================================================================

echo [4/8] Analyzing the component store...
DISM /Online /Cleanup-Image /AnalyzeComponentStore
echo.
echo [5/8] Performing standard component cleanup...
DISM /Online /Cleanup-Image /StartComponentCleanup
echo.
echo [6/8] Performing aggressive component cleanup...
DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
echo.
echo [7/8] Removing superseded service pack components...
DISM /Online /Cleanup-Image /SPSuperseded
echo.
REM ====================================================================
REM  Part 3: System File Checker
REM ====================================================================

echo [8/8] Running System File Checker...
sfc /scannow
echo.
REM ====================================================================
REM  Part 4: Automated Disk Cleanup
REM ====================================================================

echo Running pre-configured Disk Cleanup...
cleanmgr /sagerun:1
echo.
REM ====================================================================
REM  Part 5: Deep System Cleaning
REM ====================================================================
echo.
echo [1/3] Clearing Temporary Files...
del /q /f /s "%TEMP%\*" >nul 2>&1
rd /s /q "%TEMP%" >nul 2>&1
if not exist "%TEMP%" mkdir "%TEMP%" >nul 2>&1

del /q /f /s "%WINDIR%\Temp\*" >nul 2>&1
rd /s /q "%WINDIR%\Temp" >nul 2>&1
if not exist "%WINDIR%\Temp" mkdir "%WINDIR%\Temp" >nul 2>&1

echo [2/3] Clearing Windows Update Cache...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
rd /s /q "%WINDIR%\SoftwareDistribution\Download" >nul 2>&1
mkdir "%WINDIR%\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

echo [3/3] Flushing DNS Cache...
ipconfig /flushdns >nul

echo.
REM ====================================================================
echo  Script Complete
REM ====================================================================
echo.
echo The comprehensive maintenance script has finished.
pause
