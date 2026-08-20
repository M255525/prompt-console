# CLAUDE.md — Prompt（提示詞控制台）

依 CRISPE 架構（Capacity／Role／Insight／Statement／Personality／Experiment）設計的互動式提示詞產生器。單檔前端工具，無建置步驟、無框架、無 package.json，直接開啟 `index.html`（`file://`）或以靜態伺服器託管即可。

**已推公開 GitHub repo**：<https://github.com/M255525/prompt-console>（2026-08-20，repo 名用 `prompt-console` 而非資料夾名 `Prompt`，避免與工作區其他同名慣例衝突並符合 kebab-case 命名習慣），並啟用 GitHub Pages（legacy branch-source，`master` 分支根目錄）：<https://m255525.github.io/prompt-console/>。

**RWD 已實測驗證（2026-08-20）**：單欄卡片式版面（`.rack` 內每個 `.module` 各自全寬）本身天生對窄螢幕友善，且既有 CSS 已在幾乎每個橫向排列的區塊（`.preset-row`／`.chip-row`／`.output-actions`／`.save-row`／`.saved-item`／`.footer-meta`）都設了 `flex-wrap:wrap`，Playwright 實測 320px／375px／768px 寬度皆**無水平溢出、無版面破圖**，`.api-grid` 也已有 `@media(max-width:600px)` 收成單欄。這次只對 `.topbar`（品牌字樣＋操作手冊連結）額外補上 `flex-wrap:wrap` 做防禦性加固，避免文字未來變長時在極窄螢幕溢出——實際測試沒發現真正的破版，屬預防性補強而非修 bug。**跑馬燈與 sticky topbar 的偏移量整合（`body.has-marquee .topbar{top:30px}`）已在 320px 下確認無疊圖。**

## 設計概念

視覺以「類比合成器控制台（modular synth patch bay）」為主題：CRISPE 的六個維度是六個可填寫的「模組」，垂直排列如機架（rack），左側一條「訊號線」貫穿所有模組，模組有內容時左側 LED 指示燈會亮起（`.module.filled .led-node`），象徵訊號已接上；最下方「輸出訊號」模組即時把六個模組的內容組成完整提示詞。配色為暖色調深色機殼（`--bg #161310`）＋琥珀色 LED 強調色（`--amber #e8a33d`），非典型 AI 產品的冷色霓虹風格。

## 架構

單一 `index.html`：內嵌 CSS/JS、無外部資源。除了「AI 產生」功能主動呼叫使用者自己設定的 LLM API 之外，其餘功能無 fetch、無任何網路請求。

