# 002 - .bat → .sh 轉換實作計畫

> 承接 `project-arc.md` 的分析結果。本文件只規劃步驟，尚未寫程式碼。

## 專案目標

把 `build_venv.bat`、`config.bat`、`download_db.bat` 轉換為可在 Linux 遠端環境執行的對應 `.sh` 腳本。

## 前置：需要你先做決定的分岐點

以下每一點都會實際影響第 2 節怎麼寫，不是可以先跳過、之後再補的細節。

### 決策 1：新舊檔案並存方式
- **選項 A（建議）**：新增 `build_venv.sh` / `config.sh` / `download_db.sh`，原本三個 `.bat` 保留不動。兩邊語法邏輯對應但各自獨立維護。
- **選項 B**：直接取代，之後只留 `.sh`，`.bat` 刪除或不再維護。
- 未特別說明時我會採選項 A（改動範圍最小，且你可能仍在 Windows 上開發、Linux 上部署，兩邊都要能跑）。

### 決策 2：`config` 內的個資與未填參數 — 已解決

- `GIT_USER_NAME` / `GIT_USER_EMAIL` 明碼寫死一事**經查證後不成立為新風險**：這個 repo 的 git commit 作者資訊（`james.sun0919@gmail.com`）本來就會透過 `git log` 公開，跟 `config.bat` 有沒有寫這兩個值無關。維持現狀即可，不需改動。
- `FILE_ID`：原本暫留空，開發者後續提供實際 Google Drive 分享連結，已補上實際值
  `1Jb6W-_iIVopt0fSkDbeLBlw9w0qsxKk7`（`config.sh`／`config.bat` 兩邊同步更新）。

### 決策 3：`setup_git.bat` 的處理
- `setup_git.bat` 也 `call config.bat`，但不在這次要轉換的清單內。
- **選項 A（建議）**：這次不動 `setup_git.bat`，它繼續依賴 Windows 版 `config.bat`；新增的 `config.sh` 只服務 Linux 端三支腳本，兩者並存互不影響。
- **選項 B**：一併新增 `setup_git.sh`。
- 若沒有指示，我會採選項 A，因為超出這次明確要求的範圍。

### 決策 4：Google Drive 下載邏輯要不要換
- 檢查目前 `db.sqlite3` 實際大小僅約 148KB，遠低於 Google 對大檔案觸發「病毒掃描警告頁」的門檻（一般在數十 MB 以上才會發生）。
- 因此這個風險目前**實際發生機率低**，建議先照抄原本 curl/PowerShell fallback 的邏輯結構（Linux 版改成 curl/wget fallback），不需要現在就換成 `gdown` 之類的工具。之後檔案若明顯變大再重新評估。
- **實測後補充**：實際測試時確實抓到 HTML 而非資料庫，但原因不是檔案過大，而是 Google Drive 分享權限一開始未設為「知道連結的任何人可檢視」。調整分享設定後下載即成功，「回傳 HTML 而非真正檔案」這個失敗模式本身是存在的，只是觸發原因跟原先預期的不同，仍建議保留「下載後驗證檔案格式」這道檢查。

## 實作步驟與驗證方式

決策 1、3、4 均採建議選項，決策 2 已解決（`FILE_ID` 已補上實際值）。步驟 1～4 皆已完成並實測驗證，步驟 5（完整 Linux/WSL 端對端驗證）待部署到目標機器時執行。

```
1. 建立 config.sh — 完成
   - 用 SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 取代 %~dp0
   - VAR="value" 取代 set "VAR=value"
   - FILE_ID 已補上實際值 1Jb6W-_iIVopt0fSkDbeLBlw9w0qsxKk7（config.bat 也同步補上同一值）；
     GIT_USER_NAME / GIT_USER_EMAIL 原樣帶過
   → 驗證：bash -n config.sh 語法檢查通過；source config.sh 後
     DB_PATH=/c/Users/User/Desktop/DjangoBlog/db.sqlite3、
     DOWNLOAD_URL=https://drive.google.com/uc?export=download&id=1Jb6W-_iIVopt0fSkDbeLBlw9w0qsxKk7，
     皆符合預期 ✅

2. 建立 build_venv.sh — 完成（語法檢查通過，實際執行待 Linux/WSL 環境驗證）
   - 用 command -v python3 取代 python --version 檢查
   - .venv/bin/python 取代 .venv\Scripts\python.exe
   - 移除 pause
   - chmod +x build_venv.sh
   → 驗證：bash -n build_venv.sh 通過 ✅。實際跑 bash build_venv.sh 建立 .venv/ 並
     確認 .venv/bin/python -m pip show Django 有輸出，需在真正的 Linux/WSL 環境執行——
     目前開發機是 Windows，現有的 .venv/ 是用 Windows python 建的（結構是 Scripts/ 不是 bin/），
     不能拿來驗證 Linux 版腳本，這一步留給你在部署目標機器上跑。

3. 建立 download_db.sh — 完成，已實測成功 ✅
   - source "$SCRIPT_DIR/config.sh" 取代 call config.bat
   - command -v curl 判斷，找不到則 fallback 到 wget（取代 PowerShell fallback）
   - 下載後檢查檔案存在且非空
   → 實測過程：
     - 第一次測試（Google Drive 檔案分享設定仍是「限制」）：下載結果是
       accounts.google.com 的登入頁面，不是資料庫檔案。用 file 指令確認為
       「HTML document」而非 SQLite 格式，證實了本文件先前提到的下載風險是真實存在的——
       只是實際原因是「分享權限未開放給任何知道連結者」，不是檔案過大觸發病毒掃描頁。
       測試前已備份本機原始 db.sqlite3，測試後隨即還原，未造成資料遺失。
     - 開發者將 Google Drive 檔案分享設定改為「知道連結的任何人可檢視」後，重新測試：
       下載成功，file db.sqlite3 確認為「SQLite 3.x database」，且與測試前的本機檔案
       逐位元組（cmp）比對完全相同（151552 bytes）。驗證通過 ✅

4. 賦權 — 完成
   → 驗證：ls -l 確認三個檔案皆為 -rwxr-xr-x ✅

5. 端對端驗證 — 待辦（需 Linux/WSL 環境；FILE_ID 已備妥）
   - 在乾淨的 Linux/WSL 環境依序執行：bash build_venv.sh → bash download_db.sh
   - 接著 .venv/bin/python manage.py migrate --check（或直接 runserver）確認整條鏈路可用
   → 驗證：伺服器成功啟動、無 import error、db.sqlite3 內容可被 Django 正常讀取
```

## 尚未涵蓋、留待之後的項目

- `settings.py` 內 `SECRET_KEY` 寫死、`DEBUG = True`、`ALLOWED_HOSTS = ['*']`——這些是部署到遠端前應處理的既有問題，但不在這次「轉換三個 .bat」的需求範圍內，先不動。
- `requirement.txt`（單數檔名）沿用現況，不在本次範圍內。

## 下一步

決策 2 已解決。若決策 1／3／4 沒有其他意見，即可直接進入第 2 節的步驟 1～4 實作。
