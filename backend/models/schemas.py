from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


# ── Driver ──────────────────────────────────────────────
class DriverBase(BaseModel):
    name: str
    phone: Optional[str] = None
    vehicle_type: Optional[str] = None
    region: Optional[str] = None
    note: Optional[str] = None

class DriverCreate(DriverBase):
    pass

class DriverUpdate(DriverBase):
    pass

class Driver(DriverBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ── Vehicle ─────────────────────────────────────────────
class VehicleBase(BaseModel):
    plate_no: str
    vehicle_type: Optional[str] = None
    max_weight: Optional[Decimal] = None
    driver_id: Optional[int] = None
    note: Optional[str] = None

class VehicleCreate(VehicleBase):
    pass

class VehicleUpdate(VehicleBase):
    pass

class Vehicle(VehicleBase):
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


# ── Order ────────────────────────────────────────────────
class OrderBase(BaseModel):
    order_no: Optional[str] = None
    customer_name: Optional[str] = None
    address: Optional[str] = None
    region: Optional[str] = None
    scheduled_time: Optional[datetime] = None
    weight: Optional[Decimal] = None
    priority: int = 3

class OrderCreate(OrderBase):
    pass

class Order(OrderBase):
    id: int
    status: str
    data_source: str
    created_at: datetime

    class Config:
        from_attributes = True


# ── Dispatch ─────────────────────────────────────────────
class DispatchSuggestion(BaseModel):
    order_id: int
    driver_id: int
    vehicle_id: int
    confidence: float
    reason: str

class DispatchResult(BaseModel):
    dispatch_id: int
    order_id: int
    driver_id: int
    vehicle_id: int
    assigned_by: str
    confidence: Optional[float] = None
    ai_reason: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


# ── Dispatch Adjustment ──────────────────────────────────
class AdjustmentCreate(BaseModel):
    dispatch_id: int
    adjusted_driver_id: int
    adjusted_vehicle_id: int
    adjust_reason: str
    adjust_note: Optional[str] = None
    adjusted_by: str


# ── VehicleType ──────────────────────────────────────────
class VehicleTypeCreate(BaseModel):
    name: str
    sort_order: int = 0

class VehicleTypeItem(BaseModel):
    id: int
    name: str
    sort_order: int
    created_at: datetime

    class Config:
        from_attributes = True


# ── Learning / Report ────────────────────────────────────
class LearningStats(BaseModel):
    batch_date: Optional[datetime] = None
    total_dispatches: int
    ai_accepted: int
    accuracy_rate: float

class DriverWorkload(BaseModel):
    driver_id: int
    driver_name: str
    dispatch_count: int
