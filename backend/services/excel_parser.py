from openpyxl import load_workbook, Workbook
from io import BytesIO
from datetime import datetime
from typing import List, Dict, Any


# 欄位別名對應（處理空白與大小寫）
ORDER_FIELD_MAP = {
    "訂單編號": "order_no",
    "客戶名稱": "customer_name",
    "地址": "address",
    "地區": "region",
    "預定時段": "scheduled_time",
    "貨物重量(kg)": "weight",
    "客戶優先級": "priority",
    "備註": "note",
}

HISTORY_EXTRA_MAP = {
    "派單司機": "driver_name",
    "車牌號碼": "plate_no",
    "派單備註": "dispatch_note",
}


def _normalize_header(h: str) -> str:
    return h.strip() if h else ""


def parse_orders_excel(file_bytes: bytes) -> List[Dict[str, Any]]:
    wb = load_workbook(BytesIO(file_bytes), data_only=True)
    ws = wb.active
    headers = [_normalize_header(str(c.value)) if c.value else "" for c in next(ws.iter_rows(min_row=1, max_row=1))]

    rows = []
    errors = []
    for row_idx, row in enumerate(ws.iter_rows(min_row=2, values_only=True), start=2):
        if not any(row):
            continue
        record: Dict[str, Any] = {}
        for col_idx, val in enumerate(row):
            if col_idx >= len(headers):
                break
            field = ORDER_FIELD_MAP.get(headers[col_idx])
            if field:
                record[field] = _coerce(field, val, row_idx, errors)
        rows.append(record)
    return rows, errors


def parse_history_excel(file_bytes: bytes) -> List[Dict[str, Any]]:
    wb = load_workbook(BytesIO(file_bytes), data_only=True)
    ws = wb.active
    headers = [_normalize_header(str(c.value)) if c.value else "" for c in next(ws.iter_rows(min_row=1, max_row=1))]

    all_map = {**ORDER_FIELD_MAP, **HISTORY_EXTRA_MAP}
    rows = []
    errors = []
    for row_idx, row in enumerate(ws.iter_rows(min_row=2, values_only=True), start=2):
        if not any(row):
            continue
        record: Dict[str, Any] = {}
        for col_idx, val in enumerate(row):
            if col_idx >= len(headers):
                break
            field = all_map.get(headers[col_idx])
            if field:
                record[field] = _coerce(field, val, row_idx, errors)
        rows.append(record)
    return rows, errors


def _coerce(field: str, val, row_idx: int, errors: list):
    if val is None:
        return None
    if field == "scheduled_time":
        if isinstance(val, datetime):
            return val
        for fmt in ("%Y/%m/%d %H:%M", "%Y-%m-%d %H:%M", "%Y/%m/%d", "%Y-%m-%d"):
            try:
                return datetime.strptime(str(val).strip(), fmt)
            except ValueError:
                continue
        errors.append({"row": row_idx, "field": field, "value": val, "error": "日期格式錯誤"})
        return None
    if field in ("weight", "max_weight"):
        try:
            return float(val)
        except (TypeError, ValueError):
            return None
    if field == "priority":
        try:
            return int(val)
        except (TypeError, ValueError):
            return 3
    return str(val).strip()


def generate_order_template() -> bytes:
    wb = Workbook()
    ws = wb.active
    ws.title = "未派車訂單"
    headers = ["訂單編號", "客戶名稱", "地址", "地區", "預定時段", "貨物重量(kg)", "客戶優先級", "備註"]
    ws.append(headers)
    ws.append(["ORD-001", "客戶A", "台北市信義區XX路1號", "北區", "2026/04/15 09:00", 500, 2, ""])
    buf = BytesIO()
    wb.save(buf)
    return buf.getvalue()


def generate_history_template() -> bytes:
    wb = Workbook()
    ws = wb.active
    ws.title = "歷史派單"
    headers = ["訂單編號", "客戶名稱", "地址", "地區", "預定時段", "貨物重量(kg)", "客戶優先級", "備註",
               "派單司機", "車牌號碼", "派單備註"]
    ws.append(headers)
    ws.append(["ORD-H001", "客戶B", "台中市西區YY路2號", "中區", "2026/04/01 08:00", 800, 1, "", "張三", "ABC-1234", ""])
    buf = BytesIO()
    wb.save(buf)
    return buf.getvalue()
