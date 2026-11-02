-- ประชุมที่ต้องครบทุกสาขา: สาขาไหนเข้าแล้ว / ยกเว้นไว้
-- ไม่เกี่ยวกับประวัติอบรมของพนักงาน (ทะเบียนประชุมไม่บันทึกประวัติ)
create table if not exists public.meeting_coverage (
  meeting     text not null,
  branch_code text not null,
  status      text not null check (status in ('done', 'excused')),
  note        text not null default '',
  updated_at  timestamptz not null default now(),
  primary key (meeting, branch_code)
);

alter table public.meeting_coverage enable row level security;

drop policy if exists meeting_coverage_auth_all on public.meeting_coverage;
create policy meeting_coverage_auth_all on public.meeting_coverage
  for all to authenticated using (true) with check (true);

grant select, insert, update, delete on public.meeting_coverage to authenticated;
