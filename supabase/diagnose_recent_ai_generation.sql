select
  'personas' as source,
  id,
  name as title,
  generation_status,
  error_message,
  image_url,
  base_image_url,
  created_at,
  updated_at
from public.personas
order by created_at desc
limit 8;

select
  'diaries' as source,
  id,
  coalesce(title, 'untitled') as title,
  generation_status,
  error_message,
  image_urls,
  created_at,
  updated_at
from public.diaries
order by created_at desc
limit 8;

select
  'diary_panels' as source,
  id,
  diary_id,
  panel_order,
  generation_status,
  error_message,
  image_url,
  created_at,
  updated_at
from public.diary_panels
order by created_at desc
limit 12;
