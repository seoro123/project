-- SQL Editor에서 이 파일만 실행해서 RPC가 실제로 등록됐는지 확인하세요.

select
  routine_schema,
  routine_name,
  security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name = 'add_diary_to_album_guest';

select
  p.proname,
  p.prosecdef as is_security_definer,
  pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'add_diary_to_album_guest';
