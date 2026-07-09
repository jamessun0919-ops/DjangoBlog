@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo Setting up Git User Configuration...
echo ==========================================

REM Load parameters from config.bat
if exist "%~dp0config.bat" (
    call "%~dp0config.bat"
) else (
    echo [ERROR] config.bat not found.
    pause
    exit /b 1
)

REM Check if Git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH.
    echo Please install Git and try again.
    pause
    exit /b 1
)

REM Configure Git User Name and Email locally for this repository
echo Configuring Git local user name to: !GIT_USER_NAME!
git config user.name "!GIT_USER_NAME!"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to set git user.name.
    pause
    exit /b 1
)

echo Configuring Git local user email to: !GIT_USER_EMAIL!
git config user.email "!GIT_USER_EMAIL!"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to set git user.email.
    pause
    exit /b 1
)

echo ==========================================
echo Git configuration complete!
echo Current Local Git Config:
echo ------------------------------------------
echo user.name  : 
git config user.name
echo user.email : 
git config user.email
echo ==========================================
pause