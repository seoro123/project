select 'profiles' as table_name, count(*)::int as row_count from public.profiles
union all
select 'personas', count(*)::int from public.personas
union all
select 'diaries', count(*)::int from public.diaries
union all
select 'diary_panels', count(*)::int from public.diary_panels
union all
select 'diary_likes', count(*)::int from public.diary_likes
union all
select 'diary_comments', count(*)::int from public.diary_comments
union all
select 'follows', count(*)::int from public.follows
union all
select 'diary_albums', count(*)::int from public.diary_albums
union all
select 'diary_album_items', count(*)::int from public.diary_album_items
order by table_name;
