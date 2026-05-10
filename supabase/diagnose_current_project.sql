-- SQL Editor 내용을 전부 지우고 이 내용만 실행하세요.
-- 결과를 보면 앱이 기대하는 테이블이 현재 Supabase 프로젝트에 실제로 있는지 확인할 수 있습니다.

select current_database() as database_name;
select current_schema() as schema_name;

select
  to_regclass('public.profiles') as profiles_table,
  to_regclass('public.diaries') as diaries_table,
  to_regclass('public.personas') as personas_table,
  to_regclass('public.diary_albums') as diary_albums_table;

select
  schemaname,
  tablename
from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles',
    'personas',
    'diaries',
    'diary_panels',
    'diary_albums',
    'diary_album_items'
  )
order by tablename;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;
grant usage, select on all sequences in schema public to anon, authenticated;

select pg_notify('pgrst', 'reload schema');
