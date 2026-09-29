-- ════════════════════════════════════════════════════════════════════
-- เพิ่มคอลัมน์ all_branches ให้ตาราง course_catalog
-- = "หลักสูตรนี้ต้องอบรมทุกสาขาอย่างน้อย 1 คน"
-- หน้า 📅 จัดอบรม จะใช้ค่านี้บอกว่าสาขาไหนยังไม่มีใครผ่านหลักสูตรนั้น
--
-- วิธีใช้: เปิด Supabase → โปรเจกต์ cyjfgperenakjeazsfgf → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง)
-- ════════════════════════════════════════════════════════════════════

alter table public.course_catalog
  add column if not exists all_branches boolean not null default false;

-- ดูผลได้ทันที: หลักสูตรที่ติ๊กไว้มีอะไรบ้าง
-- select name, all_branches from public.course_catalog order by all_branches desc, name;
