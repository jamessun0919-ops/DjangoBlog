@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Downloading Database from Google Drive...
echo ==========================================

REM Load parameters from config.bat
if exist "%~dp0config.bat" (
    call "%~dp0config.bat"
) else (
    echo [ERROR] config.bat not found.
    pause
    exit /b 1
)


echo Target: !DB_PATH!

where curl.exe >nul 2>&1
if %errorlevel% equ 0 (
    echo Using curl.exe to download...
    curl.exe -L "!DOWNLOAD_URL!" -o "!DB_PATH!"
) else (
    echo curl.exe not found. Falling back to PowerShell...
    powershell -Command "Invoke-WebRequest -Uri '!DOWNLOAD_URL!' -OutFile '!DB_PATH!'"
)

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to download the database file.
    pause
    exit /b %errorlevel%
)

if not exist "!DB_PATH!" (
    echo.
    echo [ERROR] Database file was not created successfully.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Database downloaded successfully!
echo Saved as: !DB_PATH!
echo ==========================================
pause