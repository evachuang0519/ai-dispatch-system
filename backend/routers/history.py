from fastapi import APIRouter, HTTPException, UploadFile, File, Query
from typing import Optional
from datetime import date
from services.db_service import get_pool
from services.excel_parser import parse_history_excel, generate_history_template
from fastapi.responses import Response

router = APIRouter(prefix="/api/history", tags=["history"])


@router.get("")
async def list_history(
    region: Optional[str] = None,
    driver_id: Optional[int] = None,
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
):
    pool = await get_pool()
    query = """
        SELECT o.*, d.id AS dispatch_id, d.assigned_by, d.confidence,
               dr.name AS driver_name, v.plate_no
        FROM orders o
        LEFT JOIN dispatches d ON d.order_id = o.id
        LEFT JOIN drivers dr ON d.driver_id = dr.id
        LEFT JOIN vehicles v ON d.vehicle_id = v.id
        WHERE o.data_source != 'pending_only'
    """
    params = []
    if region:
        params.append(region)
        query += f" AND o.region = ${len(params)}"
    if driver_id:
        params.append(driver_id)
        query += f" AND d.driver_id = ${len(params)}"
    if date_from:
        params.append(date_from)
        query += f" AND o.scheduled_time >= ${len(params)}"
    if date_to:
        params.append(date_to)
        query += f" AND o.scheduled_time < ${len(params)} + INTERVAL '1 day'"
    query += " ORDER BY o.scheduled_time DESC"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.post("/import")
async def import_history(file: UploadFile = File(...)):
    content = await file.read()
    rows, errors = parse_history_excel(content)
    return {"preview": rows, "errors": errors, "total": len(rows)}


@router.post("")
async def create_history(data: dict):
    pool = await get_pool()
    async with pool.acquire() as conn:
        order_row = await conn.fetchrow(
            """INSERT INTO orders (order_no,customer_name,address,region,scheduled_time,weight,priority,status,data_source)
               VALUES ($1,$2,$3,$4,$5,$6,$7,'dispatched','import') RETURNING id""",
            data.get("order_no"), data.get("customer_name"), data.get("address"),
            data.get("region"), data.get("scheduled_time"), data.get("weight"), data.get("priority", 3)
        )
        order_id = order_row["id"]
        # 查詢司機 ID
        driver_row = await conn.fetchrow("SELECT id FROM drivers WHERE name=$1", data.get("driver_name"))
        driver_id = driver_row["id"] if driver_row else None
        vehicle_row = await conn.fetchrow("SELECT id FROM vehicles WHERE plate_no=$1", data.get("plate_no"))
        vehicle_id = vehicle_row["id"] if vehicle_row else None
        dispatch_row = await conn.fetchrow(
            """INSERT INTO dispatches (order_id, driver_id, vehicle_id, assigned_by)
               VALUES ($1,$2,$3,'human') RETURNING id""",
            order_id, driver_id, vehicle_id
        )
    return {"order_id": order_id, "dispatch_id": dispatch_row["id"]}


@router.put("/{history_id}")
async def update_history(history_id: int, data: dict):
    pool = await get_pool()
    await pool.execute(
        """UPDATE orders SET customer_name=$1,address=$2,region=$3,scheduled_time=$4,weight=$5,priority=$6
           WHERE id=$7""",
        data.get("customer_name"), data.get("address"), data.get("region"),
        data.get("scheduled_time"), data.get("weight"), data.get("priority", 3), history_id
    )
    return {"ok": True}


@router.delete("/{history_id}")
async def delete_history(history_id: int):
    pool = await get_pool()
    await pool.execute("UPDATE orders SET status='deleted' WHERE id=$1", history_id)
    return {"ok": True}
