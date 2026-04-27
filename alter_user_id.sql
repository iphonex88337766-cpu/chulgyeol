-- =========================================================
-- 출결이 · v5 마이그레이션: 사용자별 데이터 분리
--
-- 변경 사항
--   1) groups / participants / sessions / attendance 에 user_id 컬럼 추가
--      (default auth.uid() — 클라이언트 insert 시 자동 채움)
--   2) 인덱스 추가
--   3) 기존 anon 공개 정책(anon_all) 제거
--   4) authenticated 사용자가 본인 row 만 접근 가능한 RLS 정책 적용
--
-- 주의
--   - 기존 v1.0 데이터의 user_id 는 NULL 로 남습니다.
--     RLS 정책상 NULL 인 row 는 어떤 사용자에게도 보이지 않게 됩니다.
--     보존이 필요하면 아래 [선택] 블록 참고하여 본인 계정으로 클레임하세요.
-- =========================================================

-- 1) user_id 컬럼 추가
alter table public.groups
  add column if not exists user_id uuid
  references auth.users(id) on delete cascade
  default auth.uid();

alter table public.participants
  add column if not exists user_id uuid
  references auth.users(id) on delete cascade
  default auth.uid();

alter table public.sessions
  add column if not exists user_id uuid
  references auth.users(id) on delete cascade
  default auth.uid();

alter table public.attendance
  add column if not exists user_id uuid
  references auth.users(id) on delete cascade
  default auth.uid();

-- 2) 인덱스
create index if not exists idx_groups_user       on public.groups(user_id);
create index if not exists idx_participants_user on public.participants(user_id);
create index if not exists idx_sessions_user     on public.sessions(user_id);
create index if not exists idx_attendance_user   on public.attendance(user_id);

-- 3) 정책 교체: anon 공개 → authenticated 본인 row 만
do $$
declare t text;
begin
  foreach t in array array['groups','participants','sessions','attendance'] loop
    execute format('drop policy if exists anon_all on public.%I', t);
    execute format('drop policy if exists own_rows on public.%I', t);
    execute format($p$
      create policy own_rows on public.%I
      for all
      to authenticated
      using (user_id = auth.uid())
      with check (user_id = auth.uid())
    $p$, t);
  end loop;
end$$;

-- =========================================================
-- [선택] 기존 v1.0 데이터를 본인 계정으로 클레임
--
-- SQL 에디터에서는 auth.uid() 가 NULL 이므로 직접 본인 user id 를 넣어야 합니다.
--
-- 1) 본인 id 확인:
--    select id, email from auth.users;
--
-- 2) 아래 'PASTE-YOUR-UUID' 를 본인 id 로 바꿔 실행:
--
-- update public.groups       set user_id = 'PASTE-YOUR-UUID' where user_id is null;
-- update public.participants set user_id = 'PASTE-YOUR-UUID' where user_id is null;
-- update public.sessions     set user_id = 'PASTE-YOUR-UUID' where user_id is null;
-- update public.attendance   set user_id = 'PASTE-YOUR-UUID' where user_id is null;
-- =========================================================
