-- 게스트 계정으로 생성된 테스트 데이터를 실제로 삭제하는 SQL입니다.
-- SQL Editor에서 실행하면 아래 guest_user_id에 연결된 프로필, 캐릭터, 일기,
-- 좋아요, 댓글, 앨범, 앨범 항목이 모두 삭제됩니다.
-- 되돌릴 수 없으니 실행 전 Supabase 프로젝트가 맞는지 한 번 더 확인하세요.

begin;

create temp table guest_diary_ids as
select id
from public.diaries
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.diary_album_items
where user_id = '00000000-0000-4000-8000-000000000001'
   or diary_id in (select id from guest_diary_ids);

delete from public.diary_likes
where user_id = '00000000-0000-4000-8000-000000000001'
   or diary_id in (select id from guest_diary_ids);

delete from public.diary_comments
where user_id = '00000000-0000-4000-8000-000000000001'
   or diary_id in (select id from guest_diary_ids);

delete from public.diary_panels
where diary_id in (select id from guest_diary_ids);

delete from public.diary_albums
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.diaries
where id in (select id from guest_diary_ids);

delete from public.personas
where user_id = '00000000-0000-4000-8000-000000000001';

delete from public.follows
where follower_id = '00000000-0000-4000-8000-000000000001'
   or following_id = '00000000-0000-4000-8000-000000000001';

delete from public.profiles
where id = '00000000-0000-4000-8000-000000000001';

drop table guest_diary_ids;

commit;

select pg_notify('pgrst', 'reload schema');
