-- 소장/앨범 기능에 필요한 게스트 RPC 전체 묶음입니다.
-- SQL Editor 내용을 전부 지우고 이 파일만 전체 실행하세요.

create or replace function public.create_guest_diary(payload jsonb)
returns public.diaries
language plpgsql
security definer
set search_path = public
as $$
declare
  guest_id constant uuid := '00000000-0000-4000-8000-000000000001';
  created_diary public.diaries;
begin
  insert into public.diaries (
    user_id,
    persona_id,
    title,
    diary_at,
    weather,
    content,
    keyword_tags,
    art_style,
    art_sub_style,
    genre,
    genre_subtype,
    webtoon_format,
    is_public,
    generation_status
  )
  values (
    guest_id,
    nullif(payload->>'persona_id', '')::uuid,
    nullif(payload->>'title', ''),
    coalesce(nullif(payload->>'diary_at', '')::timestamptz, timezone('utc', now())),
    coalesce(nullif(payload->>'weather', ''), 'sunny'),
    coalesce(payload->>'content', ''),
    coalesce(
      array(select jsonb_array_elements_text(coalesce(payload->'keyword_tags', '[]'::jsonb))),
      '{}'::text[]
    ),
    coalesce(nullif(payload->>'art_style', ''), 'comics_ld')::public.diary_art_style,
    nullif(payload->>'art_sub_style', ''),
    coalesce(nullif(payload->>'genre', ''), 'daily_comic')::public.diary_genre,
    nullif(payload->>'genre_subtype', ''),
    coalesce(nullif(payload->>'webtoon_format', ''), 'card_slide'),
    coalesce((payload->>'is_public')::boolean, false),
    'completed'::public.diary_generation_status
  )
  returning * into created_diary;

  return created_diary;
end;
$$;

grant execute on function public.create_guest_diary(jsonb) to anon, authenticated;

create or replace function public.add_diary_to_album_guest(payload jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  guest_id constant uuid := '00000000-0000-4000-8000-000000000001';
  target_album_id uuid := (payload->>'target_album_id')::uuid;
  target_diary_id uuid := (payload->>'target_diary_id')::uuid;
begin
  if not exists (
    select 1
    from public.diary_albums
    where id = target_album_id
      and user_id = guest_id
  ) then
    raise exception 'album_not_found';
  end if;

  if not exists (
    select 1
    from public.diaries
    where id = target_diary_id
      and user_id = guest_id
  ) then
    raise exception 'diary_not_found';
  end if;

  update public.diary_albums
  set is_public = true,
      updated_at = timezone('utc', now())
  where id = target_album_id
    and user_id = guest_id;

  insert into public.diary_album_items (
    user_id,
    album_id,
    diary_id
  )
  values (
    guest_id,
    target_album_id,
    target_diary_id
  )
  on conflict (album_id, diary_id) do nothing;
end;
$$;

grant execute on function public.add_diary_to_album_guest(jsonb) to anon, authenticated;

select pg_notify('pgrst', 'reload schema');

select
  routine_name,
  security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in ('create_guest_diary', 'add_diary_to_album_guest')
order by routine_name;
