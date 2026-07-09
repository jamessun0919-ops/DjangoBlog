@echo off
echo ==========================================
echo Setting up Python Virtual Environment...
echo ==========================================

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not installed or not in PATH.
    echo Please install Python and try again.
    pause
    exit /b 1
)

REM Create virtual environment
if not exist ".venv" (
    echo Creating virtual environment in .venv...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo Virtual environment created successfully.
) else (
    echo .venv already exists. Skipping creation.
)

REM Upgrade pip
echo Upgrading pip...
.venv\Scripts\python.exe -m pip install --upgrade pip

REM Install dependencies
if exist "requirement.txt" (
    echo Installing dependencies from requirement.txt...
    .venv\Scripts\python.exe -m pip install -r requirement.txt
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies.
        pause
        exit /b 1
    )
) else (
    echo [WARNING] requirement.txt not found. Skipping installation.
)

echo ==========================================
echo Setup complete successfully!
echo ==========================================
pause