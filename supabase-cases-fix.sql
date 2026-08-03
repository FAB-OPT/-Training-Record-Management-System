-- ════════════════════════════════════════════════════════════════════
-- แก้ด่วน: ตาราง cases ขาดคอลัมน์ priority
--
-- อาการ: สาขากดแจ้งเคสแล้วเคสหายไป
-- สาเหตุ: ข้อมูลเคสมีฟิลด์ priority (ปกติ/ด่วน) แต่ตารางไม่มีคอลัมน์นี้
--         การบันทึกขึ้น Supabase จึงล้มเหลว พอซิงค์รอบถัดไปเคสก็หายจากหน้าจอ
--
-- วิธีใช้: Supabase → SQL Editor → วางแล้วกด Run (รันซ้ำได้ ไม่พัง)
-- ════════════════════════════════════════════════════════════════════

alter table public.cases
  add column if not exists priority text default 'normal';

-- เผื่อฟิลด์ที่อาจเพิ่มในอนาคต ใส่ไว้ให้ครบตั้งแต่ตอนนี้ กันอาการเดิมซ้ำ
alter table public.cases
  add column if not exists assignee   text,
  add column if not exists closed_at  text,
  add column if not exists closed_by  text;
