alter table public.diaries
  add column if not exists caption text;

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
  d.caption,
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

select pg_notify('pgrst', 'reload schema');
