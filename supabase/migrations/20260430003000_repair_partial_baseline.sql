-- baseline을 한 번 실행한 뒤 일부 SQL이 실패했거나, PostgREST cache가 늦게 갱신되는
-- 상태를 복구하는 비파괴 보강 파일입니다. 기존 테이블 데이터는 삭제하지 않습니다.

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

create or replace function public.set_diary_search_text()
returns trigger
language plpgsql
as $$
begin
  new.search_text := lower(
    coalesce(new.title, '') || ' ' ||
    coalesce(new.content, '') || ' ' ||
    coalesce(array_to_string(new.keyword_tags, ' '), '') || ' ' ||
    coalesce(array_to_string(new.emotion_tags, ' '), '')
  );
  return new;
end;
$$;

drop trigger if exists diaries_set_search_text on public.diaries;

create trigger diaries_set_search_text
before insert or update of title, content, keyword_tags, emotion_tags on public.diaries
for each row execute function public.set_diary_search_text();

select pg_notify('pgrst', 'reload schema');