- `FIELDS`（capacity/role/insight/statement/personality/experiment）對應六個 `<textarea>`；`input` 事件觸發 `onFieldChange()` → 更新 LED（`updateLeds()`）→ 即時重繪輸出（`renderOutput()`）→ 存 localStorage（key: `crispePromptState`，`saveState()`）→ 更新預設檔名（`refreshDefaultFilename()`，見下）。
- 輸出有「標籤版」（保留【中文標籤】方便檢查結構）與「精簡版」（去標籤的自然段落）兩種格式，由 `format` 變數與 `#fmtLabeled`／`#fmtMerged` 按鈕切換；只組合非空欄位。
- `PRESETS` 內建 4 組**完全虛構**的情境範例（社群行銷文案顧問、電商客服回覆、課程教學助理、履歷潤稿顧問），對應台灣中小企業／教學顧問常見情境；套用範例若欄位已有內容會先 `confirm()` 詢問是否覆蓋。
- 複製使用 `navigator.clipboard.writeText`，不支援時退回 `document.execCommand('copy')`。
- **「已儲存的提示詞」（rack 最後一個模組，`.saved-module`）是 localStorage 清單，不是檔案下載**——這是刻意的區分：「儲存」＝存進瀏覽器清單，「下載 .txt」才會真的產生檔案。清單存 `localStorage`（key: `crispeSavedPrompts`），每筆 `{id, name, savedAt, fields, format}`；`renderSavedList()` 用事件委派（`#savedList` 上單一 click listener＋`data-action`）處理 載入／複製／下載／重新命名／刪除，避免每筆重繪都要重掛 listener。重新命名走 `prompt()`、刪除走 `confirm()`——原生對話框在這幾個低頻操作上足夠，不需要自訂 modal。
- 儲存名稱欄位（`#filenameInput`）身兼兩用：一是「已儲存的提示詞」存檔時的名稱，二是自動依「任務表述」欄前 20 字產生預設值（`defaultFilename()`／`sanitizeFilename()` 去除 `\/:*?"<>|`）。使用者手動編輯過（`filenameTouched` 旗標）就不再被欄位變動覆蓋，存 localStorage（key: `crispeFilename`，含 `value`／`touched`）；「清空全部」會重置旗標並清掉這個 key，讓名稱回到自動模式。
- `manual.html` 是操作手冊：CRISPE 六個字母說明、操作步驟、AI 一句話產生說明、隱私說明、使用警語、創作者（Mark Tsai）證照與經歷、授權限制。**創作者經歷內容與 `icap-generator/manual.html`、`sbir-generator/manual.html`、`phoenix-loan-generator/manual.html` 為同一份，更新其中一邊時同步其餘各邊。**
- **AI 產生（串接外部 LLM API，選用）**：rack 最上方的 `.ai-module`（teal 配色，與六個 CRISPE 模組的 amber 配色區隔），可串 Claude／OpenAI／Gemini（Google AI Studio）／OpenRouter。實作與 `sbir-generator`／`icap-generator` 相同模式（修改時互相參照）：
  - 全部走瀏覽器直連 `fetch()`：Claude 需 `anthropic-dangerous-direct-browser-access: true` header；Gemini 金鑰放 `x-goog-api-key` header（不放 URL query）；OpenAI/OpenRouter 用 Bearer。預設模型 `claude-opus-4-8` / `gpt-4o-mini` / `gemini-3.5-flash` / `openai/gpt-4o-mini`（模型欄可自由改）。逾時 180 秒；遇暫時性錯誤（429/500/503/529）自動重試最多 2 次（間隔 8、16 秒），重試進度顯示於 `#aiReport`。
  - 設定（provider/model/apiKey）存 `localStorage`（key: `crispeApiConfig`）——**金鑰只落在使用者本機瀏覽器，絕不可寫進程式碼**。`.led-node.ai-led` 的 `ready` class 依 API 金鑰是否已填反映連線狀態。
  - `buildAiPrompt(idea)` 把使用者一句話需求連同 CRISPE 六維度說明組成提示詞，要求模型回傳固定鍵值的 JSON（`{capacity,role,insight,statement,personality,experiment}`），以 `extractJsonObject()` 寬鬆解析；產生前備份現有六欄位到 `localStorage`（key: `crispePromptBackup`），「還原 AI 產生前內容」可復原。
  - 與其他 generator 的差異：這裡是**從一句話生成全新內容**（不是優化既有敘述），所以 prompt 要求模型合理補全未提及的細節，而非用【】標示待補。

## 頂部跑馬燈（2026-07-30 新增）

`#marqueeBar` 固定在頁面最上方（`position:fixed`，z-index 高於 `.topbar` 的 sticky），內容跟 ai-video-studio 系列（主版／`AIvideo_studio` 教學版／`ppt-course-video`／`video-editor`）**共用同一個授權伺服器**（`https://script.google.com/macros/s/AKfycbwKX0.../exec`）與同一份跑馬燈 Google Sheet（<https://docs.google.com/spreadsheets/d/1sSBXW2dAc-4u0j21Q72MzNEBIhDccShhr1iJcAdG0UE/edit>）。本工具沒有序號登入機制，頁面載入時直接 POST 空序號給該網址（`doPost` 不論序號有效與否都會附上 `marquee` 陣列），`localStorage` key `crispeMarquee`，每 20 分鐘背景重抓一次；獨立 `<script>`，跟下方主程式邏輯無關。**`.topbar` 是 `position:sticky;top:0`**，跑馬燈顯示時用 `body.has-marquee .topbar{top:30px}` 把 sticky 的偏移量一起往下推，否則捲動時 topbar 會被固定的跑馬燈蓋住。改跑馬燈內容直接編輯共用 Sheet 即可，不需要重新部署 Apps Script。**`Prompt_Eng/PromptConsole.exe` 已為此重建**（改 `index.html` 後需重新執行 build.ps1／PyInstaller 指令才會反映到 exe 裡，見下方桌面版章節）。

