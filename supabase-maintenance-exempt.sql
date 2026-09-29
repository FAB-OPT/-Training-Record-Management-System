-- ════════════════════════════════════════════════════════════════════
-- ปิดระบบชั่วคราว — เพิ่มคอลัมน์รายชื่อสาขาที่ได้รับยกเว้น (ยังเข้าใช้งานได้แม้ระบบปิดอยู่)
-- ต่อจาก supabase-maintenance-mode.sql / supabase-maintenance-window.sql (ตาราง quiz_meta เดิม)
--
-- วิธีใช้: Supabase → โปรเจกต์ Training Record (cyjfgperenakjeazsfgf) → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง ไม่แตะข้อมูลเดิม)
-- ════════════════════════════════════════════════════════════════════

alter table public.quiz_meta
  add column if not exists maintenance_exempt_branches jsonb not null default '[]'::jsonb;

-- ตรวจผล
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'quiz_meta'
  and column_name = 'maintenance_exempt_branches';
