select
  id,
  user_id,
  name,
  generation_status,
  left(coalesce(error_message, ''), 220) as error_preview,
  image_url is not null as has_image,
  created_at
from public.personas
order by created_at desc
limit 10;
