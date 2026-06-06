-- 일기와 캐릭터에 "팔로워 전용 공개" 범위를 추가합니다.

alter table public.diaries
add column if not exists visibility text not null default 'private';

update public.diaries
set visibility = case
  when is_public = true then 'public'
  else coalesce(nullif(visibility, ''), 'private')
end;

alter table public.diaries
drop constraint if exists diaries_visibility_check;

alter table public.diaries
add constraint diaries_visibility_check
check (visibility in ('private', 'followers', 'public'));

alter table public.personas
drop constraint if exists personas_template_visibility_check;

alter table public.personas
add constraint personas_template_visibility_check
check (template_visibility in ('private', 'followers', 'public', 'unlisted'));

create or replace function public.can_view_followers_content(owner_id uuid)
returns boolean
language sql
stable
as $$
  select auth.uid() = owner_id
    or exists (
      select 1
      from public.follows f
      where f.follower_id = auth.uid()
        and f.following_id = owner_id
    );
$$;

drop policy if exists personas_select_own_or_public on public.personas;
create policy personas_select_visible on public.personas
for select using (
  auth.uid() = user_id
  or template_visibility = 'public'
  or is_public = true
  or (
    template_visibility = 'followers'
    and public.can_view_followers_content(user_id)
  )
);

drop policy if exists diaries_select_own_or_public on public.diaries;
create policy diaries_select_visible on public.diaries
for select using (
  auth.uid() = user_id
  or visibility = 'public'
  or is_public = true
  or (
    visibility = 'followers'
    and public.can_view_followers_content(user_id)
  )
);

drop policy if exists diary_panels_select_visible on public.diary_panels;
create policy diary_panels_select_visible on public.diary_panels
for select using (
  exists (
    select 1
    from public.diaries d
    where d.id = diary_panels.diary_id
      and (
        d.user_id = auth.uid()
        or d.visibility = 'public'
        or d.is_public = true
        or (
          d.visibility = 'followers'
          and public.can_view_followers_content(d.user_id)
        )
      )
  )
);

drop policy if exists diary_comments_select_visible on public.diary_comments;
create policy diary_comments_select_visible on public.diary_comments
for select using (
  exists (
    select 1
    from public.diaries d
    where d.id = diary_comments.diary_id
      and (
        d.user_id = auth.uid()
        or d.visibility = 'public'
        or d.is_public = true
        or (
          d.visibility = 'followers'
          and public.can_view_followers_content(d.user_id)
        )
      )
  )
);

drop policy if exists diary_likes_select_visible on public.diary_likes;
create policy diary_likes_select_visible on public.diary_likes
for select using (
  exists (
    select 1
    from public.diaries d
    where d.id = diary_likes.diary_id
      and (
        d.user_id = auth.uid()
        or d.visibility = 'public'
        or d.is_public = true
        or (
          d.visibility = 'followers'
          and public.can_view_followers_content(d.user_id)
        )
      )
  )
);

drop view if exists public.social_feed_items;
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
  d.visibility,
  count(distinct l.user_id)::integer as like_count,
  count(distinct c.id)::integer as comment_count,
  d.created_at
from public.diaries d
join public.profiles p on p.id = d.user_id
left join public.personas pe on pe.id = d.persona_id
left join public.diary_likes l on l.diary_id = d.id
left join public.diary_comments c on c.diary_id = d.id and c.moderation_status <> 'rejected'
where d.generation_status = 'completed'
  and (
    d.visibility = 'public'
    or d.is_public = true
    or (
      d.visibility = 'followers'
      and public.can_view_followers_content(d.user_id)
    )
  )
group by d.id, p.id, pe.id;

drop view if exists public.public_persona_templates;
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
where pe.template_visibility = 'public'
  or pe.is_public = true
  or (
    pe.template_visibility = 'followers'
    and public.can_view_followers_content(pe.user_id)
  );

select pg_notify('pgrst', 'reload schema');
