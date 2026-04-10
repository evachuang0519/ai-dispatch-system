from fastapi import APIRouter, HTTPException
from typing import List, Optional
from models.schemas import VehicleCreate, VehicleUpdate
from services.db_service import get_pool

router = APIRouter(prefix="/api/vehicles", tags=["vehicles"])


@router.get("", response_model=List[dict])
async def list_vehicles(vehicle_type: Optional[str] = None, active: Optional[bool] = None):
    pool = await get_pool()
    query = "SELECT v.*, d.name as driver_name FROM vehicles v LEFT JOIN drivers d ON v.driver_id=d.id WHERE 1=1"
    params = []
    if vehicle_type:
        params.append(vehicle_type)
        query += f" AND v.vehicle_type = ${len(params)}"
    if active is not None:
        params.append(active)
        query += f" AND v.is_active = ${len(params)}"
    query += " ORDER BY v.id"
    rows = await pool.fetch(query, *params)
    return [dict(r) for r in rows]


@router.post("", response_model=dict, status_code=201)
async def create_vehicle(data: VehicleCreate):
    pool = await get_pool()
    row = await pool.fetchrow(
        """INSERT INTO vehicles (plate_no, vehicle_type, max_weight, driver_id, note)
           VALUES ($1,$2,$3,$4,$5) RETURNING *""",
        data.plate_no, data.vehicle_type, data.max_weight, data.driver_id, data.note
    )
    return dict(row)


@router.put("/{vehicle_id}", response_model=dict)
async def update_vehicle(vehicle_id: int, data: VehicleUpdate):
    pool = await get_pool()
    row = await pool.fetchrow(
        """UPDATE vehicles SET plate_no=$1,vehicle_type=$2,max_weight=$3,driver_id=$4,note=$5
           WHERE id=$6 RETURNING *""",
        data.plate_no, data.vehicle_type, data.max_weight, data.driver_id, data.note, vehicle_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="車輛不存在")
    return dict(row)


@router.patch("/{vehicle_id}/toggle", response_model=dict)
async def toggle_vehicle(vehicle_id: int):
    pool = await get_pool()
    row = await pool.fetchrow(
        "UPDATE vehicles SET is_active = NOT is_active WHERE id=$1 RETURNING *",
        vehicle_id
    )
    if not row:
        raise HTTPException(status_code=404, detail="車輛不存在")
    return dict(row)
