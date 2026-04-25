-- =========================================================
-- 출결이 · sessions 테이블 마이그레이션 (휴강 기능)
--   - status        : scheduled(진행예정) / cancelled_closed(휴강 종료) / cancelled_makeup(휴강 보강예정)
--   - cancel_reason : holiday(공휴일) / institution(기관사정) / agreement(합의) / other(기타)
--   - cancel_memo   : 자유 메모
--   - makeup_date   : 보강 예정일 (cancelled_makeup 일 때)
--
-- Supabase 대시보드 → SQL Editor 에 붙여넣고 실행하세요.
-- 이미 컬럼이 존재하면 IF NOT EXISTS 로 무시됩니다.
-- =========================================================

ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'scheduled'
  CHECK (status IN ('scheduled','cancelled_closed','cancelled_makeup'));

ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS cancel_reason text;
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS cancel_memo   text;
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS makeup_date   date;
