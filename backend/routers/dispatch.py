from fastapi import APIRouter, HTTPException
from fastapi.responses import Response
from services.db_service import get_pool
from services.claude_service import run_dispatch
from services.excel_parser import generate_order_template
from models.schemas import AdjustmentCreate
from openpyxl import Workbook
from io import BytesIO

router = APIRouter(prefix="/api/dispatch", tags=["dispatch"])


@router.get("/pending")
async def list_pending_dispatches():
    """供 dispatch_review.asp 使用：取得待審核的 AI 派單清單"""
    pool = await get_pool()
    rows = await pool.fetch(
        """SELECT d.id AS dispatch_id, d.driver_id, d.vehicle_id, d.confidence, d.ai_reason,
                  o.id AS order_id, o.order_no, o.customer_name, o.region, o.scheduled_time, o.priority,
                  dr.name AS driver_name, v.plate_no
           FROM dispatches d
           JOIN orders o ON d.order_id = o.id
           JOIN drivers dr ON d.driver_id = dr.id
           LEFT JOIN vehicles v ON d.vehicle_id = v.id
           WHERE d.assigned_by = 'ai' AND o.status = 'pending'
           ORDER BY o.priority, o.scheduled_time"""
    )
    return [dict(r) for r in rows]


@router.get("/{dispatch_id}")
async def get_dispatch(dispatch_id: int):
    """供 dispatch_edit.asp 使用：取得單筆派單資料"""
    pool = await get_pool()
    row = await pool.fetchrow(
        """SELECT d.*, o.order_no, dr.name AS driver_name, v.plate_no
           FROM dispatches d
           JOIN orders o ON d.order_id = o.id
           JOIN drivers dr ON d.driver_id = dr.id
           LEFT JOIN vehicles v ON d.vehicle_id = v.id
           WHERE d.id = $1""",
        dispatch_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="派單記錄不存在")
    return dict(row)


@router.post("")
async def ai_dispatch():
    pool = await get_pool()
    async with pool.acquire() as conn:
        orders = [dict(r) for r in await conn.fetch(
            "SELECT * FROM orders WHERE status='pending' ORDER BY priority, scheduled_time"
        )]
        if not orders:
            return {"suggestions": [], "message": "無待派訂單"}

        drivers = [dict(r) for r in await conn.fetch(
            "SELECT id,name,vehicle_type,region FROM drivers WHERE is_active=TRUE"
        )]
        vehicles = [dict(r) for r in await conn.fetch(
            "SELECT v.id,v.plate_no,v.vehicle_type,v.max_weight,d.name as driver_name "
            "FROM vehicles v LEFT JOIN drivers d ON v.driver_id=d.id WHERE v.is_active=TRUE"
        )]
        adjustments = [dict(r) for r in await conn.fetch(
            """SELECT da.adjust_reason, da.adjust_note,
                      o.region, o.scheduled_time, o.priority,
                      od.name as original_driver, ad2.name as adjusted_driver
               FROM dispatch_adjustments da
               JOIN dispatches dis ON da.dispatch_id=dis.id
               JOIN orders o ON dis.order_id=o.id
               LEFT JOIN drivers od ON da.original_driver_id=od.id
               LEFT JOIN drivers ad2 ON da.adjusted_driver_id=ad2.id
               ORDER BY da.adjusted_at DESC LIMIT 50"""
        )]

    suggestions = await run_dispatch(orders, drivers, vehicles, adjustments)

    # 儲存 AI 派單結果
    async with pool.acquire() as conn:
        for s in suggestions:
            await conn.execute(
                """INSERT INTO dispatches (order_id,driver_id,vehicle_id,assigned_by,confidence,ai_reason)
                   VALUES ($1,$2,$3,'ai',$4,$5)
                   ON CONFLICT DO NOTHING""",
                s["order_id"], s["driver_id"], s["vehicle_id"], s.get("confidence"), s.get("reason")
            )

    return {"suggestions": suggestions, "total": len(suggestions)}


@router.post("/confirm/{dispatch_id}")
async def confirm_dispatch(dispatch_id: int):
    pool = await get_pool()
    row = await pool.fetchrow("SELECT order_id FROM dispatches WHERE id=$1", dispatch_id)
    if not row:
        raise HTTPException(status_code=404, detail="派單記錄不存在")
    await pool.execute("UPDATE orders SET status='dispatched' WHERE id=$1", row["order_id"])
    return {"ok": True}


@router.post("/adjust")
async def adjust_dispatch(data: AdjustmentCreate):
    pool = await get_pool()
    async with pool.acquire() as conn:
        orig = await conn.fetchrow(
            "SELECT driver_id, vehicle_id FROM dispatches WHERE id=$1", data.dispatch_id
        )
        if not orig:
            raise HTTPException(status_code=404, detail="派單記錄不存在")

        await conn.execute(
            """INSERT INTO dispatch_adjustments
               (dispatch_id, original_driver_id, adjusted_driver_id,
                original_vehicle_id, adjusted_vehicle_id, adjust_reason, adjust_note, adjusted_by)
               VALUES ($1,$2,$3,$4,$5,$6,$7,$8)""",
            data.dispatch_id, orig["driver_id"], data.adjusted_driver_id,
            orig["vehicle_id"], data.adjusted_vehicle_id,
            data.adjust_reason, data.adjust_note, data.adjusted_by
        )
        # 更新派單結果
        await conn.execute(
            "UPDATE dispatches SET driver_id=$1, vehicle_id=$2, assigned_by='human' WHERE id=$3",
            data.adjusted_driver_id, data.adjusted_vehicle_id, data.dispatch_id
        )
    return {"ok": True}


@router.post("/export")
async def export_dispatches():
    pool = await get_pool()
    rows = await pool.fetch(
        """SELECT o.order_no, o.customer_name, o.region, o.scheduled_time,
                  dr.name as driver_name, v.plate_no, d.assigned_by, d.confidence
           FROM dispatches d
           JOIN orders o ON d.order_id=o.id
           JOIN drivers dr ON d.driver_id=dr.id
           LEFT JOIN vehicles v ON d.vehicle_id=v.id
           WHERE o.status='dispatched'
           ORDER BY o.scheduled_time"""
    )
    wb = Workbook()
    ws = wb.active
    ws.title = "派單結果"
    ws.append(["訂單編號", "客戶名稱", "地區", "預定時段", "司機", "車牌", "派單方式", "AI信心分數"])
    for r in rows:
        ws.append([r["order_no"], r["customer_name"], r["region"],
                   str(r["scheduled_time"]), r["driver_name"], r["plate_no"],
                   r["assigned_by"], float(r["confidence"]) if r["confidence"] else ""])
    buf = BytesIO()
    wb.save(buf)
    return Response(
        content=buf.getvalue(),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=dispatch_result.xlsx"}
    )
