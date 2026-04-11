-- 新增車輛類型維護資料表
CREATE TABLE IF NOT EXISTS vehicle_types (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(50) UNIQUE NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 預設車型
INSERT INTO vehicle_types (name, sort_order) VALUES
    ('小貨車', 1),
    ('大貨車', 2),
    ('冷凍車', 3)
ON CONFLICT (name) DO NOTHING;
