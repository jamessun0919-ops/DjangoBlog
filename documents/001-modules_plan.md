# 001 - 發表文章介面 (登入 + Markdown WYSIWYG) 實作計畫

## 專案目標

在 DjangoBlog 新增一個「張貼文章」頁面：使用者必須登入才能發表，內容編輯採「所見即所得」(WYSIWYG)，但**底層儲存格式為 Markdown**，顯示時再將 Markdown 渲染成 HTML。

## 已確認的設計決策

| 項目 | 決策 |
|---|---|
| 登入範圍 | 僅登入，不開放前台註冊。帳號一律由開發者於 `/admin/` 後台手動建立（`django.contrib.auth` 內建 User model） |
| 內容儲存格式 | Markdown 純文字（`TextField`），非 HTML |
| WYSIWYG 方案 | **Toast UI Editor**（前端 JS 套件，真正 inline 所見即所得，內部自動序列化為 Markdown 字串存回表單欄位） |

> 註：原先討論過 django-ckeditor（存 HTML）與 django-markdownx（左右並排、非真 inline WYSIWYG）兩個方案，因為使用者明確要「Markdown 儲存 + 所見即所得」，兩者互斥條件下選擇 Toast UI Editor 取代先前的 django-ckeditor 決定。

## 現況缺口（來自架構檢視，尚未變更）

- `article/urls.py` 不存在，`DjangoBlog/urls.py` 直接 import view function。
- `Post` model 沒有 `author` 欄位，無法記錄「誰發表的」。
- `slug` 目前是普通 `CharField`，非 `SlugField`，也沒有 `unique=True`，沒有自動產生機制。
- 沒有任何登入頁面／`LOGIN_URL` 設定。
- 沒有 `article/forms.py`。
- `requirement.txt` 只有 `Django==6.0`；沒有 Markdown 渲染套件，也沒有任何前端 JS 套件（本專案目前是純 SSR、零 JS）。
- 沒有 `MEDIA_URL`/`MEDIA_ROOT` 設定。
- 首頁 `article_card.html` 直接對 `post.content` 做 `truncatewords`，未來 `content` 存的是 Markdown 語法，若不處理，摘要會顯示 `**粗體**`、`## 標題` 這類原始符號。

## 範圍界定（避免過度設計）

**這次只做**：登入頁、登出、發表文章表單頁（Toast UI Editor + Markdown 儲存）、寫入 DB 時綁定登入者為作者、首頁摘要改為去除 Markdown 語法的純文字。

**這次不做**（如未來需要另外討論再排入計畫）：
- 前台註冊頁
- 文章詳情頁（完整內容渲染成 HTML 的頁面）／編輯／刪除頁
- 圖片上傳（Toast UI Editor 支援，但需要額外的上傳 endpoint，先不做，待確認）
- 分類、標籤、留言
- 權限分級（目前只要「登入」即可發表，不分角色）

---

## 實作步驟與驗證方式

### Step 1：安裝 Markdown 渲染套件（Python 端）
- 更新 `requirement.txt` 加入 `Markdown`（Python-Markdown，用於之後把存好的 markdown 字串轉成 HTML 顯示）
- `pip install Markdown`
- **驗證**：`python -c "import markdown; print(markdown.markdown('**test**'))"` 輸出 `<p><strong>test</strong></p>`

### Step 2：引入 Toast UI Editor（前端）
- 透過 CDN `<link>`/`<script>` 引入 `toastui-editor` 的 CSS/JS（本專案目前零 JS 依賴，不用 npm build，直接用 CDN 最貼近現有架構）
- **驗證**：頁面載入後瀏覽器 console 無 404／JS error。

### Step 3：調整 `Post` model
- 新增 `author = models.ForeignKey(User, on_delete=models.CASCADE)`
- `slug` 改為 `models.SlugField(max_length=200, unique=True, blank=True)`，儲存時若空白用 `slugify(title)` 自動產生（於 model `save()` 覆寫）
- `content` 維持 `TextField`（現況已符合，只是語意上改存 Markdown，不需改型別）
- 產生 migration：`python manage.py makemigrations article`
- **驗證**：`python manage.py migrate` 成功。

