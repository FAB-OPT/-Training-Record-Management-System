-- ════════════════════════════════════════════════════════════════════
-- ปิดระบบชั่วคราว — เพิ่มคอลัมน์ช่วงวันที่ (maintenance_from / maintenance_to)
-- ต่อจาก supabase-maintenance-mode.sql (ตาราง quiz_meta เดิม แถว singleton เดียวกัน)
--
-- วิธีใช้: Supabase → โปรเจกต์ Training Record (cyjfgperenakjeazsfgf) → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง ไม่แตะข้อมูลเดิม)
-- ════════════════════════════════════════════════════════════════════

alter table public.quiz_meta
  add column if not exists maintenance_from date,
  add column if not exists maintenance_to   date;

-- ตรวจผล: ควรเห็น 2 แถว
select column_name, data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'quiz_meta'
  and column_name in ('maintenance_from', 'maintenance_to');
