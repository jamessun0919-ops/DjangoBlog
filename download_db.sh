#!/usr/bin/env bash

echo "=========================================="
echo "Downloading Database from Google Drive..."
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load parameters from config.sh
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    echo "[ERROR] config.sh not found."
    exit 1
fi

echo "Target: $DB_PATH"

if command -v curl >/dev/null 2>&1; then
    echo "Using curl to download..."
    curl -L "$DOWNLOAD_URL" -o "$DB_PATH"
else
    echo "curl not found. Falling back to wget..."
    wget -O "$DB_PATH" "$DOWNLOAD_URL"
fi

if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Failed to download the database file."
    exit 1
fi

if [ ! -f "$DB_PATH" ]; then
    echo ""
    echo "[ERROR] Database file was not created successfully."
    exit 1
fi

echo ""
echo "=========================================="
echo "Database downloaded successfully!"
echo "Saved as: $DB_PATH"
echo "=========================================="
