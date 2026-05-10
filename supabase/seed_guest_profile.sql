-- 앱이 Google 로그인 없이도 일기/캐릭터를 저장할 수 있게 기본 게스트 프로필을 만듭니다.
-- SQL Editor 내용을 전부 지우고 이 파일만 실행하세요.

insert into public.profiles (
  id,
  username,
  display_name,
  is_public
)
values (
  '00000000-0000-4000-8000-000000000001',
  'guest_user',
  '게스트 사용자',
  true
)
on conflict (id) do update set
  username = excluded.username,
  display_name = excluded.display_name,
  is_public = excluded.is_public,
  updated_at = timezone('utc', now());

select
  to_regclass('public.profiles') as profiles_table,
  to_regclass('public.diaries') as diaries_table,
  to_regclass('public.personas') as personas_table,
  to_regclass('public.diary_albums') as diary_albums_table;

select pg_notify('pgrst', 'reload schema');
