create table if not exists public.diary_style_templates (
  id text primary key,
  name text not null,
  description text,
  art_style public.diary_art_style not null default 'comics_ld',
  art_sub_style text,
  prompt text not null,
  negative_prompt text,
  preview_image_url text,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint diary_style_templates_name_check check (char_length(name) between 1 and 60),
  constraint diary_style_templates_prompt_check check (char_length(prompt) between 20 and 4000)
);

create trigger diary_style_templates_set_updated_at
before update on public.diary_style_templates
for each row execute function public.set_updated_at();

alter table public.diaries
add column if not exists style_template_id text references public.diary_style_templates(id) on delete set null,
add column if not exists style_template_prompt text;

alter table public.diary_style_templates enable row level security;

drop policy if exists diary_style_templates_select_active on public.diary_style_templates;
create policy diary_style_templates_select_active
  on public.diary_style_templates
  for select
  using (is_active = true);

insert into public.diary_style_templates (
  id, name, description, art_style, art_sub_style, prompt, negative_prompt, sort_order
) values
(
  'semi_realistic_daily',
  '극화형 일기',
  '표정과 장면을 섬세하게 살리는 LD',
  'comics_ld',
  '극화형 (Semi-Realistic)',
  'Semi-realistic Korean diary webtoon style. Believable stylized anatomy, firm contour lines, expressive face planes, clear hands, cinematic daily lighting, dramatic but readable single vertical card panel. Keep the diary event visible, never a generic portrait.',
  'flat anime, chibi, 3D render, photorealistic live action, western superhero comic',
  10
),
(
  'graphic_anime_daily',
  '애니형 그래픽',
  '깔끔한 선과 셀 셰이딩 중심',
  'anime_ld',
  '애니형 (Graphic)',
  'Graphic anime diary webtoon style. Clean stylized linework, crisp cel shading, expressive animated eyes, smooth hair clumps, controlled color blocks, clear emotional acting, readable vertical Korean diary panel.',
  'semi-realistic gritty ink, casual cartoon SD, 3D render, photorealistic portrait',
  20
),
(
  'casual_cartoon_daily',
  '캐주얼 만화',
  '웃긴 표정과 과장된 액션에 적합',
  'comics_sd',
  '캐주얼 만화형 (Cartoon)',
  'Casual cartoon diary style. Simplified cute proportions, bouncy shapes, exaggerated comedy expressions, bright flat color blocks, sweat drops, motion marks, playful daily gag timing, readable props and action.',
  'realistic anatomy, romance webtoon face, 3D render, photorealistic portrait',
  30
),
(
  'simple_character_daily',
  '심플 캐릭터',
  '아이콘처럼 읽히는 단순한 SD',
  'simple_2d',
  '캐릭터형 (Simple Character)',
  'Simple character diary style. Mascot-like 2D silhouette, minimal facial features, rounded body, clean outlines, flat pastel fills, readable props, calm negative space, cute diary app character mood.',
  'detailed anime face, semi-realistic portrait, 3D render, complex painting',
  40
),
(
  'soft_3d_daily',
  '소프트 3D',
  '입체감과 빛이 보이는 3D',
  'realistic_3d',
  '입체 렌더링 (3D Style)',
  'Stylized 3D animated diary scene. Volumetric rounded character, sculpted hair, soft materials, ambient occlusion, cast shadows, cozy miniature daily environment, cinematic but cute lighting. The final image must look 3D, not flat 2D line art.',
  'flat anime, 2D illustration, line art, cel shading, manga, comic ink, photorealistic human',
  50
)
on conflict (id) do update set
  name = excluded.name,
  description = excluded.description,
  art_style = excluded.art_style,
  art_sub_style = excluded.art_sub_style,
  prompt = excluded.prompt,
  negative_prompt = excluded.negative_prompt,
  sort_order = excluded.sort_order,
  is_active = true;
