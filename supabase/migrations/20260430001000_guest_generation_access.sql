-- Google 로그인을 제거한 1차 프로토타입에서도 일기/캐릭터 생성이 막히지 않도록
-- 게스트 작성자 row를 허용하는 보강 마이그레이션입니다.

alter table public.profiles drop constraint if exists profiles_id_fkey;

drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;
drop policy if exists personas_insert_own on public.personas;
drop policy if exists personas_update_own on public.personas;
drop policy if exists diaries_insert_own on public.diaries;
drop policy if exists diaries_update_own on public.diaries;
drop policy if exists diary_albums_insert_own on public.diary_albums;
drop policy if exists diary_albums_update_own on public.diary_albums;
drop policy if exists diary_album_items_insert_own on public.diary_album_items;

create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id or auth.uid() is null);

create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id or auth.uid() is null)
  with check (auth.uid() = id or auth.uid() is null);

create policy personas_insert_own on public.personas
  for insert with check (auth.uid() = user_id or auth.uid() is null);

create policy personas_update_own on public.personas
  for update using (auth.uid() = user_id or auth.uid() is null)
  with check (auth.uid() = user_id or auth.uid() is null);

create policy diaries_insert_own on public.diaries
  for insert with check (auth.uid() = user_id or auth.uid() is null);

create policy diaries_update_own on public.diaries
  for update using (auth.uid() = user_id or auth.uid() is null)
  with check (auth.uid() = user_id or auth.uid() is null);

create policy diary_albums_insert_own on public.diary_albums
  for insert with check (auth.uid() = user_id or auth.uid() is null);

create policy diary_albums_update_own on public.diary_albums
  for update using (auth.uid() = user_id or auth.uid() is null)
  with check (auth.uid() = user_id or auth.uid() is null);

create policy diary_album_items_insert_own on public.diary_album_items
  for insert with check (
    (auth.uid() = user_id or auth.uid() is null)
    and exists (
      select 1
      from public.diary_albums a
      where a.id = album_id
        and (a.user_id = user_id or auth.uid() is null)
    )
    and exists (
      select 1
      from public.diaries d
      where d.id = diary_id
        and (d.user_id = user_id or auth.uid() is null)
    )
  );
