-- ════════════════════════════════════════════════════════════════════
-- ตาราง cases — "ติดต่อ Admin / เคสจากสาขา"
-- เดิมเก็บใน Google Sheets อย่างเดียว ทำให้โหลดช้า 5-60 วินาที
-- และสาขาส่งเคสแล้วแอดมินไม่เห็นทันที ย้ายมาที่ Supabase จะเหลือไม่ถึง 1 วินาที
--
-- วิธีใช้: เปิด Supabase → โปรเจกต์ cyjfgperenakjeazsfgf → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง)
--
-- ข้อมูลเก่าใน Sheets: หน้าเว็บจะย้ายขึ้นให้เองอัตโนมัติครั้งเดียวตอนเปิดใช้งานครั้งถัดไป
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.cases (
  id             text primary key,
  branch_id      text,                                -- รหัสสาขาที่แจ้ง (เก็บเป็น text เสมอ)
  branch_name    text,
  reporter_name  text,
  reporter_role  text,
  category       text,
  subject        text,
  description    text,
  status         text default 'open',                 -- open · in_progress · resolved · closed
  messages       jsonb not null default '[]'::jsonb,  -- บทสนทนาในเคส
  created_at     text,                                -- ISO string จากฝั่งหน้าเว็บ
  updated_at     text,
  resolved_at    text,
  resolved_by    text
);

-- ค้นหาเคสของสาขา และเรียงตามเวลาอัปเดต ให้เร็ว
create index if not exists cases_branch_idx     on public.cases (branch_id);
create index if not exists cases_status_idx     on public.cases (status);
create index if not exists cases_updated_at_idx on public.cases (updated_at desc);

-- เปิด RLS แล้วอนุญาตให้ key ฝั่งหน้าเว็บ (anon) อ่าน/เขียนได้
-- — ระบบคุมสิทธิ์ที่ชั้น UI เหมือนตารางอื่นในโปรเจกต์นี้
alter table public.cases enable row level security;

drop policy if exists "cases_all" on public.cases;
create policy "cases_all"
  on public.cases
  for all
  to anon, authenticated
  using (true)
  with check (true);
