-- Google 로그인 없는 프로토타입에서 고정 게스트 사용자가 만든 소장 앨범을
-- 다시 읽을 수 있도록 RLS를 보강합니다.

drop policy if exists diary_albums_select_own_or_public on public.diary_albums;
drop policy if exists diary_album_items_select_visible on public.diary_album_items;

create policy diary_albums_select_own_or_public on public.diary_albums
  for select using (
    auth.uid() = user_id
    or is_public = true
    or user_id = '00000000-0000-4000-8000-000000000001'
  );

create policy diary_album_items_select_visible on public.diary_album_items
  for select using (
    user_id = '00000000-0000-4000-8000-000000000001'
    or exists (
      select 1
      from public.diary_albums a
      where a.id = diary_album_items.album_id
        and (a.user_id = auth.uid() or a.is_public = true)
    )
  );

update public.diary_albums
set is_public = true
where user_id = '00000000-0000-4000-8000-000000000001';

select pg_notify('pgrst', 'reload schema');
