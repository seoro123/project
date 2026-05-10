-- 게스트 프로토타입에서 일기 생성이 diaries RLS에 막히지 않도록
-- DB 내부에서 소유권을 고정 검증하고 row를 만드는 RPC입니다.

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

select pg_notify('pgrst', 'reload schema');
