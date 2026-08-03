-- ════════════════════════════════════════════════════════════════════
-- ตาราง course_catalog — "ทะเบียนหลักสูตร" ของหน้า 📅 จัดอบรม
-- เดิมชื่อหลักสูตรงอกมาจากประวัติการอบรมอย่างเดียว หลักสูตรใหม่ที่ยัง
-- ไม่มีใครผ่านจึงไม่โผล่ในดรอปดาว ตารางนี้เก็บชื่อไว้ต่างหาก
-- แล้วหน้าเว็บจะรวมกับชื่อที่พบในประวัติเวลาแสดงผล
--
-- วิธีใช้: เปิด Supabase → โปรเจกต์ cyjfgperenakjeazsfgf → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง)
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.course_catalog (
  id          text primary key,                   -- CC<timestamp><rand>
  name        text not null,                      -- ชื่อหลักสูตร
  created_by  text,                               -- ชื่อแอดมินที่เพิ่ม
  created_at  timestamptz default now()
);

-- กันชื่อซ้ำแบบไม่สนตัวพิมพ์ใหญ่เล็ก
create unique index if not exists course_catalog_name_key
  on public.course_catalog (lower(name));

-- เปิด RLS แล้วอนุญาตให้ key ฝั่งหน้าเว็บ (anon) อ่าน/เขียนได้
-- — ระบบคุมสิทธิ์ที่ชั้น UI เหมือนตารางอื่นในโปรเจกต์นี้
alter table public.course_catalog enable row level security;

drop policy if exists "course_catalog_all" on public.course_catalog;
create policy "course_catalog_all"
  on public.course_catalog
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- ── เติมชื่อหลักสูตรที่มีอยู่แล้วในประวัติ เข้าทะเบียนให้ครบในครั้งเดียว ──
-- (ไม่บังคับ — ถึงไม่รัน หน้าเว็บก็รวมชื่อจากประวัติให้อยู่แล้ว
--  แต่รันไว้จะทำให้ "เปลี่ยนชื่อ" ทำงานได้เต็มรูปแบบกับทุกหลักสูตร)
insert into public.course_catalog (id, name, created_by)
select
  'CC' || substr(md5(course_name), 1, 12),
  btrim(course_name),
  'migrate'
from (select distinct course_name from public.course_history
      where course_name is not null and btrim(course_name) <> '') s
on conflict do nothing;