## 隱私與警語

無伺服器端、無任何資料上傳；所有輸入只存在使用者瀏覽器的 localStorage。首頁與手冊皆明列使用警語：本工具僅產生提示詞架構、不對後續 AI 輸出負責、請勿輸入真實個資或機密資料、僅供教學與個人使用禁止商業化。修改功能時這些警語需一併檢視是否仍準確。

## 指令

無建置/測試指令。修改 `index.html` 或 `manual.html` 後直接用瀏覽器開啟驗證，或 `python -m http.server <port> --directory Prompt` 暫起伺服器測完關閉。此工作區以 Chrome 自動化驗證時，`computer` 的 `screenshot` 動作偶發逾時（與 `ai-course-hub` 相同的已知問題），改用 `javascript_tool` 讀 DOM／觸發事件驗證互動邏輯較可靠。

### 桌面版 exe（Prompt_Eng/）

`Prompt_Eng/PromptConsole.exe` 是可攜式單檔桌面版（做法比照 `icap-generator/icap/`）：`launcher.py` 把 index/manual 打包進 exe，執行時於 `127.0.0.1:8777` 起本機伺服器並開預設瀏覽器（**固定 8777 埠**——工作區埠號分配：8765 ai-course-hub、8766 video-editor、8767 fruit-ninja-cam、8770 phoenix-loan exe、8771 icap exe、8772 sbir exe、8773 ai-video-studio、8774 ai-video-studio 桌面版 exe、8775 IPA_Kano dashboard exe、8776 Dashboard 通用儀表板工具、**8777 本專案 exe**）。**修改 index.html／manual.html 後 exe 不會自動更新，需重建**（PowerShell、絕對路徑，`--add-data` 的相對路徑會以 specpath 為準而踩雷）：

```powershell
$proj = "C:\Users\mark_\AI Test\行銷內容工具\Prompt"
cd $proj
python -m PyInstaller --onefile --console --name PromptConsole `
  --distpath "$proj\Prompt_Eng" --workpath "$env:TEMP\pyi-build-prompt" --specpath "$env:TEMP" `
  --add-data "$proj\index.html;." --add-data "$proj\manual.html;." `
  launcher.py
```

exe 未簽章，首次執行會遇 SmartScreen 警告（`Prompt_Eng/使用說明.txt` 已向使用者說明）。**這次建置踩到新坑**：剛編譯出來的 exe 在本機被 **Smart App Control 完全封鎖**（`An Application Control policy has blocked this file`，Code Integrity 事件 3077/3033，PowerShell `Start-Process`／直接呼叫／Git-Bash 背景執行皆同樣被擋，錯誤訊息比一般 SmartScreen 更硬——沒有「仍要執行」可點），而同一台機器上**同日早上 07:31** 建置的 `icap-generator`／`sbir-generator` exe 到了傍晚都能正常啟動——證實是**全新未簽章二進位檔的雲端信譽需要數小時建立**，不是打包方式或 launcher.py 的問題（沒有 Mark-of-the-Web；`Get-Item -Stream *` 確認只有 `:$DATA`）。**不要建議使用者關閉 Smart App Control**。因應措施（均已寫入 `使用說明.txt`）：
1. **`Prompt_Eng/啟動提示詞控制台.bat`**——立即可用的替代啟動方式，用本機已裝的 Python 跑 `../launcher.py`（python.exe 有簽章不被 SAC 擋），同埠同功能，已實測可啟動並回應 200。**bat 檔編碼坑**：內容含中文＋`chcp 65001` 會讓 cmd 中途切換編碼時檔案定位錯亂、把註解文字當指令執行；解法是 bat 內容全 ASCII、以 cp950＋CRLF 寫入（用 python `open(..., encoding="cp950", newline="\r\n")`），檔名本身可以是中文。
2. 等信譽建立（依同日經驗約半天）後 exe 即可直接雙擊。

詳見全域記憶 `windows-smart-app-control-dll-blocks`。測試 exe 時注意：PyInstaller onefile 會有父子兩個程序，`taskkill //IM PromptConsole.exe //F` 才殺得乾淨。
