-- ทะเบียนประชุม: ชื่อประชุม + ต้องเข้าทุกสาขาหรือไม่ (ไม่กระทบประวัติอบรม)
create table if not exists public.meeting_register (
  name          text primary key,
  all_branches  boolean not null default false,
  created_at    timestamptz not null default now()
);
alter table public.meeting_register enable row level security;
drop policy if exists meeting_register_auth_all on public.meeting_register;
create policy meeting_register_auth_all on public.meeting_register
  for all to authenticated using (true) with check (true);
grant select, insert, update, delete on public.meeting_register to authenticated;
