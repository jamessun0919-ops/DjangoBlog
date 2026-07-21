#!/usr/bin/env bash

echo "=========================================="
echo "Setting up Python Virtual Environment..."
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Python is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] Python3 is not installed or not in PATH."
    echo "Please install Python and try again."
    exit 1
fi

# Create virtual environment
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment in .venv..."
    python3 -m venv .venv
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to create virtual environment."
        exit 1
    fi
    echo "Virtual environment created successfully."
else
    echo ".venv already exists. Skipping creation."
fi

# Upgrade pip
echo "Upgrading pip..."
.venv/bin/python -m pip install --upgrade pip

# Install dependencies
if [ -f "requirement.txt" ]; then
    echo "Installing dependencies from requirement.txt..."
    .venv/bin/python -m pip install -r requirement.txt
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to install dependencies."
        exit 1
    fi
else
    echo "[WARNING] requirement.txt not found. Skipping installation."
fi

echo "=========================================="
echo "Setup complete successfully!"
echo "=========================================="
