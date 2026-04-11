# AI 派單系統 — 開發進度與異常記錄

> 最後更新：2026-04-11（第三次更新）

---

## 專案基本資訊

| 項目 | 內容 |
|------|------|
| GitHub Repo | https://github.com/evachuang0519/ai-dispatch-system |
| 工作目錄 | C:\project\rainstart |
| 規格書 | C:\Users\stanl\Downloads\AI派單系統_開發規格書.docx |
| 參考排班檔 | C:\Users\stanl\Downloads\1121已排班.xlsx（189 筆） |

---

## 系統架構

```
瀏覽器
  ├─► IIS port 80  →  C:\project\rainstart\frontend\  （Classic ASP）
  └─► FastAPI port 8000  →  C:\project\rainstart\backend\  （Python 3.14）
                               └─► PostgreSQL ai_dispatch（port 5432）
```

**啟動指令**：`cd C:/project/rainstart/backend && python -m uvicorn main:app --reload`

---

## 業務流程理解

本系統為**身心障礙/長者復康巴士派單系統**：

1. **歷史派單匯入**：將過去已排班的 Excel（如 1121已排班.xlsx）匯入作為 AI 學習資料
2. **新訂單上傳**：將待派車訂單上傳系統
3. **AI 自動派單**：Claude API 分析歷史規律，為每筆訂單建議司機+車輛
4. **人工審核**：調度員確認或調整 AI 建議
5. **學習閉環**：人工調整記錄供 AI 下次改進

**訂單特性**：
- 客戶類型：電話（單次）、包月（固定客戶）
- 性質：送（去程）、來（回程）、單（單趟）
- 補助/自費：1=補助（政府補助），2=自費
- 地區：土城區、板橋區等（新北市為主）

---

## 資料庫現況（2026-04-11）

### drivers（司機）— 共 15 筆

| 來源 | 筆數 | 說明 |
|------|------|------|
| 測試資料 | 2 筆 | 王大明（ID:1）、魚大夫（ID:2），已有車型/地區 |
| Excel 匯入 | 13 筆 | 吳質欽、張國光、李是慰、林君偉、林育德、王國盛、王錫川、邱明昶、邱柏勳、陳建勳、陳議盛、黃冠羽、黃永清 |

⚠️ Excel 匯入的 13 位司機目前**缺少**：可操作車型、負責地區、電話

### vehicles（車輛）— 共 14 筆

| 來源 | 車牌 | 車型 |
|------|------|------|
| 測試資料 | ABC-1234 | 箱型車（ID:1） |
| Excel 匯入 | RCY-5021, RCY-5012, RCY-5013, RCY-5010, RCY-2287, RCY-2291, RCY-2292, RCJ-3137, RDJ-5603, RDJ-5782, RDJ-7813, RDQ-0152, RDQ-0157 | 一般（10輛）、輪（3輛） |

⚠️ 所有 Excel 匯入車輛**未關聯司機**（driver_id = NULL）

### vehicle_types（車型）— 共 5 筆
`一般車`、`福祉車`、`小貨車`、`大貨車`、`冷凍車`

⚠️ 車型命名不一致：vehicles 表用「一般」「輪」，vehicle_types 維護表用「一般車」「福祉車」

### orders（訂單）— 0 筆
**尚未匯入**，等待執行批次匯入

---

## 開發進度總覽

