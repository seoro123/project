-- 게스트 프로토타입 데이터 삭제용 SQL입니다.
-- 삭제 대상:
-- - guest user id로 만든 앨범/앨범 항목
-- - guest user id로 만든 일기/컷/좋아요/댓글
-- - guest user id로 만든 캐릭터
-- - guest profile row
--
-- 실행하면 되돌릴 수 없습니다. SQL Editor에서 실행하기 전 대상 count를 먼저 확인하세요.

select 'profiles' as table_name, count(*) as rows
from public.profiles
where id = '00000000-0000-4000-8000-000000000001'
union all
select 'personas', count(*)
from public.personas
where user_id = '00000000-0000-4000-8000-000000000001'
union all
select 'diaries', count(*)
from public.diaries
where user_id = '00000000-0000-4000-8000-000000000001'
union all
select 'diary_albums', count(*)
from public.diary_albums
where user_id = '00000000-0000-4000-8000-000000000001'
union all
select 'diary_album_items', count(*)
from public.diary_album_items
where user_id = '00000000-0000-4000-8000-000000000001';

-- 아래 delete 블록은 정말 삭제할 때만 주석을 해제해서 실행하세요.
/*
delete from public.diary_album_items
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.diary_likes
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.diary_comments
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.diary_albums
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.diary_panels
where diary_id in (
  select id
  from public.diaries
  where user_id = '00000000-0000-4000-8000-000000000001'
);

delete from public.diaries
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.personas
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.profiles
where id = '00000000-0000-4000-8000-000000000001';

select pg_notify('pgrst', 'reload schema');
*/