### Step 4：登入 / 登出路由
- 新增 `LOGIN_URL = 'login'`、`LOGIN_REDIRECT_URL = '/'` 至 `settings.py`
- `DjangoBlog/urls.py` 加入 `path('accounts/', include('django.contrib.auth.urls'))`
- 新增樣板 `templates/registration/login.html`（extends `base.html`）
- `nav.html` 依登入狀態顯示「登入」或「登出 + 發表文章」連結
- **驗證**：未登入時看到「登入」連結；登入後看到「發表文章」與「登出」；`/accounts/logout/` 可登出。

### Step 5：文章發表路由與 View
- 新增 `article/urls.py`：`path('post/new/', views.post_create, name='post_create')`
- `DjangoBlog/urls.py` 改為 `path('', include('article.urls'))`
- `article/views.py` 新增 `post_create` view，套用 `@login_required`，儲存時 `post.author = request.user`
- **驗證**：未登入訪問 `/post/new/` 導向登入頁；登入後可開啟表單頁。

### Step 6：`article/forms.py`
- 新增 `PostForm(ModelForm)`，欄位 `title`, `content`（`content` 用一般 `forms.Textarea`，實際的所見即所得效果由前端 JS 接管這個 textarea，不需要自訂 Django widget 套件）
- **驗證**：表單能正常 render 出一個 `<textarea id="content">`。

### Step 7：發表頁模板 + Toast UI Editor 綁定
- 新增 `templates/post_form.html`
- 用 JS 將 Toast UI Editor 掛載在 `#content` 對應的容器上（editor 顯示用另一個 div，原本的 textarea 隱藏）
- 表單送出前（`submit` 事件），用 `editor.getMarkdown()` 把目前內容寫回隱藏的 `<textarea name="content">`，確保後端收到的是 Markdown 字串
- **驗證**：在編輯器打字看到即時粗體/標題等樣式（真正 WYSIWYG）；送出後，DB 裡 `Post.content` 存的是 Markdown 語法字串（例如 `**test**`），不是 HTML。

### Step 8：首頁摘要顯示調整
- `article_card.html` 目前的 `{{ post.content|truncatewords:20 }}` 會直接印出 Markdown 語法符號，需調整：
  - 建立一個 template filter（如 `strip_markdown`），先用 `markdown.markdown()` 轉成 HTML 再 `striptags` 拿到純文字，最後 `truncatewords`
- **驗證**：首頁摘要顯示純文字，沒有 `**`、`##` 等符號殘留。

### Step 9：整合驗證
- 建立測試帳號 → 登入 → 用 WYSIWYG 編輯器發表一篇含粗體/標題的文章 → 確認 DB 存的是 Markdown → 確認首頁摘要顯示乾淨的純文字截斷

---

## 待實作時仍需開發者確認的細節

1. **圖片上傳**：Toast UI Editor 支援貼上/拖曳圖片自動上傳，但需要一個接收圖片的 Django endpoint（回傳圖片 URL）。這次範圍界定先不做，若需要要另外規劃 `MEDIA_ROOT`、上傳 view、檔案大小/型別限制。
2. **文章詳情頁**：目前只有首頁摘要列表，沒有「完整內容」的頁面。若之後要看完整文章，需要新增 `post_detail` view + 用 `markdown.markdown()` 渲染完整 HTML（並注意 XSS：Python-Markdown 預設不會清除內嵌的 raw HTML，如果之後開放非管理員發表，需要加 `bleach` 之類的白名單清洗）。
3. **CDN vs 本地 vendor 檔案**：Toast UI Editor 用 CDN 最快，但正式環境若要求所有資源自架（不依賴外部 CDN），需要改成下載 `.js`/`.css` 放進 `static/vendor/`，屆時再調整。

## 對應未來 MySQL 遷移的影響

以上異動都是透過 Django ORM 完成（model 欄位、migration），未使用任何 SQLite 專屬語法，日後切換 `DATABASES['default']['ENGINE']` 到 MySQL 時不需要額外調整這次新增的程式碼。Markdown 內容以純文字形式存在 `TextField`，與資料庫引擎無關。
