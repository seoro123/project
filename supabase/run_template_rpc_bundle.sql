-- 캐릭터 생성 기능에 필요한 게스트 RPC입니다.
-- SQL Editor 내용을 전부 지우고 이 파일만 전체 실행하세요.

create or replace function public.create_guest_persona(payload jsonb)
returns public.personas
language plpgsql
security definer
set search_path = public
as $$
declare
  guest_id constant uuid := '00000000-0000-4000-8000-000000000001';
  created_persona public.personas;
  should_share boolean := coalesce((payload->>'is_public')::boolean, true);
begin
  insert into public.personas (
    user_id,
    name,
    input_mode,
    appearance_desc,
    appearance_tags,
    emotion_prompts,
    expression_library,
    default_seed,
    default_art_style,
    default_genre,
    base_image_url,
    image_url,
    template_visibility,
    is_public,
    generation_status
  )
  values (
    guest_id,
    coalesce(nullif(payload->>'name', ''), '공유 캐릭터'),
    coalesce(nullif(payload->>'input_mode', ''), 'prose'),
    coalesce(payload->>'appearance_desc', '기본 캐릭터'),
    coalesce(payload->'appearance_tags', '{"tags":[]}'::jsonb),
    coalesce(payload->'emotion_prompts', '{}'::jsonb),
    coalesce(payload->'expression_library', '{}'::jsonb),
    coalesce((payload->>'default_seed')::integer, 1),
    coalesce(nullif(payload->>'default_art_style', ''), 'anime_ld')::public.diary_art_style,
    coalesce(nullif(payload->>'default_genre', ''), 'daily_comic')::public.diary_genre,
    nullif(payload->>'base_image_url', ''),
    nullif(payload->>'image_url', ''),
    case when should_share then 'public' else 'private' end,
    should_share,
    'completed'::public.diary_generation_status
  )
  returning * into created_persona;

  return created_persona;
end;
$$;

grant execute on function public.create_guest_persona(jsonb) to anon, authenticated;

create or replace function public.get_guest_personas()
returns setof public.personas
language sql
security definer
set search_path = public
as $$
  select *
  from public.personas
  where user_id = '00000000-0000-4000-8000-000000000001'
     or is_public = true
  order by created_at desc;
$$;

grant execute on function public.get_guest_personas() to anon, authenticated;

select pg_notify('pgrst', 'reload schema');

select routine_name, security_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in ('create_guest_persona', 'get_guest_personas')
order by routine_name;
