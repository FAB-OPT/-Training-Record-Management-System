-- ════════════════════════════════════════════════════════════════════
-- แผนการสอนงานประจำเดือน + คำขอย้ายสาขา
--
-- วิธีใช้: Supabase → โปรเจกต์ Training Record (cyjfgperenakjeazsfgf) → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง ไม่แตะข้อมูลเดิม)
--
-- ต้องล็อกอินก่อนถึงจะแตะข้อมูลได้ เหมือนทุกตารางในโปรเจกต์นี้ (lock-rls.sql)
-- แอปล็อกอินแบบไม่ระบุตัวตนให้เองตอนเปิดหน้า
-- ════════════════════════════════════════════════════════════════════

-- ── 1) แผนการสอนงานประจำเดือน ─────────────────────────────────────────
-- 1 แถว = 1 สาขา 1 เดือน · id = <รหัสสาขา>_<YYYY-MM>
-- items: [{ id, moduleId, subtopics[], empIds[], planDate, note }]
--   ครัวหรือบริการดูจากกลุ่มของ Module (Cook / Service)
-- แผนเป็นแค่ตัวช่วยวางงาน — บันทึกการสอนจริงไม่ต้องตรงแผน ระบบไม่ฟ้อง
create table if not exists public.coaching_plans (
  id          text primary key,
  branch_id   text not null,
  month       text not null,                          -- YYYY-MM
  items       jsonb not null default '[]'::jsonb,
  updated_by  text,
  updated_at  text
);
create index if not exists coaching_plans_branch_idx on public.coaching_plans (branch_id, month);

-- ── 2) คำขอย้ายสาขา ───────────────────────────────────────────────────
-- สาขาขอย้ายพนักงาน → admin อนุมัติ → ระบบย้ายด้วยฟังก์ชันย้ายเดิม (เก็บ transfer_history)
-- status: pending | approved | rejected | cancelled
create table if not exists public.transfer_requests (
  id             text primary key,
  emp_id         text not null,
  emp_name       text,
  emp_code       text,
  position       text,
  from_branch    text not null,
  to_branch      text not null,
  move_date      text,                                -- YYYY-MM-DD
  reason         text,
  status         text not null default 'pending',
  requested_by   text,
  requested_at   text,
  decided_by     text,
  decided_at     text,
  decision_note  text
);
create index if not exists transfer_requests_status_idx on public.transfer_requests (status);

-- ── สิทธิ์ ──
alter table public.coaching_plans    enable row level security;
alter table public.transfer_requests enable row level security;

drop policy if exists coaching_plans_auth_all on public.coaching_plans;
create policy coaching_plans_auth_all on public.coaching_plans
  for all to authenticated using (true) with check (true);

drop policy if exists transfer_requests_auth_all on public.transfer_requests;
create policy transfer_requests_auth_all on public.transfer_requests
  for all to authenticated using (true) with check (true);

grant select, insert, update, delete on public.coaching_plans    to authenticated;
grant select, insert, update, delete on public.transfer_requests to authenticated;
revoke all on public.coaching_plans    from anon;
revoke all on public.transfer_requests from anon;

-- ตรวจผล: ควรเห็น 2 แถว rowsecurity = true
select tablename, rowsecurity from pg_tables
where schemaname = 'public' and tablename in ('coaching_plans','transfer_requests');
