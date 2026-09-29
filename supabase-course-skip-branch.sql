-- ════════════════════════════════════════════════════════════════════
-- เพิ่มคอลัมน์ skip_branches ให้ตาราง course_catalog
-- = รายชื่อสาขาที่ "ยกเว้น" ไม่ต้องนับว่าค้างอบรมในหลักสูตรนั้น
-- (เช่น สาขาที่ผู้จัดการคนเดียวกันดูแลสองสาขา ส่งคนไปอบรมสาขาเดียวพอ)
--
-- วิธีใช้: เปิด Supabase → โปรเจกต์ cyjfgperenakjeazsfgf → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง)
-- ════════════════════════════════════════════════════════════════════

alter table public.course_catalog
  add column if not exists skip_branches jsonb not null default '[]'::jsonb;

-- ดูผลได้ทันที: หลักสูตรไหนยกเว้นสาขาอะไรไว้บ้าง
-- select name, all_branches, skip_branches from public.course_catalog order by name;
