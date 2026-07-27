-- ════════════════════════════════════════════════════════════════════
-- ตาราง training_drafts — "แบบร่างใบรายชื่อผู้เข้าอบรม" ของหน้า 📅 จัดอบรม
-- แอดมินกดบันทึกร่างไว้ที่เครื่องไหนก็ได้ แล้วเปิดทำต่อจากเครื่องอื่นได้
--
-- วิธีใช้: เปิด Supabase → โปรเจกต์ cyjfgperenakjeazsfgf → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง)
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.training_drafts (
  id          text primary key,                       -- draft_<timestamp>_<rand>
  course      text,                                   -- ชื่อหลักสูตร
  batch       text,                                   -- รุ่นที่
  train_date  text,                                   -- วันที่อบรม (YYYY-MM-DD)
  train_time  text,                                   -- เวลา เช่น "09:00 - 16:00"
  place       text,                                   -- สถานที่
  trainer     text,                                   -- วิทยากร
  people      jsonb not null default '[]'::jsonb,     -- [{id,name,empCode,position,branchId}]
  created_by  text,                                   -- ชื่อแอดมินที่บันทึกล่าสุด
  saved_at    text,                                   -- ISO timestamp ที่บันทึกล่าสุด
  created_at  timestamptz default now()
);

-- เปิด RLS แล้วอนุญาตให้ key ฝั่งหน้าเว็บ (anon) อ่าน/เขียนได้
-- — ระบบคุมสิทธิ์ที่ชั้น UI เหมือนตารางอื่นในโปรเจกต์นี้
alter table public.training_drafts enable row level security;

drop policy if exists "training_drafts_all" on public.training_drafts;
create policy "training_drafts_all"
  on public.training_drafts
  for all
  to anon, authenticated
  using (true)
  with check (true);

-- เรียงตามที่บันทึกล่าสุด (หน้าเว็บ sort เองอยู่แล้ว แต่ index ช่วยตอนร่างเยอะ)
create index if not exists training_drafts_saved_at_idx on public.training_drafts (saved_at desc);
