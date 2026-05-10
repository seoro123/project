-- 게스트 프로토타입에서 "소장" 버튼을 눌렀을 때
-- diary_album_items 연결 row가 RLS에 막히지 않도록 보강합니다.
-- 기존 데이터는 삭제하지 않습니다.

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.diary_album_items to anon, authenticated;
grant select on public.diary_albums to anon, authenticated;
grant select on public.diaries to anon, authenticated;

drop policy if exists diary_album_items_insert_own on public.diary_album_items;
drop policy if exists diary_album_items_insert_guest_or_owner on public.diary_album_items;
drop policy if exists diary_album_items_select_visible on public.diary_album_items;

create policy diary_album_items_insert_guest_or_owner on public.diary_album_items
  for insert with check (
    user_id = '00000000-0000-4000-8000-000000000001'
    or auth.uid() = user_id
  );

create policy diary_album_items_select_visible on public.diary_album_items
  for select using (
    user_id = '00000000-0000-4000-8000-000000000001'
    or auth.uid() = user_id
    or exists (
      select 1
      from public.diary_albums a
      where a.id = diary_album_items.album_id
        and a.is_public = true
    )
  );

update public.diary_albums
set is_public = true
where user_id = '00000000-0000-4000-8000-000000000001';

select pg_notify('pgrst', 'reload schema');
