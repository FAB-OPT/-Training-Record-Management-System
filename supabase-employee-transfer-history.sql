-- เพิ่มคอลัมน์ transfer_history ที่โค้ดอ้างถึงมาตั้งแต่แรก แต่ไม่เคยสร้างจริงในตาราง employees
-- ทำให้ gsSave('employees', ...) ทุกครั้งที่มีการย้ายสาขา ล้มเหลวทั้งแถว (รวม branch_id ด้วย)
-- แบบเงียบๆ — คำขอย้ายขึ้นสถานะ "อนุมัติแล้ว" แต่พนักงานไม่ได้ถูกย้ายจริงในฐานข้อมูล
alter table public.employees add column if not exists transfer_history jsonb default '[]'::jsonb;
