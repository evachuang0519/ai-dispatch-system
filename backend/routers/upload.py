from fastapi import APIRouter, UploadFile, File
from fastapi.responses import Response
from services.db_service import get_pool
from services.excel_parser import parse_orders_excel, generate_order_template

router = APIRouter(prefix="/api/upload", tags=["upload"])

_pending_preview: list = []


@router.post("")
async def upload_orders(file: UploadFile = File(...)):
    global _pending_preview
    content = await file.read()
    rows, errors = parse_orders_excel(content)
    _pending_preview = rows
    return {"preview": rows, "errors": errors, "total": len(rows)}


@router.post("/confirm")
async def confirm_upload(selected_indices: list[int] | None = None):
    pool = await get_pool()
    rows = _pending_preview
    if selected_indices is not None:
        rows = [rows[i] for i in selected_indices if i < len(rows)]

    inserted = 0
    errors = []
    async with pool.acquire() as conn:
        for row in rows:
            try:
                await conn.execute(
                    """INSERT INTO orders (order_no,customer_name,address,region,scheduled_time,weight,priority,status,data_source)
                       VALUES ($1,$2,$3,$4,$5,$6,$7,'pending','import')
                       ON CONFLICT (order_no) DO NOTHING""",
                    row.get("order_no"), row.get("customer_name"), row.get("address"),
                    row.get("region"), row.get("scheduled_time"), row.get("weight"), row.get("priority", 3)
                )
                inserted += 1
            except Exception as e:
                errors.append({"order_no": row.get("order_no"), "error": str(e)})
    return {"inserted": inserted, "errors": errors}


@router.get("/template")
async def download_template():
    content = generate_order_template()
    return Response(
        content=content,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=order_template.xlsx"}
    )
