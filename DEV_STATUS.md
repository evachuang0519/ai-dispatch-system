# AI 派單系統 — 開發進度與異常記錄

> 最後更新：2026-04-11

---

## 專案基本資訊

| 項目 | 內容 |
|------|------|
| GitHub Repo | https://github.com/evachuang0519/ai-dispatch-system |
| 工作目錄 | C:\project\rainstart |
| 規格書 | C:\Users\stanl\Downloads\AI派單系統_開發規格書.docx |

---

## 開發進度總覽

| 階段 | 項目 | 狀態 | 備註 |
|------|------|------|------|
| P0 | 資料庫 `init.sql` | ✅ 完成 | `database/init.sql` |
| P0 | FastAPI 骨架 `main.py` | ✅ 完成 | CORS、lifespan、router 掛載 |
| P0 | `models/schemas.py` | ✅ 完成 | Pydantic models 全部定義 |
| P0 | `services/db_service.py` | ✅ 完成 | asyncpg 連線池 |
| P0 | `services/excel_parser.py` | ✅ 完成 | 解析 + 範本產生 |
| P0 | `services/claude_service.py` | ✅ 完成 | 含指數退避重試（最多 3 次） |
| P0 | `routers/drivers.py` | ✅ 完成 | CRUD + toggle |
| P0 | `routers/vehicles.py` | ✅ 完成 | CRUD + toggle + GET 單筆 |
| P0 | `routers/history.py` | ✅ 完成 | 列表、匯入、確認匯入、新增、更新、軟刪除、範本下載 |
| P0 | `routers/upload.py` | ✅ 完成 | GET /orders、上傳、確認、範本下載 |
| P0 | `routers/dispatch.py` | ✅ 完成 | AI 派單、待審清單、單筆查詢、確認、調整、匯出 |
| P0 | `routers/reports.py` | ✅ 完成 | 學習統計、調整記錄、工作量、匯出 |
| P0 | `backend/requirements.txt` | ✅ 完成 | 改為 >= 版本，相容 Python 3.14 |
| P0 | `backend/.env.example` | ✅ 完成 | — |
| P0 | ASP `includes/header.asp` | ✅ 完成 | — |
| P0 | ASP `includes/footer.asp` | ✅ 完成 | — |
| P0 | ASP `includes/db_conn.asp` | ✅ 完成 | HTTP 呼叫封裝函式 |
| P0 | ASP `index.asp` | ✅ 完成 | 首頁導覽 |
| P0 | ASP `drivers.asp` | ✅ 完成 | 列表、篩選、搜尋、停用 |
| P0 | ASP `driver_edit.asp` | ✅ 完成 | 新增 / 編輯表單 |
| P0 | ASP `vehicles.asp` | ✅ 完成 | 列表、篩選、停用 |
| P0 | ASP `vehicle_edit.asp` | ✅ 完成 | — |
| P0 | ASP `history_manage.asp` | ✅ 完成 | — |
| P0 | ASP `history_import.asp` | ✅ 完成 | — |
| P0 | ASP `history_edit.asp` | ✅ 完成 | — |
| P1 | ASP `upload.asp` | ✅ 完成 | — |
| P1 | ASP `dispatch.asp` | ✅ 完成 | — |
| P1 | ASP `dispatch_review.asp` | ✅ 完成 | — |
| P1 | ASP `dispatch_edit.asp` | ✅ 完成 | — |
| P2 | ASP `learning_log.asp` | ✅ 完成 | — |
| P2 | ASP `report.asp` | ✅ 完成 | — |
| — | Git 初始化 + 推送 GitHub | ✅ 完成 | https://github.com/evachuang0519/ai-dispatch-system |
| — | Python 套件安裝 | ✅ 完成 | Python 3.14 環境，套件改用最新版 |
| — | PostgreSQL 安裝 | ✅ 完成 | 17.9，Port 5432，帳號 postgres |
| — | 建立 `.env` | ⏸ 待完成 | 等待 Anthropic API Key |
| — | 執行 `init.sql` 建立資料表 | ⏸ 待完成 | 需先建立 `.env` |
| — | 啟動 FastAPI 實際測試 | ⏸ 待完成 | 需先建立 `.env` 與資料庫 |

---

## 環境資訊

| 項目 | 內容 |
|------|------|
| Python | 3.14.4 |
| PostgreSQL | 17.9 |
| PostgreSQL Port | 5432 |
| PostgreSQL 帳號 | postgres |
| PostgreSQL 資料庫 | ai_dispatch（待建立） |
| PostgreSQL 安裝路徑 | C:\Program Files\PostgreSQL\17 |
| 套件安裝狀態 | ✅ 已安裝（fastapi、asyncpg、anthropic 等） |

---

## Bug 修正記錄（2026-04-11）

規格審查後發現並修正 3 處前後端不一致：

| # | 檔案 | 問題 | 修正 |
|---|------|------|------|
| 1 | `dispatch.asp` | 呼叫不存在的 `/api/orders?status=pending` | `upload.py` 新增 `GET /api/orders` |
| 2 | `dispatch_review.asp` | 用 GET 觸發 `POST /api/dispatch/export` | dispatch export 改為 `GET` |
| 3 | `vehicle_edit.asp` | 呼叫不存在的 `GET /api/vehicles/{id}` | `vehicles.py` 補 GET 單筆端點 |

---

## 異常記錄

### ✅ 異常 001 — Anthropic API 500 Internal Server Error（已修復）
- **發生時間**：2026-04-10
- **現象**：呼叫 Claude API 時回傳 `500 Internal Server Error`
- **原因**：Anthropic 伺服器端暫時性問題
- **修復**：`claude_service.py` `run_dispatch()` 加入指數退避重試（最多 3 次）
- **狀態**：✅ 已修復

### ✅ 異常 002 — pandoc 未安裝（已繞過）
- **發生時間**：2026-04-10
- **現象**：`pandoc: command not found`
- **影響**：使用 Python zipfile 替代方案讀取 .docx，功能不受影響
- **狀態**：✅ 已繞過，無需處理

### ⚠️ 異常 003 — Python 3.14 與固定版套件不相容
- **發生時間**：2026-04-11
- **現象**：`pip install -r requirements.txt` 失敗，pydantic-core / asyncpg 無 Python 3.14 wheel，嘗試從原始碼編譯時 MSVC linker 報錯
- **原因**：requirements.txt 固定版本（如 pydantic==2.7.0）無 Python 3.14 預編譯 wheel
- **修復**：`requirements.txt` 改為 `>=` 版本限制，安裝最新相容版本
- **狀態**：✅ 已修復

---

## 下一步（待執行）

1. **取得 Anthropic API Key**（至 https://console.anthropic.com/ 申請）
2. **建立 `.env`** — 填入 API Key 與資料庫連線
3. **新增 PATH**：`C:\Program Files\PostgreSQL\17\bin` 加入系統環境變數
4. **建立資料庫並執行 init.sql**：
   ```bash
   psql -U postgres -c "CREATE DATABASE ai_dispatch;"
   psql -U postgres -d ai_dispatch -f database/init.sql
   ```
5. **啟動 FastAPI**：
   ```bash
   cd backend
   uvicorn main:app --reload
   ```
6. **測試 API**：開啟 http://localhost:8000/docs 確認所有端點正常

---

## 注意事項

- `ANTHROPIC_API_KEY` 不可提交至 git（`.gitignore` 已排除 `.env`）
- ASP 前端透過 `fetch()` 呼叫 FastAPI，不直連資料庫
- Python 3.14 為目前環境，套件需使用 `>=` 版本限制
