create table if not exists public.persona_drafts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null default '나의 캐릭터',
  appearance_desc text not null default '',
  input_mode text not null default 'prose',
  appearance_tags jsonb not null default '{"tags":[]}'::jsonb,
  template_visibility text not null default 'public',
  reference_image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint persona_drafts_one_per_user unique (user_id)
);

alter table public.persona_drafts enable row level security;

drop policy if exists "persona_drafts_select_own" on public.persona_drafts;
create policy "persona_drafts_select_own"
  on public.persona_drafts
  for select
  using (auth.uid() = user_id);

drop policy if exists "persona_drafts_insert_own" on public.persona_drafts;
create policy "persona_drafts_insert_own"
  on public.persona_drafts
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "persona_drafts_update_own" on public.persona_drafts;
create policy "persona_drafts_update_own"
  on public.persona_drafts
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "persona_drafts_delete_own" on public.persona_drafts;
create policy "persona_drafts_delete_own"
  on public.persona_drafts
  for delete
  using (auth.uid() = user_id);
