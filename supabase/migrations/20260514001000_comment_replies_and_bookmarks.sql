-- 댓글의 대댓글 구조와 작품 북마크 기능을 추가합니다.
alter table public.diary_comments
  add column if not exists parent_comment_id uuid references public.diary_comments(id) on delete cascade;

create index if not exists diary_comments_parent_created_at_idx
  on public.diary_comments (parent_comment_id, created_at);

create table if not exists public.diary_bookmarks (
  diary_id uuid not null references public.diaries(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (diary_id, user_id)
);

alter table public.diary_bookmarks enable row level security;

grant select, insert, delete on public.diary_bookmarks to anon, authenticated;

drop policy if exists diary_bookmarks_select_own on public.diary_bookmarks;
drop policy if exists diary_bookmarks_insert_own on public.diary_bookmarks;
drop policy if exists diary_bookmarks_delete_own on public.diary_bookmarks;

create policy diary_bookmarks_select_own on public.diary_bookmarks
  for select using (auth.uid() = user_id);

create policy diary_bookmarks_insert_own on public.diary_bookmarks
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.diaries d
      where d.id = diary_bookmarks.diary_id
        and (d.user_id = auth.uid() or d.is_public = true)
    )
  );

create policy diary_bookmarks_delete_own on public.diary_bookmarks
  for delete using (auth.uid() = user_id);

-- PostgREST 스키마 캐시를 즉시 새로고침합니다.
select pg_notify('pgrst', 'reload schema');