| 階段 | 項目 | 狀態 | 備註 |
|------|------|------|------|
| P0 | 資料庫 schema | ✅ 完成 | 5 張核心表 + vehicle_types + orders 擴充 20 欄 |
| P0 | 後端 API（8 個 router） | ✅ 完成 | 全端點正常 |
| P0 | 前端 ASP（15 頁） | ✅ 完成 | IIS 正常服務 |
| P0 | 環境設定（IIS + FastAPI + DB） | ✅ 完成 | 全部正常運作 |
| 資料 | 司機資料建立 | ✅ 完成 | 13 筆從 Excel 匯入 |
| 資料 | 車輛資料建立 | ✅ 完成 | 13 筆從 Excel 匯入 |
| 資料 | 歷史派單匯入 | ⏸ 待執行 | 1121已排班.xlsx，189 筆 |
| 資料 | 司機補齊資料 | ⏸ 待補 | 車型、地區、電話 |
| 資料 | 車輛關聯司機 | ⏸ 待設定 | driver_id 目前全為 NULL |
| AI | Prompt 更新 | ⏸ 待執行 | 加入新欄位供 AI 學習 |
| AI | AI 派單實測 | ⏸ 待執行 | 需先有歷史資料 |
| 驗證 | 學習記錄 / 報表 | ⏸ 待驗證 | 需有真實派單資料 |
| 維護 | 車型命名統一 | ⏸ 待確認 | 「一般」vs「一般車」、「輪」vs「福祉車」 |
| 維護 | Git 推送 | ⏸ 待執行 | 大量修改尚未推送 |

---

## Bug 修正記錄

| # | 問題 | 修正 |
|---|------|------|
| 1 | `/api/orders` 端點不存在 | `upload.py` 新增 |
| 2 | dispatch export GET/POST 錯誤 | 改為 GET |
| 3 | `GET /api/vehicles/{id}` 不存在 | 補端點 |
| 4 | VBScript `If()` 語法錯誤 | 改為 `If...Then...Else` |
| 5 | 中文 VBScript 編譯錯誤 800a03f9 | 各頁加 `<%@ CodePage=65001 %>` |
| 6 | ASP 全站中文亂碼 | `header.asp` 加 Charset/CodePage |
| 7 | IIS fetch 打到 port 80 | 全站改用 `API_BASE + '/api/...'` |
| 8 | `Dim API_BASE` 重複宣告 | 移除 header.asp 中的宣告 |
| 9 | 民國年 float 解析失敗 | `_parse_roc_date` 加 float→int |
| 10 | `dispatch.asp` 中文亂碼 | 加 CodePage，待派清單欄位更新 |

---

## 待辦事項（按優先順序）

| 優先 | 項目 | 說明 |
|------|------|------|
| 🔴 高 | 歷史派單批次匯入 | 至「歷史派單→批次匯入」上傳 1121已排班.xlsx |
| 🔴 高 | 司機資料補齊 | 13 位司機需補車型、地區、電話 |
| 🔴 高 | 車輛關聯司機 | 各車輛設定對應司機 |
| 🟡 中 | 車型命名統一 | 決定「一般/輪」或「一般車/福祉車」並統一 |
| 🟡 中 | AI Prompt 更新 | `claude_service.py` 加入地區/性質/出發地等欄位 |
| 🟡 中 | AI 派單實測 | 歷史資料就緒後測試 |
| 🟢 低 | 地區下拉動態化 | 目前硬編碼，考慮資料庫維護 |
| 🟢 低 | 學習記錄/報表驗證 | 有真實資料後測試 |
| 🟢 低 | Git 推送 | 推送至 GitHub |

---

## 異常記錄

### ✅ 異常 001 — Anthropic API 500（已修復）
`claude_service.py` 加入指數退避重試最多 3 次。

### ✅ 異常 002 — pandoc 未安裝（已繞過）
改用 Python zipfile 讀取 .docx。

### ✅ 異常 003 — Python 3.14 套件相容性（已修復）
`requirements.txt` 改為 `>=` 版本限制。

---

## 注意事項

- `.env` 不可 commit（含 Anthropic API Key）
- ASP 頁含中文 VBScript → 第一行必須 `<%@ CodePage=65001 %>`
- Excel 數字欄位可能為 float → 解析前需轉 int
- 民國年格式：1141121 = 2025/11/21（`_parse_roc_date` 自動轉換）
- `_pending_preview` 為 in-memory，FastAPI 重啟後消失
