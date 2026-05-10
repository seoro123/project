-- 게스트 프로토타입의 소장 기능을 RLS와 무관하게 안정적으로 처리하는 RPC입니다.
-- SQL Editor에서 이 파일 전체를 실행하세요.

create or replace function public.add_diary_to_album_guest(
  target_album_id uuid,
  target_diary_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  guest_id constant uuid := '00000000-0000-4000-8000-000000000001';
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

grant execute on function public.add_diary_to_album_guest(uuid, uuid) to anon, authenticated;

-- PostgREST가 함수 시그니처를 더 안정적으로 찾도록 jsonb wrapper도 제공합니다.
create or replace function public.add_diary_to_album_guest(payload jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.add_diary_to_album_guest(
    (payload->>'target_album_id')::uuid,
    (payload->>'target_diary_id')::uuid
  );
end;
$$;

grant execute on function public.add_diary_to_album_guest(jsonb) to anon, authenticated;

select pg_notify('pgrst', 'reload schema');
