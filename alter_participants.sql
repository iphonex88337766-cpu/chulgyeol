-- =========================================================
-- 출결이 · participants 테이블 마이그레이션
-- 참여자 재적 기간(enrolled_from / enrolled_to) 컬럼 추가
--
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- 이미 컬럼이 존재하면 IF NOT EXISTS 로 무시됩니다.
-- =========================================================

ALTER TABLE public.participants ADD COLUMN IF NOT EXISTS enrolled_from date;
ALTER TABLE public.participants ADD COLUMN IF NOT EXISTS enrolled_to   date;
