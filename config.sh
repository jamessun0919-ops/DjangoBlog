#!/usr/bin/env bash
# =====================================================================
# Configuration Parameters for Database Download
# =====================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Google Drive File ID for db.sqlite3
FILE_ID="1Jb6W-_iIVopt0fSkDbeLBlw9w0qsxKk7"

# Local path where the database will be saved
DB_PATH="$SCRIPT_DIR/db.sqlite3"

# Direct download link constructed from FILE_ID
DOWNLOAD_URL="https://drive.google.com/uc?export=download&id=${FILE_ID}"

GIT_USER_NAME="jamessun0919-ops"
GIT_USER_EMAIL="james.sun0919@gmail.com"
