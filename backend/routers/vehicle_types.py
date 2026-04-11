from fastapi import APIRouter, HTTPException
from typing import List
from models.schemas import VehicleTypeCreate
from services.db_service import get_pool

router = APIRouter(prefix="/api/vehicle-types", tags=["vehicle-types"])


@router.get("", response_model=List[dict])
async def list_vehicle_types():
    pool = await get_pool()
    rows = await pool.fetch("SELECT * FROM vehicle_types ORDER BY sort_order, id")
    return [dict(r) for r in rows]


@router.post("", response_model=dict, status_code=201)
async def create_vehicle_type(data: VehicleTypeCreate):
    pool = await get_pool()
    try:
        row = await pool.fetchrow(
            "INSERT INTO vehicle_types (name, sort_order) VALUES ($1,$2) RETURNING *",
            data.name.strip(), data.sort_order
        )
    except Exception:
        raise HTTPException(status_code=409, detail="車型名稱已存在")
    return dict(row)


@router.delete("/{type_id}", response_model=dict)
async def delete_vehicle_type(type_id: int):
    pool = await get_pool()
    row = await pool.fetchrow(
        "DELETE FROM vehicle_types WHERE id=$1 RETURNING *", type_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="車型不存在")
    return dict(row)
