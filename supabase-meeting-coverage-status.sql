-- เพิ่มสถานะ "ทำใบรายชื่อแล้ว" ให้ประชุมที่ต้องครบทุกสาขา (รันหลัง supabase-meeting-coverage.sql)
alter table public.meeting_coverage drop constraint if exists meeting_coverage_status_check;
alter table public.meeting_coverage add constraint meeting_coverage_status_check
  check (status in ('rostered', 'done', 'excused'));
