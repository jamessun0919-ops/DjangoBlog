# Project Arc — Windows .bat → Linux 部署腳本轉換分析

> 本文件僅為分析，未修改任何程式碼。範圍：`build_venv.bat`、`config.bat`、`download_db.bat`。

## 1. 專案結構總覽（與部署相關部分）

```
DjangoBlog/
├── build_venv.bat      # 建立 venv + 安裝 requirement.txt
├── config.bat           # 共用參數（FILE_ID / DB_PATH / GIT_USER_*）
├── download_db.bat      # 從 Google Drive 下載 db.sqlite3
├── setup_git.bat        # 設定 git user.name/email（也依賴 config.bat，本次未列入轉換範圍）
├── requirement.txt       # Django==6.0, Markdown==3.10.2
├── manage.py
├── DjangoBlog/settings.py
└── db.sqlite3            # 已被 .gitignore 排除，需靠 download_db.bat 取得
```

三個檔案的相依關係：`download_db.bat` 在執行時 `call` 讀入 `config.bat` 取得 `DB_PATH`／`DOWNLOAD_URL`；`build_venv.bat` 獨立運作，不依賴 `config.bat`。`setup_git.bat` 同樣 `call config.bat`，但不在本次轉換清單內。

## 2. 各檔案目前行為

| 檔案 | 功能 | Windows 專屬語法 |
|---|---|---|
| `build_venv.bat` | 檢查 `python`、建立 `.venv`、升級 pip、安裝 `requirement.txt` | `.venv\Scripts\python.exe`、`%errorlevel%`、`pause` |
| `config.bat` | 定義共用變數：`FILE_ID`、`DB_PATH`、`DOWNLOAD_URL`、`GIT_USER_NAME`、`GIT_USER_EMAIL` | `set "VAR=value"`、`%~dp0`（批次檔所在目錄） |
| `download_db.bat` | `call config.bat` 讀參數 → 用 `curl.exe`（找不到則 fallback 到 PowerShell `Invoke-WebRequest`）下載 DB | `setlocal enabledelayedexpansion` + `!VAR!`、`where curl.exe`、PowerShell fallback |

## 3. 轉換為 Linux（.sh）的技術對應表

| Windows (.bat) | Linux (.sh) 對應 |
|---|---|
| `@echo off` | 不需要對應，shebang `#!/usr/bin/env bash` 即可 |
| `REM` / `::` 註解 | `#` |
| `%errorlevel% neq 0` | `if [ $? -ne 0 ]` 或直接用 `set -e` |
| `python` 指令檢查 | 多數 Linux 發行版預設只有 `python3`，需檢查 `python3`（且可能要另外裝 `venv`：Debian/Ubuntu 常需要 `python3-venv` 套件，否則 `python3 -m venv` 會直接失敗且訊息不明顯） |
| `.venv\Scripts\python.exe` | `.venv/bin/python` |
| `pause` | 無直接對應；通常整段移除（Linux 腳本一般不會卡住等按鍵），若要保留互動可用 `read -p "按 Enter 繼續..."` |
| `set "VAR=value"` | `VAR="value"` |
| `%~dp0`（批次檔自身所在目錄，含結尾反斜線） | `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`，使用時 `"$SCRIPT_DIR/db.sqlite3"` |
| `setlocal enabledelayedexpansion` + `!VAR!` | 不需要，bash 沒有這個機制，直接用 `$VAR` |
| `call "%~dp0config.bat"` | `source "$SCRIPT_DIR/config.sh"` |
| `where curl.exe` | `command -v curl` |
| PowerShell fallback (`Invoke-WebRequest`) | Linux 上沒有 PowerShell，需改為 fallback 到 `wget`（`wget -O "$DB_PATH" "$DOWNLOAD_URL"`） |
| `%~dp0db.sqlite3` | `"$SCRIPT_DIR/db.sqlite3"` |

檔名部分：三個檔案若要成為「Linux 專用」，一般慣例是改副檔名為 `.sh`（`build_venv.sh`、`config.sh`、`download_db.sh`），並需要 `chmod +x` 賦予執行權限（Windows 端沒有可執行位元這個概念，git 在 Windows 上通常也不會保留這個 bit，跨平台常見的坑）。

## 4. 我認為需要先確認的問題（邏輯漏洞 / 不成立之處）

1. **`config.bat` 的 `FILE_ID=你的FILE_ID` 是未填的佔位字串。** 目前這個檔案本身還沒接上真正的 Google Drive 檔案 ID，轉換語法不會解決這件事，仍需你手動填入實際值，否則轉出來的 `.sh` 一樣下載不到東西。
2. **`config.bat` 沒有被 `.gitignore` 排除，但裡面寫死了真實姓名與 Email（`jamessun0919-ops` / `james.sun0919@gmail.com`）。** 若這個 repo 要推到遠端（尤其是公開 repo），這些個資會一併被推上去。這跟語法轉換無關，但既然目的是「部署到遠端」，建議一併決定：這份 config 是否該去掉個資、改用環境變數、或至少確認 repo 是 private。
3. **`download_db.bat` 對大檔案的 Google Drive 直接下載連結（`uc?export=download`）在檔案超過一定大小時會被 Google 攔截，轉成「病毒掃描警告」的確認頁，回傳的不是資料庫檔案本身，而是一段 HTML。** 這是原腳本既有的風險，不是本次轉換造成的，但轉出 Linux 版時如果照抄同一組邏輯，同樣的坑會原封不動搬過去。是否要換成 `gdown` 或其他更穩定的下載方式，是一個值得一併決定的點。
4. **`setup_git.bat` 也 `call config.bat`，但不在這次要轉換的三個檔案中。** 如果 `config.bat` 被轉成 `config.sh`（改變語法／副檔名），`setup_git.bat` 會找不到 `config.bat` 而失敗（除非 `setup_git.bat` 本身也一起轉換，或保留一份相容的 `config.bat`）。這點需要你決定：`setup_git.bat` 這次要不要一起處理，還是保留給 Windows 端用、`config.sh` 只服務 Linux 端三個腳本。
5. **`build_venv.bat` 讀取的套件檔名是 `requirement.txt`（單數），非 Python 生態圈慣例的 `requirements.txt`（複數）。** 這不影響 Linux 轉換本身（只要腳本裡的檔名跟實際檔名一致就能跑），但如果部署流程之後接上 CI/CD 或其他工具，很多工具預設會找 `requirements.txt`，屆時可能要注意。本次不在轉換範圍內，僅提出來供留意。
6. **與「部署到遠端」直接相關但不在這三個檔案裡的既有風險（`DjangoBlog/settings.py`）**：`SECRET_KEY` 直接寫死在原始碼中、`DEBUG = True`、`ALLOWED_HOSTS = ['*']`。這些如果原樣部署到遠端環境，是常見的安全疑慮（`DEBUG = True` 會在錯誤頁洩漏原始碼與環境資訊；`ALLOWED_HOSTS = ['*']` 等於不限制 Host header）。這不屬於這次要求的範圍，先記錄在這裡，之後若要處理再另外討論。

## 5. 下一步（尚未執行，等待確認）

- 確認 §4 第 1、2、4 點的處理方式後，再進行實際的 `.sh` 改寫。
- 確認新檔案是採「新增 `.sh`、保留原 `.bat`（雙平台並存）」還是「直接取代」。
