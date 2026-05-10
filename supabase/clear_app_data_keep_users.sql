-- 인증 유저(auth.users)와 프로필(public.profiles)은 유지합니다.
-- 앱에서 생성된 일기, 컷, 좋아요, 댓글, 팔로우, 앨범, 캐릭터만 비웁니다.

truncate table
  public.diary_album_items,
  public.diary_comments,
  public.diary_likes,
  public.diary_panels,
  public.diaries,
  public.diary_albums,
  public.personas,
  public.follows
restart identity cascade;

select pg_notify('pgrst', 'reload schema');
