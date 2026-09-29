-- ════════════════════════════════════════════════════════════════════
-- ปิดระบบชั่วคราว — เพิ่มคอลัมน์ maintenance_mode ในตาราง quiz_meta เดิม
-- (ตารางเดียวกับที่เก็บ test_mode อยู่แล้ว ใช้แถว singleton เดียวกัน)
--
-- วิธีใช้: Supabase → โปรเจกต์ Training Record (cyjfgperenakjeazsfgf) → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง ไม่แตะข้อมูลเดิม)
-- ════════════════════════════════════════════════════════════════════

alter table public.quiz_meta
  add column if not exists maintenance_mode boolean not null default false;

-- ตอนนี้ระบบปิดอยู่ด้วยการ hardcode ในโค้ด (MAINTENANCE_MODE = true) — พอรันไฟล์นี้แล้ว
-- โค้ดฝั่งเว็บจะเปลี่ยนไปอ่านค่าจากตารางนี้แทน จึงต้องตั้งแถว singleton ให้เป็น true ไว้ก่อน
-- ไม่งั้นช่วงรอยต่อตอน deploy ระบบจะเผลอเปิดให้เข้าได้ชั่วขณะ — ปิดต่อเนื่องไม่มีช่องโหว่
insert into public.quiz_meta (id, deleted, disabled, maintenance_mode)
values ('singleton', '[]'::jsonb, '[]'::jsonb, true)
on conflict (id) do update set maintenance_mode = true;

-- ตรวจผล: ควรเห็นคอลัมน์ maintenance_mode ชนิด boolean
select column_name, data_type, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'quiz_meta' and column_name = 'maintenance_mode';
