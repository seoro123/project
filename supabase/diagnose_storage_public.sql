select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'diary-assets';

select name, bucket_id, owner, created_at, updated_at
from storage.objects
where bucket_id = 'diary-assets'
order by created_at desc
limit 8;
