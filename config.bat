@echo off
:: =====================================================================
:: Configuration Parameters for Database Download
:: =====================================================================

:: Google Drive File ID for db.sqlite3
set "FILE_ID=1Jb6W-_iIVopt0fSkDbeLBlw9w0qsxKk7"

:: Local path where the database will be saved
set "DB_PATH=%~dp0db.sqlite3"

:: Direct download link constructed from FILE_ID
set "DOWNLOAD_URL=https://drive.google.com/uc?export=download&id=%FILE_ID%"

set "GIT_USER_NAME=jamessun0919-ops"
set "GIT_USER_EMAIL=james.sun0919@gmail.com"