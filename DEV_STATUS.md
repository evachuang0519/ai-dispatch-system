# AI 派單系統 — 開發進度與異常記錄

> 最後更新：2026-04-10

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
| P0 | `services/claude_service.py` | ✅ 完成 | 含重試邏輯待補（見異常記錄） |
| P0 | `routers/drivers.py` | ✅ 完成 | CRUD + toggle |
| P0 | `routers/vehicles.py` | ✅ 完成 | CRUD + toggle |
| P0 | `routers/history.py` | ✅ 完成 | 列表、匯入、新增、更新、軟刪除 |
| P0 | `routers/upload.py` | ✅ 完成 | 上傳、確認、範本下載 |
| P0 | `routers/dispatch.py` | ✅ 完成 | AI 派單、確認、調整、匯出 |
| P0 | `routers/reports.py` | ✅ 完成 | 學習統計、調整記錄、工作量、匯出 |
| P0 | `backend/requirements.txt` | ✅ 完成 | — |
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

---

## 異常記錄

### ❌ 異常 001 — Anthropic API 500 Internal Server Error
- **發生時間**：2026-04-10
- **現象**：呼叫 Claude API 時回傳 `500 {"type":"error","error":{"type":"api_error","message":"Internal server error"}}`
- **原因**：Anthropic 伺服器端暫時性問題（非程式碼錯誤）
- **影響**：`claude_service.py` 中尚未加入重試機制
- **處理方式**：恢復後在 `claude_service.py` 的 `run_dispatch()` 加入指數退避重試，範例如下：
  ```python
  import time
  for attempt in range(3):
      try:
          message = client.messages.create(...)
          break
      except anthropic.APIStatusError as e:
          if e.status_code == 500 and attempt < 2:
              time.sleep(2 ** attempt)
              continue
          raise
  ```
- **狀態**：⏸ 待補充至程式碼

### ⚠️ 異常 002 — pandoc 未安裝
- **發生時間**：2026-04-10
- **現象**：`pandoc: command not found`
- **原因**：開發環境未安裝 pandoc
- **影響**：使用 Python zipfile 替代方案讀取 .docx，功能不受影響
- **狀態**：✅ 已繞過，無需處理

---

## 恢復開發步驟

1. **確認環境**
   ```bash
   cd C:/project/rainstart
   git status
   ```

2. **繼續建立 ASP 頁面**（從 `vehicle_edit.asp` 開始，依上方表格順序）

3. **補充 claude_service.py 重試機制**（異常 001）

4. **Git 初始化並推送**
   ```bash
   git init
   git remote add origin https://github.com/evachuang0519/ai-dispatch-system.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

5. **建立 .env 並測試後端**
   ```bash
   cd backend
   cp .env.example .env
   # 填入 ANTHROPIC_API_KEY 與 DATABASE_URL
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```

---

## 注意事項

- `ANTHROPIC_API_KEY` 不可提交至 git（`.gitignore` 已排除 `.env`）
- GitHub Token 已用於建立 repo，不存入任何程式碼
- ASP 前端透過 `fetch()` 呼叫 FastAPI，不直連資料庫
