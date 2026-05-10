-- AI 일기 & 소셜 플랫폼 새 기준선 스키마입니다.
-- 기존 개발 DB는 보존하지 않고 Supabase reset 후 이 파일 하나로 다시 시작합니다.

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists vector;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'diary_art_style') then
    create type public.diary_art_style as enum (
      'comics_ld',
      'comics_sd',
      'anime_ld',
      'anime_sd',
      'realistic_3d',
      'simple_2d'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'diary_genre') then
    create type public.diary_genre as enum (
      'daily_comic',
      'serious',
      'fantasy_action',
      'healing_romance'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'diary_generation_status') then
    create type public.diary_generation_status as enum (
      'queued',
      'processing',
      'completed',
      'failed'
    );
  end if;
end
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key,
  username text not null unique,
  display_name text,
  bio text,
  avatar_url text,
  tendency_vector vector(1536),
  is_public boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profiles_username_check check (username ~ '^[a-zA-Z0-9_]{3,24}$')
);

create table public.personas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  input_mode text not null default 'prose',
  appearance_desc text not null default '',
  appearance_tags jsonb not null default '{}'::jsonb,
  emotion_prompts jsonb not null default '{}'::jsonb,
  expression_library jsonb not null default '{}'::jsonb,
  default_seed integer not null,
  default_art_style public.diary_art_style not null default 'anime_ld',
  default_genre public.diary_genre not null default 'daily_comic',
  image_url text,
  base_image_url text,
  is_primary boolean not null default false,
  is_public boolean not null default false,
  template_visibility text not null default 'private',
  generation_status public.diary_generation_status not null default 'queued',
  error_message text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint personas_name_length_check check (char_length(name) between 1 and 40),
  constraint personas_input_mode_check check (input_mode in ('prose', 'tags')),
  constraint personas_appearance_tags_object_check check (jsonb_typeof(appearance_tags) = 'object'),
  constraint personas_emotion_prompts_object_check check (jsonb_typeof(emotion_prompts) = 'object'),
  constraint personas_expression_library_object_check check (jsonb_typeof(expression_library) = 'object'),
  constraint personas_template_visibility_check check (template_visibility in ('private', 'public', 'unlisted')),
  constraint personas_seed_check check (default_seed between 1 and 2147483647)
);

create table public.diaries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  persona_id uuid references public.personas(id) on delete set null,
  title text,
  diary_at timestamptz,
  weather text not null default 'sunny',
  content text not null,
  summary text,
  emotion_tags text[] not null default '{}',
  keyword_tags text[] not null default '{}',
  art_style public.diary_art_style not null default 'comics_ld',
  art_sub_style text,
  genre public.diary_genre not null default 'daily_comic',
  genre_subtype text,
  webtoon_format text not null default 'card_slide',
  image_urls text[] not null default '{}',
  is_public boolean not null default false,
  generation_status public.diary_generation_status not null default 'queued',
  structured_result jsonb not null default '{}'::jsonb,
  generation_seed integer,
  retry_count integer not null default 0,
  error_message text,
  search_text text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint diaries_content_length_check check (char_length(content) between 1 and 10000),
  constraint diaries_weather_check check (weather in ('sunny', 'cloudy', 'rainy', 'snowy', 'foggy')),
  constraint diaries_webtoon_format_check check (webtoon_format in ('card_slide', 'image_focus', 'qa_slide', 'reaction_focus')),
  constraint diaries_retry_count_check check (retry_count between 0 and 5),
  constraint diaries_seed_check check (generation_seed is null or generation_seed between 1 and 2147483647)
);

