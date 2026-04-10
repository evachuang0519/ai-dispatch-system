from fastapi import APIRouter, Query
from fastapi.responses import Response
from typing import Optional
from datetime import date
from services.db_service import get_pool
from openpyxl import Workbook
from io import BytesIO

router = APIRouter(prefix="/api", tags=["reports"])


@router.get("/learning/summary")
async def learning_summary():
    pool = await get_pool()
    rows = await pool.fetch(
        """SELECT DATE(d.created_at) as batch_date,
                  COUNT(*) as total_dispatches,
                  COUNT(*) FILTER (WHERE da.id IS NULL) as ai_accepted
           FROM dispatches d
           LEFT JOIN dispatch_adjustments da ON da.dispatch_id=d.id
           WHERE d.assigned_by='ai'
           GROUP BY DATE(d.created_at)
           ORDER BY batch_date DESC
           LIMIT 30"""
    )
    result = []
    for r in rows:
        total = r["total_dispatches"]
        accepted = r["ai_accepted"]
        result.append({
            "batch_date": str(r["batch_date"]),
            "total_dispatches": total,
            "ai_accepted": accepted,
            "accuracy_rate": round(accepted / total, 4) if total else 0
        })
    return result


@router.get("/learning/adjustments")
async def list_adjustments(date_from: Optional[date] = None, date_to: Optional[date] = None):
    pool = await get_pool()
    query = """
        SELECT da.*, od.name as original_driver, ad2.name as adjusted_driver,
               o.order_no, o.region
        FROM dispatch_adjustments da
        JOIN dispatches dis ON da.dispatch_id=dis.id
        JOIN orders o ON dis.order_id=o.id
        LEFT JOIN drivers od ON da.original_driver_id=od.id
        LEFT JOIN drivers ad2 ON da.adjusted_driver_id=ad2.id
        WHERE 1=1
    """
    params = []
    if date_from:
        params.append(date_from)
        query += f" AND da.adjusted_at >= ${len(params)}"
    if date_to:
        params.append(date_to)
        query += f" AND da.adjusted_at < ${len(params)} + INTERVAL '1 day'"
    query += " ORDER BY da.adjusted_at DESC"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.get("/reports/driver-workload")
async def driver_workload(date_from: Optional[date] = None, date_to: Optional[date] = None):
    pool = await get_pool()
    query = """
        SELECT dr.id as driver_id, dr.name as driver_name, COUNT(d.id) as dispatch_count
        FROM dispatches d
        JOIN drivers dr ON d.driver_id=dr.id
        JOIN orders o ON d.order_id=o.id
        WHERE 1=1
    """
    params = []
    if date_from:
        params.append(date_from)
        query += f" AND o.scheduled_time >= ${len(params)}"
    if date_to:
        params.append(date_to)
        query += f" AND o.scheduled_time < ${len(params)} + INTERVAL '1 day'"
    query += " GROUP BY dr.id, dr.name ORDER BY dispatch_count DESC"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.get("/reports/export")
async def export_report(date_from: Optional[date] = None, date_to: Optional[date] = None):
    pool = await get_pool()
    rows = await pool.fetch(
        """SELECT dr.name as driver_name, o.region, COUNT(*) as cnt
           FROM dispatches d
           JOIN drivers dr ON d.driver_id=dr.id
           JOIN orders o ON d.order_id=o.id
           GROUP BY dr.name, o.region ORDER BY dr.name"""
    )
    wb = Workbook()
    ws = wb.active
    ws.title = "派單報表"
    ws.append(["司機", "地區", "派單數"])
    for r in rows:
        ws.append([r["driver_name"], r["region"], r["cnt"]])
    buf = BytesIO()
    wb.save(buf)
    return Response(
        content=buf.getvalue(),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=report.xlsx"}
    )
