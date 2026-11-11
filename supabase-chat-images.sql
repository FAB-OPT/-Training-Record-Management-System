-- ภาพที่แนบในแชตน้องแฮปปี้ (ภาพย่อ) — ให้แอดมินเปิดดูในหน้าประวัติแชต
-- เก็บแยกจาก chat_logs เพื่อไม่ให้โหลดประวัติหนัก · ผูกกับแถวแชตด้วย id เดียวกัน · ลบแชต = รูปถูกลบตามอัตโนมัติ
create table if not exists public.chat_images (
  id text primary key references public.chat_logs(id) on delete cascade,
  img text not null,
  created_at timestamptz not null default now()
);
alter table public.chat_images enable row level security;
drop policy if exists chat_images_auth_all on public.chat_images;
create policy chat_images_auth_all on public.chat_images for all to authenticated using (true) with check (true);
