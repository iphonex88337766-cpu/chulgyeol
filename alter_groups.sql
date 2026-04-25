-- =========================================================
-- 출결이 · groups 테이블 마이그레이션
-- 기존 데이터를 보존한 채 v2 컬럼(weekdays/session_time/total_sessions/start_date) 추가
--
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- 이미 컬럼이 존재하면 IF NOT EXISTS 로 무시됩니다.
-- =========================================================

ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS weekdays int[] NOT NULL DEFAULT '{}';
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS session_time time;
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS total_sessions int NOT NULL DEFAULT 0;
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS start_date date;