create table public.diary_panels (
  id uuid primary key default gen_random_uuid(),
  diary_id uuid not null references public.diaries(id) on delete cascade,
  panel_order integer not null,
  panel_type text not null default 'scene',
  image_url text,
  dialogue text,
  prompt text,
  seed integer,
  generation_status public.diary_generation_status not null default 'queued',
  retry_count integer not null default 0,
  error_message text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (diary_id, panel_order),
  constraint diary_panels_order_check check (panel_order >= 0),
  constraint diary_panels_type_check check (panel_type in ('scene', 'question', 'answer', 'reaction', 'cover')),
  constraint diary_panels_dialogue_length_check check (dialogue is null or char_length(dialogue) <= 1000),
  constraint diary_panels_retry_count_check check (retry_count between 0 and 5),
  constraint diary_panels_seed_check check (seed is null or seed between 1 and 2147483647)
);

create table public.diary_likes (
  diary_id uuid not null references public.diaries(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (diary_id, user_id)
);

create table public.diary_comments (
  id uuid primary key default gen_random_uuid(),
  diary_id uuid not null references public.diaries(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  persona_id uuid references public.personas(id) on delete set null,
  content text not null,
  persona_script text,
  moderation_status text not null default 'pending',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint diary_comments_content_length_check check (char_length(content) between 1 and 500),
  constraint diary_comments_persona_script_length_check check (persona_script is null or char_length(persona_script) <= 1000),
  constraint diary_comments_moderation_status_check check (moderation_status in ('pending', 'approved', 'rejected'))
);

create table public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (follower_id, following_id),
  constraint follows_no_self_check check (follower_id <> following_id)
);

create table public.diary_albums (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text,
  color_hex text not null default '#86BFFF',
  is_public boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint diary_albums_title_length_check check (char_length(title) between 1 and 60)
);

create table public.diary_album_items (
  album_id uuid not null references public.diary_albums(id) on delete cascade,
  diary_id uuid not null references public.diaries(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (album_id, diary_id)
);

create unique index personas_primary_per_user_idx on public.personas (user_id) where is_primary = true;
create index profiles_username_trgm_idx on public.profiles using gin (username gin_trgm_ops);
create index personas_user_id_created_at_idx on public.personas (user_id, created_at desc);
create index personas_appearance_tags_gin_idx on public.personas using gin (appearance_tags);
create index diaries_public_created_at_idx on public.diaries (is_public, created_at desc);
create index diaries_user_id_created_at_idx on public.diaries (user_id, created_at desc);
create index diaries_search_text_trgm_idx on public.diaries using gin (search_text gin_trgm_ops);
create index diaries_keyword_tags_gin_idx on public.diaries using gin (keyword_tags);
create index diaries_emotion_tags_gin_idx on public.diaries using gin (emotion_tags);
create index diary_panels_diary_order_idx on public.diary_panels (diary_id, panel_order);
create index diary_comments_diary_created_at_idx on public.diary_comments (diary_id, created_at desc);
create index diary_albums_user_sort_idx on public.diary_albums (user_id, sort_order, created_at desc);

create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger personas_set_updated_at before update on public.personas for each row execute function public.set_updated_at();
create trigger diaries_set_updated_at before update on public.diaries for each row execute function public.set_updated_at();
create trigger diary_panels_set_updated_at before update on public.diary_panels for each row execute function public.set_updated_at();
create trigger diary_comments_set_updated_at before update on public.diary_comments for each row execute function public.set_updated_at();
create trigger diary_albums_set_updated_at before update on public.diary_albums for each row execute function public.set_updated_at();

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

create trigger diaries_set_search_text
before insert or update of title, content, keyword_tags, emotion_tags on public.diaries
for each row execute function public.set_diary_search_text();

alter table public.profiles enable row level security;
alter table public.personas enable row level security;
alter table public.diaries enable row level security;
alter table public.diary_panels enable row level security;
alter table public.diary_likes enable row level security;
alter table public.diary_comments enable row level security;
alter table public.follows enable row level security;
alter table public.diary_albums enable row level security;
alter table public.diary_album_items enable row level security;

create policy profiles_select_own_or_public on public.profiles for select using (auth.uid() = id or is_public = true);
create policy profiles_insert_own on public.profiles for insert with check (auth.uid() = id or auth.uid() is null);
create policy profiles_update_own on public.profiles for update using (auth.uid() = id or auth.uid() is null) with check (auth.uid() = id or auth.uid() is null);

create policy personas_select_own_or_public on public.personas for select using (auth.uid() = user_id or is_public = true);
create policy personas_insert_own on public.personas for insert with check (auth.uid() = user_id or auth.uid() is null);
create policy personas_update_own on public.personas for update using (auth.uid() = user_id or auth.uid() is null) with check (auth.uid() = user_id or auth.uid() is null);
create policy personas_delete_own on public.personas for delete using (auth.uid() = user_id);

create policy diaries_select_own_or_public on public.diaries for select using (auth.uid() = user_id or is_public = true);
create policy diaries_insert_own on public.diaries for insert with check (auth.uid() = user_id or auth.uid() is null);
create policy diaries_update_own on public.diaries for update using (auth.uid() = user_id or auth.uid() is null) with check (auth.uid() = user_id or auth.uid() is null);
create policy diaries_delete_own on public.diaries for delete using (auth.uid() = user_id);

create policy diary_panels_select_visible on public.diary_panels for select using (
  exists (
    select 1 from public.diaries d
    where d.id = diary_panels.diary_id
      and (d.user_id = auth.uid() or d.is_public = true)
  )
);
create policy diary_panels_insert_own on public.diary_panels for insert with check (
  exists (select 1 from public.diaries d where d.id = diary_panels.diary_id and d.user_id = auth.uid())
);
create policy diary_panels_update_own on public.diary_panels for update using (
  exists (select 1 from public.diaries d where d.id = diary_panels.diary_id and d.user_id = auth.uid())
) with check (
  exists (select 1 from public.diaries d where d.id = diary_panels.diary_id and d.user_id = auth.uid())
);

create policy diary_likes_select_all on public.diary_likes for select using (true);
create policy diary_likes_insert_own on public.diary_likes for insert with check (auth.uid() = user_id);
create policy diary_likes_delete_own on public.diary_likes for delete using (auth.uid() = user_id);

create policy diary_comments_select_visible on public.diary_comments for select using (
  exists (select 1 from public.diaries d where d.id = diary_comments.diary_id and (d.user_id = auth.uid() or d.is_public = true))
);
create policy diary_comments_insert_own on public.diary_comments for insert with check (
  auth.uid() = user_id
  and exists (
    select 1 from public.diaries d
    where d.id = diary_id
      and (d.user_id = auth.uid() or d.is_public = true)
  )
);
create policy diary_comments_update_own on public.diary_comments for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy diary_comments_delete_own on public.diary_comments for delete using (auth.uid() = user_id);

create policy follows_select_all on public.follows for select using (true);
create policy follows_insert_own on public.follows for insert with check (auth.uid() = follower_id);
create policy follows_delete_own on public.follows for delete using (auth.uid() = follower_id);

create policy diary_albums_select_own_or_public on public.diary_albums for select using (auth.uid() = user_id or is_public = true);
create policy diary_albums_insert_own on public.diary_albums for insert with check (auth.uid() = user_id or auth.uid() is null);
create policy diary_albums_update_own on public.diary_albums for update using (auth.uid() = user_id or auth.uid() is null) with check (auth.uid() = user_id or auth.uid() is null);
create policy diary_albums_delete_own on public.diary_albums for delete using (auth.uid() = user_id);

create policy diary_album_items_select_visible on public.diary_album_items for select using (
  exists (select 1 from public.diary_albums a where a.id = diary_album_items.album_id and (a.user_id = auth.uid() or a.is_public = true))
);
create policy diary_album_items_insert_own on public.diary_album_items for insert with check (
  (auth.uid() = user_id or auth.uid() is null)
  and exists (select 1 from public.diary_albums a where a.id = album_id and a.user_id = auth.uid())
  and exists (select 1 from public.diaries d where d.id = diary_id and d.user_id = auth.uid())
);
create policy diary_album_items_delete_own on public.diary_album_items for delete using (auth.uid() = user_id);

create or replace function public.toggle_diary_like(target_diary_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  liked boolean;
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  if not exists (
    select 1 from public.diaries d
    where d.id = target_diary_id
      and (d.user_id = auth.uid() or d.is_public = true)
  ) then
    raise exception '좋아요를 누를 수 없는 일기입니다.';
  end if;

  if exists (
    select 1 from public.diary_likes
    where diary_id = target_diary_id and user_id = auth.uid()
  ) then
    delete from public.diary_likes
    where diary_id = target_diary_id and user_id = auth.uid();
    liked := false;
  else
    insert into public.diary_likes (diary_id, user_id)
    values (target_diary_id, auth.uid());
    liked := true;
  end if;

  return liked;
end;
$$;

create or replace function public.request_diary_panel_retry(target_panel_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception '로그인이 필요합니다.';
  end if;

  update public.diary_panels p
  set generation_status = 'queued',
      retry_count = retry_count + 1,
      error_message = null,
      image_url = null,
      updated_at = timezone('utc', now())
  where p.id = target_panel_id
    and p.retry_count < 5
    and exists (
      select 1 from public.diaries d
      where d.id = p.diary_id and d.user_id = auth.uid()
    );

  if not found then
    raise exception '재시도할 수 없는 컷입니다.';
  end if;
end;
$$;

create or replace view public.social_feed_items
with (security_invoker = true)
as
select
  d.id,
  d.user_id,
  p.username,
  coalesce(p.display_name, p.username) as display_name,
  p.avatar_url,
  d.persona_id,
  pe.name as persona_name,
  d.title,
  d.content,
  d.summary,
  d.emotion_tags,
  d.keyword_tags,
  d.art_style,
  d.genre,
  d.webtoon_format,
  d.image_urls,
  d.image_urls[1] as first_image_url,
  d.search_text,
  count(distinct l.user_id)::integer as like_count,
  count(distinct c.id)::integer as comment_count,
  d.created_at
from public.diaries d
join public.profiles p on p.id = d.user_id
left join public.personas pe on pe.id = d.persona_id
left join public.diary_likes l on l.diary_id = d.id
left join public.diary_comments c on c.diary_id = d.id and c.moderation_status <> 'rejected'
where d.is_public = true
  and d.generation_status = 'completed'
group by d.id, p.id, pe.id;

create or replace view public.public_persona_templates
with (security_invoker = true)
as
select
  pe.id,
  pe.user_id,
  p.username,
  coalesce(p.display_name, p.username) as display_name,
  pe.name,
  pe.input_mode,
  pe.appearance_desc,
  pe.appearance_tags,
  pe.emotion_prompts,
  pe.expression_library,
  pe.default_seed,
  pe.default_art_style,
  pe.default_genre,
  pe.image_url,
  pe.base_image_url,
  pe.template_visibility,
  pe.created_at,
  pe.updated_at
from public.personas pe
join public.profiles p on p.id = pe.user_id
where pe.is_public = true
  and pe.template_visibility = 'public';

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('diary-assets', 'diary-assets', true, 10485760, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy diary_assets_public_read on storage.objects
  for select using (bucket_id = 'diary-assets');

create policy diary_assets_owner_insert on storage.objects
  for insert with check (
    bucket_id = 'diary-assets'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy diary_assets_owner_update on storage.objects
  for update using (
    bucket_id = 'diary-assets'
    and auth.uid()::text = (storage.foldername(name))[1]
  ) with check (
    bucket_id = 'diary-assets'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy diary_assets_owner_delete on storage.objects
  for delete using (
    bucket_id = 'diary-assets'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

comment on table public.personas is '사용자가 만든 캐릭터와 AI 이미지 생성 기준을 저장합니다.';
comment on table public.diaries is '원문 일기, 선택 태그, AI 분석 결과, 공개 피드 상태를 저장합니다.';
comment on table public.diary_panels is '웹툰 컷 단위 이미지, 대사, 프롬프트, 재시도 상태를 저장합니다.';
