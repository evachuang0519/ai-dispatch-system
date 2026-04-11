from fastapi import APIRouter, HTTPException, UploadFile, File, Query
from typing import Optional
from datetime import date
from services.db_service import get_pool
from services.excel_parser import parse_history_excel, generate_history_template
from fastapi.responses import Response

router = APIRouter(prefix="/api/history", tags=["history"])


def _order_fields(data: dict, status: str = "dispatched") -> tuple:
    """回傳 (欄位值 tuple) 供 INSERT/UPDATE 使用"""
    return (
        data.get("order_no"),
        data.get("order_date"),
        data.get("customer_type"),
        data.get("customer_name"),
        data.get("id_no"),
        data.get("contact_phone"),
        data.get("payment_type"),
        data.get("trip_type"),
        data.get("pickup_time"),
        data.get("region"),
        data.get("departure"),
        data.get("departure"),          # address 沿用 departure
        data.get("destination"),
        data.get("dropoff_time"),
        data.get("mileage"),
        data.get("fare"),
        data.get("companion_fee"),
        data.get("self_pay"),
        data.get("vehicle_accessories"),
        data.get("subsidy_balance"),
        data.get("qualification"),
        data.get("note"),
        data.get("form_filler"),
        data.get("grade"),
        data.get("scheduled_time"),
        status,
    )


_INSERT_ORDER_SQL = """
    INSERT INTO orders (
        order_no, order_date, customer_type, customer_name, id_no, contact_phone,
        payment_type, trip_type, pickup_time, region, departure, address, destination,
        dropoff_time, mileage, fare, companion_fee, self_pay, vehicle_accessories,
        subsidy_balance, qualification, note, form_filler, grade,
        scheduled_time, status, data_source
    ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,'import'
    )
    ON CONFLICT (order_no) DO NOTHING RETURNING id
"""

_INSERT_ORDER_SQL_NO_CONFLICT = """
    INSERT INTO orders (
        order_no, order_date, customer_type, customer_name, id_no, contact_phone,
        payment_type, trip_type, pickup_time, region, departure, address, destination,
        dropoff_time, mileage, fare, companion_fee, self_pay, vehicle_accessories,
        subsidy_balance, qualification, note, form_filler, grade,
        scheduled_time, status, data_source
    ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,'import'
    ) RETURNING id
"""


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
        WHERE o.status != 'deleted'
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
        query += f" AND o.order_date >= ${len(params)}"
    if date_to:
        params.append(date_to)
        query += f" AND o.order_date <= ${len(params)}"
    query += " ORDER BY o.order_date DESC, o.pickup_time"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.get("/template")
async def download_history_template():
    content = generate_history_template()
    return Response(
        content=content,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=history_template.xlsx"}
    )


@router.post("/import")
async def import_history(file: UploadFile = File(...)):
    content = await file.read()
    rows, errors = parse_history_excel(content)
    return {"preview": rows, "errors": errors, "total": len(rows)}


@router.post("/import/confirm")
async def confirm_history_import(rows: list[dict]):
    pool = await get_pool()
    inserted, errors = 0, []
    async with pool.acquire() as conn:
        for idx, row in enumerate(rows):
            try:
                # 若無 order_no 則自動產生
                if not row.get("order_no"):
                    d = row.get("order_date") or ""
                    n = (row.get("customer_name") or "")[:4]
                    row["order_no"] = f"{d}-{n}-{idx+1}"

                order_row = await conn.fetchrow(_INSERT_ORDER_SQL, *_order_fields(row, "dispatched"))
                if not order_row:
                    continue  # order_no 衝突跳過

                driver_row = await conn.fetchrow(
                    "SELECT id FROM drivers WHERE name=$1", row.get("driver_name")
                )
                vehicle_row = await conn.fetchrow(
                    "SELECT id FROM vehicles WHERE plate_no=$1", row.get("plate_no")
                )
                await conn.execute(
                    """INSERT INTO dispatches (order_id, driver_id, vehicle_id, assigned_by)
                       VALUES ($1,$2,$3,'human')""",
                    order_row["id"],
                    driver_row["id"] if driver_row else None,
                    vehicle_row["id"] if vehicle_row else None,
                )
                inserted += 1
            except Exception as e:
                errors.append({"row": idx + 1, "name": row.get("customer_name"), "error": str(e)})
    return {"inserted": inserted, "errors": errors}


@router.post("")
async def create_history(data: dict):
    pool = await get_pool()
    async with pool.acquire() as conn:
        order_row = await conn.fetchrow(_INSERT_ORDER_SQL_NO_CONFLICT, *_order_fields(data, "dispatched"))
        order_id = order_row["id"]
        driver_row = await conn.fetchrow("SELECT id FROM drivers WHERE name=$1", data.get("driver_name"))
        vehicle_row = await conn.fetchrow("SELECT id FROM vehicles WHERE plate_no=$1", data.get("plate_no"))
        dispatch_row = await conn.fetchrow(
            "INSERT INTO dispatches (order_id, driver_id, vehicle_id, assigned_by) VALUES ($1,$2,$3,'human') RETURNING id",
            order_id,
            driver_row["id"] if driver_row else None,
            vehicle_row["id"] if vehicle_row else None,
        )
    return {"order_id": order_id, "dispatch_id": dispatch_row["id"]}


@router.get("/{history_id}")
async def get_history(history_id: int):
    pool = await get_pool()
    row = await pool.fetchrow(
        """SELECT o.*, d.id AS dispatch_id, d.assigned_by,
                  dr.name AS driver_name, v.plate_no
           FROM orders o
           LEFT JOIN dispatches d ON d.order_id = o.id
           LEFT JOIN drivers dr ON d.driver_id = dr.id
           LEFT JOIN vehicles v ON d.vehicle_id = v.id
           WHERE o.id=$1""",
        history_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="記錄不存在")
    return dict(row)


@router.put("/{history_id}")
async def update_history(history_id: int, data: dict):
    pool = await get_pool()
    await pool.execute(
        """UPDATE orders SET
            order_date=$1, customer_type=$2, customer_name=$3, id_no=$4, contact_phone=$5,
            payment_type=$6, trip_type=$7, pickup_time=$8, region=$9,
            departure=$10, address=$10, destination=$11, dropoff_time=$12,
            mileage=$13, fare=$14, companion_fee=$15, self_pay=$16,
            vehicle_accessories=$17, subsidy_balance=$18, qualification=$19,
            note=$20, form_filler=$21, grade=$22, scheduled_time=$23
           WHERE id=$24""",
        data.get("order_date"), data.get("customer_type"), data.get("customer_name"),
        data.get("id_no"), data.get("contact_phone"), data.get("payment_type"),
        data.get("trip_type"), data.get("pickup_time"), data.get("region"),
        data.get("departure"), data.get("destination"), data.get("dropoff_time"),
        data.get("mileage"), data.get("fare"), data.get("companion_fee"), data.get("self_pay"),
        data.get("vehicle_accessories"), data.get("subsidy_balance"), data.get("qualification"),
        data.get("note"), data.get("form_filler"), data.get("grade"),
        data.get("scheduled_time"), history_id
    )
    return {"ok": True}


@router.delete("/{history_id}")
async def delete_history(history_id: int):
    pool = await get_pool()
    await pool.execute("UPDATE orders SET status='deleted' WHERE id=$1", history_id)
    return {"ok": True}
