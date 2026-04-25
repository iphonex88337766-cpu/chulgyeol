-- =========================================================
-- 출결이 · v3 마이그레이션
--   - groups.group_type : 기간제(fixed) / 상시(ongoing)
--   - participants.enrolled_from / enrolled_to : 재적 기간
--
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- 이미 컬럼이 있으면 IF NOT EXISTS 로 무시됩니다.
-- =========================================================

ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS group_type text NOT NULL DEFAULT 'fixed'
  CHECK (group_type IN ('fixed','ongoing'));

ALTER TABLE public.participants
  ADD COLUMN IF NOT EXISTS enrolled_from date;

ALTER TABLE public.participants
  ADD COLUMN IF NOT EXISTS enrolled_to date;
