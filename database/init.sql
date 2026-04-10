-- AI 自動派單系統 資料庫初始化
-- PostgreSQL 15+

-- 司機資料表
CREATE TABLE IF NOT EXISTS drivers (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    phone         VARCHAR(30),
    vehicle_type  VARCHAR(50),          -- 可操作車型
    region        VARCHAR(50),          -- 負責地區
    is_active     BOOLEAN DEFAULT TRUE,
    note          TEXT,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- 車輛資料表
CREATE TABLE IF NOT EXISTS vehicles (
    id            SERIAL PRIMARY KEY,
    plate_no      VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type  VARCHAR(50),          -- 小貨車 / 大貨車 / 冷凍車
    max_weight    DECIMAL,              -- 最大載重 kg
    driver_id     INTEGER REFERENCES drivers(id),
    is_active     BOOLEAN DEFAULT TRUE,
    note          TEXT,
    created_at    TIMESTAMP DEFAULT NOW()
);

-- 訂單資料表
CREATE TABLE IF NOT EXISTS orders (
    id              SERIAL PRIMARY KEY,
    order_no        VARCHAR(50) UNIQUE,
    customer_name   VARCHAR(100),
    address         TEXT,
    region          VARCHAR(50),
    scheduled_time  TIMESTAMP,
    weight          DECIMAL,
    priority        INTEGER DEFAULT 3,  -- 1=最高 5=最低
    status          VARCHAR(20) DEFAULT 'pending',
    data_source     VARCHAR(20) DEFAULT 'import',
    created_at      TIMESTAMP DEFAULT NOW()
);

-- 派單結果資料表
CREATE TABLE IF NOT EXISTS dispatches (
    id           SERIAL PRIMARY KEY,
    order_id     INTEGER REFERENCES orders(id),
    driver_id    INTEGER REFERENCES drivers(id),
    vehicle_id   INTEGER REFERENCES vehicles(id),
    assigned_by  VARCHAR(20),  -- 'ai' 或 'human'
    confidence   DECIMAL,      -- AI 信心分數 0~1
    ai_reason    TEXT,         -- AI 派單理由說明
    created_at   TIMESTAMP DEFAULT NOW()
);

-- 人工調整記錄資料表 (AI 學習資料來源)
CREATE TABLE IF NOT EXISTS dispatch_adjustments (
    id                  SERIAL PRIMARY KEY,
    dispatch_id         INTEGER REFERENCES dispatches(id),
    original_driver_id  INTEGER REFERENCES drivers(id),
    adjusted_driver_id  INTEGER REFERENCES drivers(id),
    original_vehicle_id INTEGER REFERENCES vehicles(id),
    adjusted_vehicle_id INTEGER REFERENCES vehicles(id),
    adjust_reason       VARCHAR(50),
    -- driver_leave: 司機休假/不可用
    -- overload: 超載，需換車
    -- customer_request: 客戶指定司機
    -- region_mismatch: 地區不符
    -- time_conflict: 時段衝突
    -- other: 其他
    adjust_note         TEXT,
    adjusted_by         VARCHAR(100),
    adjusted_at         TIMESTAMP DEFAULT NOW()
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_region ON orders(region);
CREATE INDEX IF NOT EXISTS idx_dispatches_order_id ON dispatches(order_id);
CREATE INDEX IF NOT EXISTS idx_dispatch_adjustments_dispatch_id ON dispatch_adjustments(dispatch_id);
CREATE INDEX IF NOT EXISTS idx_drivers_region ON drivers(region);
CREATE INDEX IF NOT EXISTS idx_drivers_is_active ON drivers(is_active);
