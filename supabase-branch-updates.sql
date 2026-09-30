-- ════════════════════════════════════════════════════════════════════
-- ประวัติการอัพเดทข้อมูลพนักงานของสาขา
--
-- วิธีใช้: Supabase → โปรเจกต์ Training Record (cyjfgperenakjeazsfgf) → SQL Editor
--          วางทั้งไฟล์นี้แล้วกด Run (รันซ้ำได้ ไม่พัง ไม่แตะข้อมูลเดิม)
--
-- ต้องล็อกอินก่อนถึงจะแตะข้อมูลได้ เหมือนทุกตารางในโปรเจกต์นี้ (lock-rls.sql)
-- แอปล็อกอินแบบไม่ระบุตัวตนให้เองตอนเปิดหน้า
-- ════════════════════════════════════════════════════════════════════

-- ปุ่ม "อัพเดทข้อมูลพนักงาน" หน้ารายชื่อพนักงาน — ทุกครั้งที่เพิ่ม/แก้ไข/ขอย้าย หรือกด
-- "ยืนยันไม่มีการเปลี่ยนแปลง" จะบันทึกไว้ที่นี่ 1 แถว ใช้โชว์ "อัพเดทล่าสุด" ที่หน้าสาขา
-- และหน้า "ประวัติการอัพเดทพนักงาน" ฝั่งแอดมิน
-- action: add | edit | transfer | confirm
create table if not exists public.branch_updates (
  id         text primary key,
  branch_id  text not null,
  action     text not null,
  emp_id     text,
  emp_name   text,
  note       text,
  by         text,
  at         text not null
);
create index if not exists branch_updates_branch_idx on public.branch_updates (branch_id, at desc);

-- ── สิทธิ์ ──
alter table public.branch_updates enable row level security;

drop policy if exists branch_updates_auth_all on public.branch_updates;
create policy branch_updates_auth_all on public.branch_updates
  for all to authenticated using (true) with check (true);

grant select, insert, update, delete on public.branch_updates to authenticated;
revoke all on public.branch_updates from anon;

-- ตรวจผล: ควรเห็น 1 แถว rowsecurity = true
select tablename, rowsecurity from pg_tables
where schemaname = 'public' and tablename = 'branch_updates';
