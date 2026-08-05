-- ════════════════════════════════════════════════════════════════════
-- ตาราง chat_logs — ประวัติการคุยกับน้องแฮปปี้
--
-- ปัญหาเดิม: เก็บใน Google Sheets อย่างเดียว และหน้าประวัติแชตต้องเรียก
--            action=load ซึ่งอ่าน "ทุกชีต" (พนักงาน การสอน ข้อสอบ ฯลฯ)
--            แค่เพื่อจะได้ประวัติแชต — วัดได้ 81 วินาที
--            ย้ายมาที่นี่แล้วจะเหลือไม่ถึง 1 วินาที เหมือนที่ทำกับเคสไปแล้ว
--
-- วิธีใช้: Supabase → โปรเจกต์ cyjfgperenakjeazsfgf → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง)
-- ════════════════════════════════════════════════════════════════════

create table if not exists public.chat_logs (
  id          text primary key,
  ts          text,                 -- ISO string จากฝั่งหน้าเว็บ
  session_id  text,                 -- หนึ่งบทสนทนา = หนึ่ง session
  user_type   text,                 -- branch | admin
  user_key    text,
  user_name   text,
  user_role   text,                 -- branch | admin | bzm | vp | coo
  branch_id   text,
  role        text,                 -- user | bot
  content     text,
  err         boolean default false
);

-- หน้าประวัติแชตเรียงตามเวลาและจัดกลุ่มตาม session เป็นหลัก
create index if not exists chat_logs_ts_idx      on public.chat_logs (ts desc);
create index if not exists chat_logs_session_idx on public.chat_logs (session_id);
create index if not exists chat_logs_branch_idx  on public.chat_logs (branch_id);

-- เปิด RLS แล้วอนุญาตให้ key ฝั่งหน้าเว็บอ่าน/เขียนได้
-- คุมสิทธิ์ที่ชั้น UI เหมือนตารางอื่นในโปรเจกต์นี้ (เฉพาะ Admin เห็นหน้าประวัติแชต)
alter table public.chat_logs enable row level security;

drop policy if exists "chat_logs_all" on public.chat_logs;
create policy "chat_logs_all"
  on public.chat_logs
  for all
  to anon, authenticated
  using (true)
  with check (true);
