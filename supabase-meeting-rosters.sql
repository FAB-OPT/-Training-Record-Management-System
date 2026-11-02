-- ใบรายชื่อประชุมของสาขา (ทำแล้วเก็บไว้ เปิด PDF ซ้ำได้) — ไม่เกี่ยวกับประวัติอบรม
create table if not exists public.meeting_rosters (
  id          uuid primary key default gen_random_uuid(),
  meeting     text not null,
  branch_code text not null,
  info        jsonb not null default '{}'::jsonb,
  people      jsonb not null default '[]'::jsonb,
  created_at  timestamptz not null default now()
);
alter table public.meeting_rosters enable row level security;
drop policy if exists meeting_rosters_auth_all on public.meeting_rosters;
create policy meeting_rosters_auth_all on public.meeting_rosters
  for all to authenticated using (true) with check (true);
grant select, insert, update, delete on public.meeting_rosters to authenticated;
