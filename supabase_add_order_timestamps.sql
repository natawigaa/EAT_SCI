-- เพิ่ม columns สำหรับ timestamp แต่ละสถานะ และเหตุผลการยกเลิก (Phase 3)
-- รันใน Supabase SQL Editor

ALTER TABLE orders
ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS preparing_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS ready_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- เพิ่ม comment อธิบาย
COMMENT ON COLUMN orders.confirmed_at IS 'เวลาที่ร้านยืนยันรับออเดอร์';
COMMENT ON COLUMN orders.preparing_at IS 'เวลาที่เริ่มทำอาหาร';
COMMENT ON COLUMN orders.ready_at IS 'เวลาที่อาหารพร้อม';
COMMENT ON COLUMN orders.completed_at IS 'เวลาที่ลูกค้ารับอาหารแล้ว';
COMMENT ON COLUMN orders.cancelled_at IS 'เวลาที่ยกเลิกออเดอร์';
COMMENT ON COLUMN orders.cancellation_reason IS 'เหตุผลการยกเลิกออเดอร์';
