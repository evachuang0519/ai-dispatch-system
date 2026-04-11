from fastapi import APIRouter, UploadFile, File
from fastapi.responses import Response
from typing import Optional
from services.db_service import get_pool
from services.excel_parser import parse_orders_excel, generate_order_template

router = APIRouter(prefix="/api", tags=["upload"])

_pending_preview: list = []


@router.get("/orders")
async def list_orders(status: Optional[str] = None):
    pool = await get_pool()
    query = "SELECT * FROM orders WHERE status != 'deleted'"
    params = []
    if status:
        params.append(status)
        query += f" AND status = ${len(params)}"
    query += " ORDER BY order_date, pickup_time"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.post("/upload")
async def upload_orders(file: UploadFile = File(...)):
    global _pending_preview
    content = await file.read()
    rows, errors = parse_orders_excel(content)
    _pending_preview = rows
    return {"preview": rows, "errors": errors, "total": len(rows)}


@router.post("/upload/confirm")
async def confirm_upload(selected_indices: list[int] | None = None):
    pool = await get_pool()
    rows = _pending_preview
    if selected_indices is not None:
        rows = [rows[i] for i in selected_indices if i < len(rows)]

    inserted, errors = 0, []
    async with pool.acquire() as conn:
        for idx, row in enumerate(rows):
            try:
                if not row.get("order_no"):
                    d = row.get("order_date") or ""
                    n = (row.get("customer_name") or "")[:4]
                    row["order_no"] = f"{d}-{n}-{idx+1}"

                await conn.execute(
                    """INSERT INTO orders (
                        order_no, order_date, customer_type, customer_name, id_no, contact_phone,
                        payment_type, trip_type, pickup_time, region, departure, address, destination,
                        mileage, fare, companion_fee, self_pay,
                        subsidy_balance, qualification, note, form_filler, grade,
                        scheduled_time, status, data_source
                    ) VALUES (
                        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,'pending','import'
                    ) ON CONFLICT (order_no) DO NOTHING""",
                    row.get("order_no"),
                    row.get("order_date"),
                    row.get("customer_type"),
                    row.get("customer_name"),
                    row.get("id_no"),
                    row.get("contact_phone"),
                    row.get("payment_type"),
                    row.get("trip_type"),
                    row.get("pickup_time"),
                    row.get("region"),
                    row.get("departure"),
                    row.get("destination"),
                    row.get("mileage"),
                    row.get("fare"),
                    row.get("companion_fee"),
                    row.get("self_pay"),
                    row.get("subsidy_balance"),
                    row.get("qualification"),
                    row.get("note"),
                    row.get("form_filler"),
                    row.get("grade"),
                    row.get("scheduled_time"),
                )
                inserted += 1
            except Exception as e:
                errors.append({"row": idx + 1, "name": row.get("customer_name"), "error": str(e)})
    return {"inserted": inserted, "errors": errors}


@router.get("/upload/template")
async def download_template():
    content = generate_order_template()
    return Response(
        content=content,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=order_template.xlsx"}
    )
