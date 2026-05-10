-- 현재 Supabase 프로젝트의 일기, 캐릭터, 앨범, 좋아요, 댓글 데이터를 모두 삭제합니다.
-- profiles/auth.users는 남겨서 계정 시스템은 유지합니다.
-- 되돌릴 수 없는 작업이므로 SQL Editor에서 프로젝트 URL을 확인한 뒤 실행하세요.

begin;

delete from public.diary_album_items;
delete from public.diary_likes;
delete from public.diary_comments;
delete from public.diary_panels;
delete from public.diary_albums;
delete from public.diaries;
delete from public.personas;

commit;

select pg_notify('pgrst', 'reload schema');
