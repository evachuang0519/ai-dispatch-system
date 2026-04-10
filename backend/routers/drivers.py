from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from models.schemas import Driver, DriverCreate, DriverUpdate
from services.db_service import get_pool

router = APIRouter(prefix="/api/drivers", tags=["drivers"])


@router.get("", response_model=List[dict])
async def list_drivers(region: Optional[str] = None, active: Optional[bool] = None):
    pool = await get_pool()
    query = "SELECT * FROM drivers WHERE 1=1"
    params = []
    if region:
        params.append(region)
        query += f" AND region = ${len(params)}"
    if active is not None:
        params.append(active)
        query += f" AND is_active = ${len(params)}"
    query += " ORDER BY id"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.post("", response_model=dict, status_code=201)
async def create_driver(data: DriverCreate):
    pool = await get_pool()
    row = await pool.fetchrow(
        """INSERT INTO drivers (name, phone, vehicle_type, region, note)
           VALUES ($1,$2,$3,$4,$5) RETURNING *""",
        data.name, data.phone, data.vehicle_type, data.region, data.note
    )
    return dict(row)


@router.get("/{driver_id}", response_model=dict)
async def get_driver(driver_id: int):
    pool = await get_pool()
    row = await pool.fetchrow("SELECT * FROM drivers WHERE id=$1", driver_id)
    if not row:
        raise HTTPException(status_code=404, detail="司機不存在")
    return dict(row)


@router.put("/{driver_id}", response_model=dict)
async def update_driver(driver_id: int, data: DriverUpdate):
    pool = await get_pool()
    row = await pool.fetchrow(
        """UPDATE drivers SET name=$1,phone=$2,vehicle_type=$3,region=$4,note=$5
           WHERE id=$6 RETURNING *""",
        data.name, data.phone, data.vehicle_type, data.region, data.note, driver_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="司機不存在")
    return dict(row)


@router.patch("/{driver_id}/toggle", response_model=dict)
async def toggle_driver(driver_id: int):
    pool = await get_pool()
    row = await pool.fetchrow(
        "UPDATE drivers SET is_active = NOT is_active WHERE id=$1 RETURNING *",
        driver_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="司機不存在")
    return dict(row)
