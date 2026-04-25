-- =========================================================
-- 출결이 · Supabase 스키마 v2 (재설계)
--
-- ⚠ 이 스크립트는 기존 groups/participants/sessions/attendance 테이블과
--    그 안의 데이터를 모두 삭제합니다 (DROP CASCADE).
--    데이터를 보존해야 한다면 별도로 백업 후 실행하세요.
-- =========================================================

drop table if exists public.attendance   cascade;
drop table if exists public.sessions     cascade;
drop table if exists public.participants cascade;
drop table if exists public.groups       cascade;

-- ----------------------------
-- 1) 테이블
-- ----------------------------
create table public.groups (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  manager        text,                         -- 담당자
  group_type     text not null default 'fixed'  -- 기간제(fixed) / 상시(ongoing)
                 check (group_type in ('fixed','ongoing')),
  weekdays       int[] not null default '{}',  -- 0=일, 1=월, ..., 6=토
  session_time   time,                         -- 회기 시간 (예: 14:00)
  total_sessions int  not null default 0,      -- 기간제일 때만 사용
  start_date     date,
  created_at     timestamptz not null default now()
);

create table public.participants (
  id            uuid primary key default gen_random_uuid(),
  group_id      uuid not null references public.groups(id) on delete cascade,
  name          text not null,
  age           int,
  school        text,
  notes         text,
  enrolled_from date,   -- 참여 시작일 (없으면 처음부터 재적)
  enrolled_to   date,   -- 참여 종료일 (없으면 계속 재적)
  created_at    timestamptz not null default now()
);

create table public.sessions (
  id             uuid primary key default gen_random_uuid(),
  group_id       uuid not null references public.groups(id) on delete cascade,
  session_number int  not null,  -- 1회기, 2회기, ...
  session_date   date not null,
  status         text not null default 'scheduled'
                 check (status in ('scheduled','cancelled_closed','cancelled_makeup')),
  cancel_reason  text,           -- holiday / institution / agreement / other
  cancel_memo    text,
  makeup_date    date,           -- cancelled_makeup 일 때 보강 예정일
  created_at     timestamptz not null default now(),
  unique (group_id, session_number)
);

create table public.attendance (
  id                uuid primary key default gen_random_uuid(),
  session_id        uuid not null references public.sessions(id)     on delete cascade,
  participant_id    uuid not null references public.participants(id) on delete cascade,
  status            text not null default 'absent' check (status in ('present','absent')),
  parent_counseling boolean not null default false,
  created_at        timestamptz not null default now(),
  unique (session_id, participant_id)
);

-- ----------------------------
-- 2) 인덱스
-- ----------------------------
create index idx_participants_group       on public.participants(group_id);
create index idx_sessions_group_number    on public.sessions(group_id, session_number);
create index idx_sessions_group_date      on public.sessions(group_id, session_date);
create index idx_attendance_session       on public.attendance(session_id);
create index idx_attendance_participant   on public.attendance(participant_id);

-- ----------------------------
-- 3) RLS (anon 공개 정책 — 개인용 도구 가정)
-- ----------------------------
alter table public.groups       enable row level security;
alter table public.participants enable row level security;
alter table public.sessions     enable row level security;
alter table public.attendance   enable row level security;

do $$
declare t text;
begin
  foreach t in array array['groups','participants','sessions','attendance'] loop
    execute format('drop policy if exists anon_all on public.%I', t);
    execute format('create policy anon_all on public.%I for all to anon using (true) with check (true)', t);
  end loop;
end$$;

-- ----------------------------
-- 4) 마이그레이션 (기존 groups 테이블에 v2 컬럼 추가)
--    위의 CREATE TABLE 을 건너뛰고 기존 데이터를 유지하면서
--    v2 컬럼만 보충하고 싶을 때 실행해도 됩니다 (IF NOT EXISTS).
-- ----------------------------
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS weekdays int[] NOT NULL DEFAULT '{}';
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS session_time time;
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS total_sessions int NOT NULL DEFAULT 0;
ALTER TABLE public.groups ADD COLUMN IF NOT EXISTS start_date date;

-- v3 (2026-04): 그룹 유형 + 참여자 재적 기간
ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS group_type text NOT NULL DEFAULT 'fixed'
  CHECK (group_type IN ('fixed','ongoing'));
ALTER TABLE public.participants ADD COLUMN IF NOT EXISTS enrolled_from date;
ALTER TABLE public.participants ADD COLUMN IF NOT EXISTS enrolled_to date;

-- v4 (2026-04): 회기 휴강 기능
ALTER TABLE public.sessions
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'scheduled'
  CHECK (status IN ('scheduled','cancelled_closed','cancelled_makeup'));
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS cancel_reason text;
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS cancel_memo   text;
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS makeup_date   date;
