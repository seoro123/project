select
  d.created_at,
  d.title,
  d.webtoon_format,
  d.art_style,
  d.art_sub_style,
  d.genre,
  d.genre_subtype,
  d.keyword_tags,
  p.panel_order,
  p.panel_type,
  p.dialogue,
  left(p.prompt, 1200) as prompt_preview
from public.diaries d
left join public.diary_panels p on p.diary_id = d.id
order by d.created_at desc, p.panel_order asc
limit 6;