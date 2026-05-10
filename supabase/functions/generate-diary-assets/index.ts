import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers':
    'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'content-type': 'application/json',
    },
  });
}

type GenerateDiaryAssetsPayload = {
  diary_id: string;
  panel_id?: string;
  mode?: 'retry_panel' | 'full';
  force_regenerate?: boolean;
};

type DiaryRow = {
  id: string;
  user_id: string;
  persona_id: string | null;
  title: string | null;
  content: string;
  weather: string;
  webtoon_format: string;
  art_style: string;
  art_sub_style: string | null;
  genre: string;
  genre_subtype: string | null;
  keyword_tags: string[];
  generation_status: string;
  retry_count: number;
};

type PersonaRow = {
  id: string;
  name: string | null;
  appearance_desc: string;
  appearance_tags: Record<string, unknown> | null;
  expression_library: Record<string, string>;
  default_seed: number;
  base_image_url: string | null;
  default_art_style: string | null;
  default_genre: string | null;
};

type StructuredPanel = {
  panel_type: 'scene' | 'question' | 'answer' | 'reaction' | 'cover';
  scene_title: string;
  dialogue: string;
  location: string;
  character_action: string;
  facial_expression: string;
  body_pose: string;
  gaze_direction: string;
  key_props: string[];
  camera_shot: string;
  speech_bubble_position: string;
  speech_bubble_shape: string;
  speech_bubble_intent: string;
  comic_effects: string[];
  panel_layout_notes: string;
  image_prompt: string;
  emotion: string;
};

type BubblePlacement = {
  alignment: string;
  margin: string;
};

type StructuredDiary = {
  summary: string;
  emotion_tags: string[];
  panels: StructuredPanel[];
};

type ImageGenerationContext = {
  provider: 'stability' | 'gemini';
  stabilityApiKey?: string;
  geminiApiKey?: string;
};

const diaryPromptSchema = {
  name: 'diary_card_slide_prompt_result',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['summary', 'emotion_tags', 'panels'],
    properties: {
      summary: { type: 'string' },
      emotion_tags: {
        type: 'array',
        minItems: 1,
        maxItems: 8,
        items: { type: 'string' },
      },
      panels: {
        type: 'array',
        minItems: 1,
        items: {
          type: 'object',
          additionalProperties: false,
          required: [
            'panel_type',
            'scene_title',
            'dialogue',
            'location',
            'character_action',
            'facial_expression',
            'body_pose',
            'gaze_direction',
            'key_props',
            'camera_shot',
            'speech_bubble_position',
            'speech_bubble_shape',
            'speech_bubble_intent',
            'comic_effects',
            'panel_layout_notes',
            'image_prompt',
            'emotion',
          ],
          properties: {
            panel_type: {
              type: 'string',
              enum: ['scene', 'question', 'answer', 'reaction', 'cover'],
            },
            scene_title: {
              type: 'string',
              description:
                'Short Korean title for this card, based on a concrete story beat from the diary event.',
            },
            dialogue: {
              type: 'string',
              minLength: 1,
              maxLength: 180,
              description:
                'OpenAI-generated Korean dialogue or inner monologue for this webtoon cut. Write natural Korean like a character actually speaking in a diary webtoon, not a report summary. Usually 1 sentence, sometimes 2 short sentences, around 8-34 Korean characters. It should react to the visible action and emotion in this exact cut. Use casual spoken Korean, tiny jokes, hesitation, surprise, or self-talk when appropriate. Do not end with artificial ellipsis unless the emotion truly requires hesitation.',
            },
            location: {
              type: 'string',
              description:
                'Concrete visible place for the panel. Must come from the diary, tags, weather, or genre.',
            },
            character_action: {
              type: 'string',
              description:
                'Concrete visible action the persona performs in the panel. Must involve the location, props, another person, device, food, school/work object, weather, or genre element. Never just standing, posing, looking at camera, or monologuing.',
            },
            facial_expression: {
              type: 'string',
              description:
                'Exact visible expression for the persona, such as wide anxious eyes, tiny proud smile, teary embarrassed face, angry puffed cheeks.',
            },
            body_pose: {
              type: 'string',
              description:
                'Exact body pose and hand/shoulder gesture. Must support the diary event and emotion.',
            },
            gaze_direction: {
              type: 'string',
              description:
                'Where the character looks: at laptop, at food, downward, side glance, toward the main prop, etc. Do not require a speech bubble in the generated image.',
            },
            key_props: {
              type: 'array',
              minItems: 1,
              maxItems: 6,
              items: { type: 'string' },
              description:
                'Visible objects, symbols, weather elements, or tag anchors that must appear.',
            },
            camera_shot: {
              type: 'string',
              description:
                'Webtoon panel camera/composition, such as medium shot, low angle, wide shot, chibi reaction close-up.',
            },
            speech_bubble_position: {
              type: 'string',
              enum: [
                'upper_left',
                'upper_right',
                'center_top',
                'left_side',
                'right_side',
                'bottom_left',
                'bottom_right',
                'none',
              ],
              description:
                'Preferred dialogue bubble placement for post-generation compositing.',
            },
            speech_bubble_shape: {
              type: 'string',
              enum: [
                'rounded_speech_bubble',
                'thought_bubble',
                'reaction_caption_box',
                'small_shout_bubble',
                'none',
              ],
              description:
                'Visual bubble shape for post-generation compositing.',
            },
            speech_bubble_intent: {
              type: 'string',
              description:
                'English-only meaning of the Korean dialogue, for composition. Do not include the exact Korean dialogue.',
            },
            comic_effects: {
              type: 'array',
              minItems: 1,
              maxItems: 6,
              items: { type: 'string' },
              description:
                'Comic-only effects such as speed lines, sweat drop, impact burst, screentone, sparkle, soft bubbles.',
            },
            panel_layout_notes: {
              type: 'string',
              description:
                'English-only layout instruction: where character, props, motion, and safe empty space for a later dialogue bubble should sit inside the vertical card.',
            },
            image_prompt: {
              type: 'string',
              minLength: 700,
              description:
                'English-only visual prompt for the image generator. Write a detailed 700-1200 character art-direction paragraph, not keywords. It must include style lock, character identity, diary scene, action, pose, expression, props, location, weather/genre mood, panel framing, lighting, comic effects, and clean reserved space for a later app-drawn speech bubble. The image model must not draw text or speech bubbles. It must describe a finished webtoon scene cut with event/action as the subject, not a solo character portrait or monologue image.',
            },
            emotion: { type: 'string' },
          },
        },
      },
    },
  },
  strict: true,
};

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const openAiApiKey = Deno.env.get('OPENAI_API_KEY');
  const stabilityApiKey = Deno.env.get('STABILITY_API_KEY');
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  const imageProvider = (Deno.env.get('IMAGE_PROVIDER') ?? 'stability').toLowerCase();
  const openAiPromptDisabled =
    Deno.env.get('OPENAI_PROMPT_DISABLED')?.toLowerCase() === 'true';

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: 'Missing Supabase environment variables.' }, 500);
  }

  if (!openAiApiKey && imageProvider !== 'gemini') {
    return jsonResponse({ error: 'Missing OPENAI_API_KEY.' }, 500);
  }

  if (imageProvider === 'gemini' && !geminiApiKey) {
    return jsonResponse({ error: 'Missing GEMINI_API_KEY.' }, 500);
  }

  if (imageProvider !== 'gemini' && !stabilityApiKey) {
    return jsonResponse({ error: 'Missing STABILITY_API_KEY.' }, 500);
  }

  const authHeader = request.headers.get('authorization') ?? '';
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return jsonResponse({ error: 'Login is required.' }, 401);
  }

  const payload = await safeJson<GenerateDiaryAssetsPayload>(request);
  if (!payload?.diary_id) {
    return jsonResponse({ error: 'diary_id is required.' }, 400);
  }

  const { data: diary, error: diaryError } = await adminClient
    .from('diaries')
    .select('*')
    .eq('id', payload.diary_id)
    .eq('user_id', userData.user.id)
    .single<DiaryRow>();

  if (diaryError || !diary) {
    return jsonResponse({ error: 'Diary was not found.' }, 404);
  }

  if (
    diary.generation_status === 'completed' &&
    payload.force_regenerate !== true &&
    payload.mode !== 'retry_panel'
  ) {
    return jsonResponse({ message: 'Diary assets already exist.' }, 200);
  }

  if (diary.retry_count >= 5 && payload.force_regenerate !== true) {
    return jsonResponse({ error: 'Diary retry limit exceeded.' }, 409);
  }

  try {
    if (payload.mode === 'retry_panel' && payload.panel_id) {
      await retryPanel(
        adminClient,
        {
          provider: imageProvider === 'gemini' ? 'gemini' : 'stability',
          stabilityApiKey,
          geminiApiKey,
        },
        diary,
        payload.panel_id,
      );
      return jsonResponse({ diary_id: diary.id, panel_id: payload.panel_id }, 200);
    }

    await adminClient
      .from('diaries')
      .update({
        generation_status: 'processing',
        error_message: null,
        retry_count: diary.retry_count + 1,
      })
      .eq('id', diary.id);

    const persona = await loadPersona(adminClient, diary);
    const structured = await writeDiaryPromptsWithFallback(
      openAiPromptDisabled ? undefined : openAiApiKey,
      diary,
      persona,
    );
    const imageUrls = await createPanels(
      adminClient,
      {
        provider: imageProvider === 'gemini' ? 'gemini' : 'stability',
        stabilityApiKey,
        geminiApiKey,
      },
      diary,
      persona,
      structured,
    );

    const { error: updateError } = await adminClient
      .from('diaries')
      .update({
        summary: structured.summary,
        emotion_tags: structured.emotion_tags,
        structured_result: {
          ...structured,
          selected_tags_contract: buildSelectedTagContract(diary, persona),
        },
        image_urls: imageUrls,
        generation_seed: persona?.default_seed ?? stableSeed(diary.id),
        generation_status: 'completed',
        error_message: null,
      })
      .eq('id', diary.id);

    if (updateError) {
      throw updateError;
    }

    return jsonResponse({ diary_id: diary.id, panel_count: imageUrls.length }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    await adminClient
      .from('diaries')
      .update({ generation_status: 'failed', error_message: message })
      .eq('id', diary.id);

    return jsonResponse({ error: message }, 500);
  }
});

async function loadPersona(
  adminClient: ReturnType<typeof createClient>,
  diary: DiaryRow,
): Promise<PersonaRow | null> {
  if (!diary.persona_id) {
    return null;
  }

  const { data, error } = await adminClient
    .from('personas')
    .select(
      'id, name, appearance_desc, appearance_tags, expression_library, default_seed, base_image_url, default_art_style, default_genre',
    )
    .eq('id', diary.persona_id)
    .eq('user_id', diary.user_id)
    .single<PersonaRow>();

  if (error) {
    throw new Error(`Persona lookup failed: ${error.message}`);
  }

  return data;
}

async function writeDiaryPromptsWithFallback(
  apiKey: string | undefined,
  diary: DiaryRow,
  persona: PersonaRow | null,
): Promise<StructuredDiary> {
  if (!apiKey) {
    return fallbackStructuredDiary(diary, persona);
  }

  try {
    return await writeDiaryPrompts(apiKey, diary, persona);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (
      message.includes('insufficient_quota') ||
      message.toLowerCase().includes('quota') ||
      message.toLowerCase().includes('billing')
    ) {
      return fallbackStructuredDiary(diary, persona);
    }
    throw error;
  }
}

function fallbackStructuredDiary(
  diary: DiaryRow,
  persona: PersonaRow | null,
): StructuredDiary {
  const title = diary.title?.trim() || '오늘의 일기';
  const tags = diary.keyword_tags.length
    ? diary.keyword_tags.map((tag) => `#${tag}`).join(' ')
    : '#일기';
  const personaBrief = persona?.appearance_desc || 'the selected diary character';
  const style = artStylePrompt(diary.art_style, diary.art_sub_style);
  const genre = genrePrompt(diary.genre);
  const weather = weatherPrompt(diary.weather);
  const content = sanitizeShortText(diary.content).slice(0, 220);
  const location = inferFallbackLocation(diary);
  const props = inferFallbackProps(diary);

  const panels: StructuredPanel[] = [
    {
      panel_type: 'cover',
      scene_title: title,
      dialogue: '오늘도 시작!',
      location,
      character_action: `the character enters the diary scene and notices ${props[0]}`,
      facial_expression: 'curious eyes and small surprised mouth',
      body_pose: 'three-quarter body pose, one hand holding or pointing at the main prop',
      gaze_direction: `looking at ${props[0]}`,
      key_props: props,
      camera_shot: 'vertical medium-wide establishing shot',
      speech_bubble_position: 'center_top',
      speech_bubble_shape: 'rounded_speech_bubble',
      speech_bubble_intent: 'introducing today diary event',
      comic_effects: ['small sparkle', 'soft motion line'],
      panel_layout_notes:
        'character placed slightly off-center, environment and props clearly visible, leave upper center safe empty space for a later dialogue bubble',
      image_prompt:
        `${style}. ${genre}. ${weather}. Finished Korean diary webtoon card panel, not a portrait. Show ${personaBrief} inside ${location}, interacting with ${props.join(', ')}. The scene establishes the diary event from: ${content}. Use vertical mobile card composition, visible panel border, readable action, and leave one clean upper-center open area for a later app-drawn speech bubble. Do not draw any speech bubble, text, hashtag, label, or caption. Pastel webtoon colors, clear background, body and hands visible. ${tags}`,
      emotion: 'curious',
    },
    {
      panel_type: 'scene',
      scene_title: '상황 발생',
      dialogue: '어렵다...',
      location,
      character_action: `the character struggles with ${props[1] ?? props[0]} while the diary situation changes`,
      facial_expression: 'worried eyes, tiny sweat drop, tense eyebrows',
      body_pose: 'leaning forward with both hands actively using the prop',
      gaze_direction: `focused on ${props[1] ?? props[0]}`,
      key_props: props,
      camera_shot: 'over-the-shoulder action shot',
      speech_bubble_position: 'bottom_right',
      speech_bubble_shape: 'rounded_speech_bubble',
      speech_bubble_intent: 'the situation feels harder than expected',
      comic_effects: ['sweat drop', 'jitter line', 'small impact mark'],
      panel_layout_notes:
        'show the action and prop first, character face second, leave safe empty space away from hands and face',
      image_prompt:
        `${style}. ${genre}. ${weather}. A real webtoon scene cut showing the diary problem/action, not a talking head. ${personaBrief} is actively doing the event from: ${content}. Include ${props.join(', ')}, visible hands, body movement, environmental context, sweat drop and motion marks. Vertical card-slide panel with clear single-panel frame and one clean bottom-right open area for later app-drawn dialogue. Do not draw any speech bubble, text, hashtag, label, or caption. ${tags}`,
      emotion: 'flustered',
    },
    {
      panel_type: 'reaction',
      scene_title: '마무리',
      dialogue: '기록 완료!',
      location,
      character_action: `the character reacts to the result and puts ${props[0]} down with relief`,
      facial_expression: 'relieved smile with slightly tired eyes',
      body_pose: 'relaxed shoulders, one hand making a small victory gesture',
      gaze_direction: 'looking at the completed result',
      key_props: props,
      camera_shot: 'warm medium shot with environment visible',
      speech_bubble_position: 'center_top',
      speech_bubble_shape: 'rounded_speech_bubble',
      speech_bubble_intent: 'closing the diary with relief',
      comic_effects: ['sparkle', 'soft glow', 'small celebratory mark'],
      panel_layout_notes:
        'make a clear payoff panel with props and result visible, leave safe empty space near top center',
      image_prompt:
        `${style}. ${genre}. ${weather}. Final Korean diary webtoon card panel showing payoff and emotion, not a portrait. ${personaBrief} reacts to finishing the event from: ${content}, with ${props.join(', ')} visible in the scene. Use cozy lighting, small sparkle effects, clear body pose, single vertical panel border, and one clean top open area for later app-drawn dialogue. Do not draw any speech bubble, text, hashtag, label, or caption. ${tags}`,
      emotion: 'relieved',
    },
  ];

  return normalizeStructuredDiary(
    {
      summary: `${title} - ${content}`,
      emotion_tags: diary.keyword_tags.length ? diary.keyword_tags : ['일기'],
      panels,
    },
    diary,
  );
}

function inferFallbackLocation(diary: DiaryRow): string {
  const text = `${diary.title ?? ''} ${diary.content} ${diary.keyword_tags.join(' ')}`;
  if (/학교|수업|시험|공부|교실/u.test(text)) {
    return 'a Korean classroom or study desk';
  }
  if (/카페|커피|디저트/u.test(text)) {
    return 'a cozy cafe table';
  }
  if (/집|방|침대/u.test(text)) {
    return 'a cozy bedroom or desk at home';
  }
  if (/비|눈|날씨|밖|거리/u.test(text)) {
    return 'a street or window-side scene with visible weather';
  }
  return 'a cozy diary scene with a desk and everyday background';
}

function inferFallbackProps(diary: DiaryRow): string[] {
  const text = `${diary.title ?? ''} ${diary.content} ${diary.keyword_tags.join(' ')}`;
  const props = new Set<string>();
  if (/공부|시험|개발|코딩|과제|일/u.test(text)) {
    props.add('laptop');
    props.add('notebook');
  }
  if (/밥|음식|카페|커피|디저트/u.test(text)) {
    props.add('food plate');
    props.add('drink cup');
  }
  if (/친구|대화|문자|연락/u.test(text)) {
    props.add('smartphone');
    props.add('chat notification');
  }
  if (/비|눈|맑음|흐림|안개/u.test(text)) {
    props.add('window weather');
  }
  diary.keyword_tags.slice(0, 3).forEach((tag) => props.add(tag));
  if (props.size === 0) {
    props.add('diary notebook');
    props.add('smartphone');
    props.add('desk items');
  }
  return Array.from(props).slice(0, 6);
}

async function writeDiaryPrompts(
  apiKey: string,
  diary: DiaryRow,
  persona: PersonaRow | null,
): Promise<StructuredDiary> {
  const tagContract = buildSelectedTagContract(diary, persona);
  const response = await fetch('https://api.openai.com/v1/responses', {
    method: 'POST',
    signal: AbortSignal.timeout(45_000),
    headers: {
      authorization: `Bearer ${apiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: Deno.env.get('OPENAI_PROMPT_MODEL') ?? 'gpt-4o',
      input: [
        {
      role: 'system',
      content:
        'You are a Korean webtoon storyboard writer and a prompt director for Nano Banana / Gemini image generation. OpenAI must first analyze the diary, selected tags, persona, art style, genre, weather, and webtoon format, then write a complete Nano Banana-ready prompt for each card-slide cut. The image generator must create a finished illustrated Korean diary webtoon scene cut without any rendered text or speech bubble; the Flutter app will draw the final Korean speech bubble after generation. Convert the diary into as many separate card-slide panels as the diary naturally needs. Do not force a 3 to 5 cut limit; a short diary may be 1 to 3 cuts, and a longer diary may use more cuts when the story needs them. Return only JSON that follows the schema. Every panel must contain a concrete location, visible event action, exact facial expression, exact body pose, props, camera shot, preferred bubble placement, layout notes, comic effects, and natural Korean dialogue. The character is an actor inside a scene; the diary event is the subject. dialogue must sound like a real Korean diary webtoon line: usually one sentence, sometimes two short sentences, specific to the scene and emotion, not a generic one-word reaction. speech_bubble_intent must be English-only and summarize the meaning/emotion of the Korean dialogue. image_prompt must be English-only, 700-1200 characters, written as a complete detailed art-direction paragraph for a finished webtoon cut with reserved open space for a later app-drawn bubble. The selected_tags_contract is a hard visual direction from the user, not optional metadata. Each image_prompt must describe exactly one finished webtoon scene cut, never a solo portrait, never a page layout, never a grid, never a character sheet.',
        },
        {
          role: 'user',
          content: JSON.stringify({
            target_output: 'card_slide_only',
            title: diary.title,
            diary: diary.content,
            weather: diary.weather,
            requested_webtoon_format: diary.webtoon_format,
            art_style: diary.art_style,
            art_sub_style: diary.art_sub_style,
            genre: diary.genre,
            genre_subtype: diary.genre_subtype,
            keyword_tags: diary.keyword_tags,
            persona_appearance: persona?.appearance_desc,
            persona_appearance_tags: persona?.appearance_tags,
            expression_library: persona?.expression_library,
            selected_tags_contract: tagContract,
            prompt_priority: [
              '1. the diary content and keyword tags decide the actual scene, action, props, location, and emotion',
              '2. selected genre and genre subtype decide the direction and mood',
              '3. selected webtoon format decides panel composition',
              '4. selected art style and art sub-style decide rendering style',
              '5. persona appearance is only the actor design inside the diary scene',
              '6. weather/date mood must be visible when relevant',
            ],
            rules: [
              'choose the number of vertical card panels from the diary content; do not force a fixed 3 to 5 cut limit',
              'make enough panels to show setup, action/conflict, reaction/change, and payoff when those beats exist; very short diary content may use fewer cuts',
              'never make a panel where the character only faces the camera and talks; no solo talking-head monologue panels',
              'every panel must show the character physically interacting with something: laptop, phone, food, door, desk, weather, friend, school/work object, fantasy prop, or another scene element',
              'at least half of the image_prompt must describe the environment, props, action, camera, and comic effects, not the face',
              'if the diary is introspective, externalize it visually with symbolic props, changing weather, messy desk, calendar, mirror, phone notification, RPG quest UI-like prop, or other story device',
              'compose each panel like an actual webtoon cut first: background, actor, action, props, effects, and one reserved open area for a later app-drawn speech bubble',
              'OpenAI should choose the emotional intent and write natural Korean dialogue for the Flutter app to render later',
              'the image generator must render no speech bubble and no text; no captions, hashtags, labels, pseudo-text, logos, UI badges, or any letters',
              'avoid random pseudo-text, unreadable glyphs, logos, watermarks, hashtags, labels, captions, or extra lettering in the generated image',
              'choose a natural speech_bubble_position for the later app-drawn bubble unless the panel is image_focus or would look cleaner with none',
              'speech_bubble_position must avoid the face, hands, key props, or main action when the app overlays the bubble',
              'speech_bubble_intent must describe the meaning of the dialogue in English, not copy the Korean text',
              'facial_expression must be specific enough for an illustrator, not a vague emotion word',
              'body_pose must include shoulders/hands/body direction so the image does not become a portrait',
              'preserve the same character design across every panel, but never replace the diary scene with a generic character portrait',
              'OpenAI writes the exact final Korean line to render. dialogue should be 10-38 Korean characters when possible, with natural spacing and punctuation',
              'dialogue should feel spoken, not narrated: the character should react to what is happening in the panel rather than explain the whole diary',
              'dialogue should contain only the bubble text, without speaker labels like "나:" or quotation marks',
              'do not end dialogue with ... unless the character is genuinely hesitating or trailing off',
              'avoid stiff diary-report sentences ending in 했다/였다/이다 unless it is a calm narration panel',
              'prefer speech endings like 해야지!, 큰일인데?, 좀만 더 해보자, 이거 맞아?, 드디어 됐다!, 생각보다 빡세네',
              'good Korean dialogue examples: 오늘은 진짜 해낸다! / 어라, 왜 또 안 되지? / 이거 생각보다 빡세네 / 그래도 조금씩 된다! / 아, 이제 감 잡았어!',
              'bad Korean dialogue examples: 오늘은 앱 개발을 시작했다, 나는 매우 기뻤다, 이 장면은 공부를 의미한다, one generic word only, mixed English/Korean labels, irrelevant slogans, copied prompt metadata',
              'for daily_comic genre, make the line light and conversational with a small gag or honest reaction',
              'for serious genre, make the line restrained and reflective, but not stiff or essay-like',
              'for fantasy_action genre, exaggerate ordinary diary events into quest/battle-like spoken lines',
              'for healing_romance genre, make the line warm, soft, and emotionally specific',
              'for qa_slide, alternate question and answer cards in dialogue, for example "오늘 기분은 어땠어?" then "생각보다 훨씬 힘들었어..."',
              'for reaction_focus, dialogue can be a vivid reaction phrase or a short sentence tied to the diary event',
              'for image_focus, dialogue should still be natural but concise, like a caption inside one bubble',
              'image_prompt must not ask the image model to draw a speech bubble; it should reserve clean space for the later app-drawn bubble',
              'image_prompt must be English-only; if the diary includes words, convert them into visual actions or props',
              'use clean webtoon/card composition with one clear diary action per panel',
              'each panel must be a storyboarded webtoon cut, not a decorative standalone image',
              'each panel must include a concrete location, a visible action, at least one prop, and comic effects',
              'selected webtoon format, art style, genre, genre subtype, weather, keyword tags, and persona must all be visible or structurally reflected',
              'image_prompt must include a visible action, prop, or location from the diary content',
              'image_prompt must repeat the chosen art style in concrete visual terms: line thickness, eye shape, proportions, shading method, color contrast, texture, and what styles to avoid',
              'image_prompt must not merely say anime/comics/3D/simple; it must describe the exact rendering grammar for the selected style',
              'style tag contract: comics_ld means 극화풍, comics_sd means 카툰, anime_ld means 망가, anime_sd means chibi, simple_2d means Kakao Friends or Sanrio-like heavily deformed simple 2D character, realistic_3d means Pixar-like 3D graphics',
              'for comics_ld, explicitly include 극화풍; for comics_sd, explicitly include 카툰; for anime_ld, explicitly include 망가; for anime_sd, explicitly include chibi',
              'for simple_2d, explicitly describe heavily deformed simple mascot character like Kakao Friends or Sanrio; for realistic_3d, explicitly describe Pixar-like 3D graphics',
              'do not describe a headshot, profile image, bust portrait, or generic handsome/pretty character portrait',
              'never request multiple portraits, portrait grid, reference sheet, model sheet, lineup, or collage',
              'if keyword tags are present, treat them as must-not-miss story anchors',
            ],
          }),
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          ...diaryPromptSchema,
        },
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`GPT prompt generation failed: ${await response.text()}`);
  }

  return normalizeStructuredDiary(
    JSON.parse(extractOutputText(await response.json())) as StructuredDiary,
    diary,
  );
}

async function createPanels(
  adminClient: ReturnType<typeof createClient>,
  imageContext: ImageGenerationContext,
  diary: DiaryRow,
  persona: PersonaRow | null,
  structured: StructuredDiary,
): Promise<string[]> {
  const urls: string[] = [];
  const baseSeed = persona?.default_seed ?? stableSeed(diary.id);

  for (let index = 0; index < structured.panels.length; index += 1) {
    const panel = structured.panels[index];
    const seed = stableSeed(`${diary.id}-${index}-${baseSeed}`);
    const prompt = buildPanelPrompt(diary, persona, panel);

    await adminClient.from('diary_panels').upsert({
      diary_id: diary.id,
      panel_order: index,
      panel_type: panel.panel_type,
      dialogue: sanitizeDialogue(panel.dialogue, diary, index),
      prompt,
      seed,
      generation_status: 'processing',
      error_message: null,
    }, { onConflict: 'diary_id,panel_order' });

    // 같은 Storage 경로에 덮어쓰면 브라우저가 예전 이미지를 캐시할 수 있으므로
    // 생성 시도마다 파일명을 바꿔 새 컷을 확실히 불러오게 한다.
    const storageNonce = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
    const imageUrl = await generateImage(
      adminClient,
      imageContext,
      prompt,
      seed,
      `${diary.user_id}/diaries/${diary.id}/panel-${index}-${storageNonce}.png`,
      '2:3',
      stylePresetForDiary(diary),
      styleLockPrompt(diary.art_style, diary.art_sub_style).negative,
    );

    urls.push(imageUrl);
    await adminClient
      .from('diary_panels')
      .update({ image_url: imageUrl, generation_status: 'completed', error_message: null })
      .eq('diary_id', diary.id)
      .eq('panel_order', index);
  }

  return urls;
}

async function retryPanel(
  adminClient: ReturnType<typeof createClient>,
  imageContext: ImageGenerationContext,
  diary: DiaryRow,
  panelId: string,
): Promise<void> {
  const { data: panel, error } = await adminClient
    .from('diary_panels')
    .select('*')
    .eq('id', panelId)
    .eq('diary_id', diary.id)
    .single();

  if (error || !panel) {
    throw new Error('Panel was not found.');
  }

  const retrySeed = stableSeed(`${panel.id}-${panel.retry_count + 1}`);
  const storageNonce = `${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
  const imageUrl = await generateImage(
    adminClient,
    imageContext,
    panel.prompt ?? diary.content,
    retrySeed,
    `${diary.user_id}/diaries/${diary.id}/panel-${panel.panel_order}-retry-${panel.retry_count + 1}-${storageNonce}.png`,
    '2:3',
    stylePresetForDiary(diary),
    styleLockPrompt(diary.art_style, diary.art_sub_style).negative,
  );

  await adminClient
    .from('diary_panels')
    .update({
      image_url: imageUrl,
      seed: retrySeed,
      generation_status: 'completed',
      error_message: null,
    })
    .eq('id', panelId);
}

function buildPanelPrompt(
  diary: DiaryRow,
  persona: PersonaRow | null,
  panel: StructuredPanel,
): string {
  const contract = buildSelectedTagContract(diary, persona);
  const imagePrompt = sanitizeImagePrompt(panel.image_prompt);
  const storyboardBrief = buildStoryboardBrief(diary, panel);
  const styleDirective = styleLockPrompt(diary.art_style, diary.art_sub_style);
  const personaDirective = personaLockPrompt(persona);
  const expressionDirective = personaExpressionPrompt(persona, panel);
  return [
    'IMAGE PROMPT MODE: detailed art direction paragraph, not tag soup. Follow every style and scene instruction literally.',
    `STYLE LOCK - THIS OVERRIDES ALL OTHER WORDS: ${styleDirective.positive}`,
    `STYLE DETAIL FOR IMAGE MODEL: ${styleDirective.detail}`,
    'ABSOLUTE IMAGE TYPE: one finished diary webtoon SCENE CUT, like a mobile card-slide comic panel. The scene/event must be the subject, not the character face.',
    'TARGET LOOK: mobile diary comic scene, simple readable acting, coherent background, clear props, clean colors, one story beat with visual cause and effect',
    'COMIC PANEL REQUIREMENTS: visible single-panel frame border, obvious webtoon scene acting, readable body pose, hands interacting with props, clear diary environment, action lines, sweat drops, sparkle, impact marks or screentone',
    'TEXT SAFETY RULE: do not draw speech bubbles, Hangul, captions, hashtags, UI badges, labels, signs, pseudo glyphs, English text, or any lettering anywhere. The app will draw the final Korean speech bubble after generation.',
    'WEBTOON CUT COMPOSITION: vertical mobile card, one readable diary event per cut, medium shot, wide shot, over-shoulder shot, or full-body shot. Show hands, body, surrounding environment, props, and leave one clean open area for a later speech bubble where it does not cover the face or main action',
    'SCENE OVER FACE RULE: at least 55 percent of the image should be environment, props, action, effects, and composition. The character may not be a centered talking head.',
    'ANTI-PORTRAIT RULE: never make a handsome/beautiful face close-up, never make a profile image, never make a centered bust portrait, never make a fashion illustration, never make a cinematic character key visual, never make a solo character monologue poster',
    'CAMERA RULE: avoid front-facing eye-contact portrait composition. Prefer 3/4 angle, side view, over-the-shoulder, desk-level view, low angle, wide room view, or action reaction framing.',
    `SCENE-FIRST DIARY WEBTOON PROMPT: ${diarySceneDirective(diary)}`,
    `STRUCTURED PANEL BRIEF, follow exactly: ${storyboardBrief}`,
    'vertical comic frame, one complete diary scene panel',
    'one finished diary webtoon cut with a clear panel border, readable action, no generic pretty illustration look',
    'the character must be doing the diary event, interacting with diary props or location, not posing or talking at the camera',
    'if the diary action is vague, show a concrete externalized event with desk clutter, phone notification, calendar, weather outside window, food, school/work object, RPG quest prop, or social interaction',
    'cute comic timing, simple composition, scene-first storytelling, visible emotion through pose and effects',
    'exactly one scene in this image, not a page layout, not a grid, not a collage, not a character sheet, not multiple portrait variations',
    `webtoon format directive: ${contract.webtoon_format_prompt}`,
    `genre directive: ${contract.genre_prompt}`,
    contract.genre_subtype_prompt
      ? `genre subtype directive: ${contract.genre_subtype_prompt}`
      : null,
    `weather mood: ${contract.weather_prompt}`,
    contract.keyword_prompt,
    imagePrompt,
    `emotion: ${panel.emotion}`,
    `facial expression lock: ${panel.facial_expression}`,
    `body pose lock: ${panel.body_pose}`,
    `gaze direction lock: ${panel.gaze_direction}`,
    `speech bubble placement instruction: ${speechBubblePrompt(panel)}`,
    'Korean dialogue is stored separately for app compositing only. Do not draw or imitate it in the image.',
    `panel layout lock: ${panel.panel_layout_notes}`,
    expressionDirective,
    personaDirective,
    persona?.base_image_url
      ? 'use the saved persona reference image only for identity guidance'
      : null,
    styleDirective.guard,
    `STYLE AVOID LIST: ${styleDirective.negative.join(', ')}`,
    'consistent character, no speech bubble drawn by the image model, no hashtags, no UI badges, no 1 CUT label, no clock icon, no broken pseudo text, no random lettering, no watermark, no logo',
    'high readability, clean background, coherent lighting, no extra fingers',
  ].filter(Boolean).join(', ');
}

function buildStoryboardBrief(diary: DiaryRow, panel: StructuredPanel): string {
  return [
    `card type=${panel.panel_type}`,
    `scene title=${sanitizeShortText(panel.scene_title)}`,
    `visible location=${sanitizeShortText(panel.location)}`,
    `persona action=${sanitizeShortText(panel.character_action)}`,
    `facial expression=${sanitizeShortText(panel.facial_expression)}`,
    `body pose=${sanitizeShortText(panel.body_pose)}`,
    `gaze direction=${sanitizeShortText(panel.gaze_direction)}`,
    `must-show props=${sanitizeStringList(panel.key_props, diary.keyword_tags).join(' | ')}`,
    `camera=${sanitizeShortText(panel.camera_shot)}`,
    speechBubblePrompt(panel),
    `layout notes=${sanitizeImagePrompt(panel.panel_layout_notes)}`,
    `comic effects=${sanitizeStringList(panel.comic_effects, ['webtoon motion lines']).join(' | ')}`,
    `emotion=${sanitizeShortText(panel.emotion)}`,
  ].join('; ');
}

function normalizeStructuredDiary(
  structured: StructuredDiary,
  diary: DiaryRow,
): StructuredDiary {
  return {
    summary: structured.summary?.trim() || fallbackSummary(diary),
    emotion_tags: structured.emotion_tags?.length
      ? structured.emotion_tags.map((tag) => sanitizeShortText(tag)).filter(Boolean)
      : ['일기'],
    panels: structured.panels.map((panel, index) => ({
      panel_type: panel.panel_type,
      scene_title: sanitizeShortText(panel.scene_title) || `컷 ${index + 1}`,
      dialogue: sanitizeDialogue(panel.dialogue, diary, index),
      location: sanitizeShortText(panel.location) || 'diary scene location',
      character_action: sanitizeShortText(panel.character_action) ||
        'the persona acts out the diary event',
      facial_expression: sanitizeShortText(panel.facial_expression) ||
        fallbackFacialExpression(panel.emotion),
      body_pose: sanitizeShortText(panel.body_pose) ||
        'expressive body pose that shows the diary event',
      gaze_direction: sanitizeShortText(panel.gaze_direction) ||
        'looking toward the main diary prop',
      key_props: sanitizeStringList(panel.key_props, diary.keyword_tags),
      camera_shot: sanitizeShortText(panel.camera_shot) || 'vertical medium shot',
      speech_bubble_position: sanitizeBubblePosition(panel.speech_bubble_position),
      speech_bubble_shape: sanitizeBubbleShape(panel.speech_bubble_shape),
      speech_bubble_intent: sanitizeImagePrompt(panel.speech_bubble_intent) ||
        fallbackSpeechIntent(diary, index),
      comic_effects: sanitizeStringList(panel.comic_effects, ['webtoon motion lines']),
      panel_layout_notes: sanitizeImagePrompt(panel.panel_layout_notes) ||
        'keep the character, props, action, and later dialogue safe space balanced in a vertical card',
      image_prompt: sanitizeImagePrompt(panel.image_prompt),
      emotion: sanitizeShortText(panel.emotion) || 'calm',
    })),
  };
}

function sanitizeStringList(
  value: string[] | null | undefined,
  fallback: string[],
): string[] {
  const cleaned = (value ?? [])
    .map((item) => sanitizeShortText(item))
    .filter((item) => item.length > 0);

  return cleaned.length ? cleaned.slice(0, 6) : fallback.slice(0, 6);
}

function sanitizeDialogue(
  value: string | null | undefined,
  diary: DiaryRow,
  index: number,
): string {
  const cleaned = sanitizeShortText(value ?? '')
    .replace(/^(나|내|캐릭터|주인공|질문|답변|대사)\s*[:：]\s*/u, '')
    .replace(/^["'“”‘’]+|["'“”‘’]+$/gu, '')
    .trim();

  if (cleaned) {
    return compactKoreanDialogue(cleaned);
  }

  if (diary.webtoon_format === 'qa_slide') {
    return index % 2 === 0 ? '오늘 어땠어?' : '기억할래!';
  }

  if (diary.webtoon_format === 'reaction_focus') {
    return '진짜?!';
  }

  return compactKoreanDialogue(fallbackSummary(diary));
}

function compactKoreanDialogue(value: string): string {
  const cleaned = sanitizeShortText(value)
    .replace(/\s+/g, ' ')
    .replace(/[~]+/g, '!')
    .trim();
  if (cleaned.length <= 14) {
    return cleaned;
  }

  const sentence = cleaned.split(/[.!?。！？]/u).find((part) => part.trim().length) ??
    cleaned;
  const clipped = sentence.trim().slice(0, 12);
  return clipped.endsWith('!') || clipped.endsWith('?') || clipped.endsWith('.')
    ? clipped
    : `${clipped}...`;
}

function sanitizeBubblePosition(value: string | null | undefined): string {
  const allowed = new Set([
    'upper_left',
    'upper_right',
    'center_top',
    'left_side',
    'right_side',
    'bottom_left',
    'bottom_right',
    'none',
  ]);
  const cleaned = sanitizeShortText(value ?? '');
  return allowed.has(cleaned) ? cleaned : 'upper_right';
}

function sanitizeBubbleShape(value: string | null | undefined): string {
  const allowed = new Set([
    'rounded_speech_bubble',
    'thought_bubble',
    'reaction_caption_box',
    'small_shout_bubble',
    'none',
  ]);
  const cleaned = sanitizeShortText(value ?? '');
  return allowed.has(cleaned) ? cleaned : 'rounded_speech_bubble';
}

function speechBubblePrompt(panel: StructuredPanel): string {
  const position = sanitizeBubblePosition(panel.speech_bubble_position);
  if (position === 'none') {
    return 'later app bubble placement=best natural empty area, keep that area simple and uncluttered';
  }

  const placement = bubblePlacement(position);
  return [
    'do not draw a speech bubble; reserve open space for an app-drawn speech bubble',
    `later app bubble placement=${position}`,
    `later app bubble alignment=${placement.alignment}`,
    `later app bubble margin=${placement.margin}`,
    'do not draw or imitate any Korean letters',
    `dialogue meaning only=${sanitizeImagePrompt(panel.speech_bubble_intent)}`,
    'keep the reserved area wide enough for Korean text and naturally near the speaking character',
    'keep face, hands, key props, and main action outside the reserved area',
  ].join(', ');
}

function bubblePlacement(position: string): BubblePlacement {
  switch (position) {
    case 'upper_left':
      return { alignment: 'upper-left interior safe area', margin: 'top 14%, left 14%' };
    case 'upper_right':
      return { alignment: 'upper-right interior safe area', margin: 'top 14%, right 14%' };
    case 'center_top':
      return { alignment: 'top center interior safe area', margin: 'top 14%, centered' };
    case 'left_side':
      return { alignment: 'middle-left safe area', margin: 'left 6%, vertical center' };
    case 'right_side':
      return { alignment: 'middle-right safe area', margin: 'right 6%, vertical center' };
    case 'bottom_left':
      return { alignment: 'bottom-left interior safe area', margin: 'bottom 14%, left 14%' };
    case 'bottom_right':
      return { alignment: 'bottom-right interior safe area', margin: 'bottom 14%, right 14%' };
    default:
      return { alignment: 'bottom center interior safe area', margin: 'bottom 14%, centered' };
  }
}

function fallbackFacialExpression(emotion: string | null | undefined): string {
  const value = sanitizeShortText(emotion ?? '').toLowerCase();
  if (value.includes('angry') || value.includes('분노') || value.includes('화')) {
    return 'puffed cheeks, sharp eyebrows, small angry pout';
  }
  if (value.includes('sad') || value.includes('슬픔') || value.includes('우울')) {
    return 'teary eyes, trembling mouth, lowered eyebrows';
  }
  if (
    value.includes('embarrassed') ||
    value.includes('당황') ||
    value.includes('부끄')
  ) {
    return 'wide anxious eyes, tiny awkward smile, sweat drop';
  }
  if (value.includes('happy') || value.includes('기쁨') || value.includes('신남')) {
    return 'bright smile, sparkling eyes, lifted cheeks';
  }

  return 'calm expressive face, soft eyes, small readable smile';
}

function fallbackSpeechIntent(diary: DiaryRow, index: number): string {
  if (diary.webtoon_format === 'qa_slide') {
    return index % 2 === 0
      ? 'the character asks a cute question about today'
      : 'the character answers with an emotional diary reaction';
  }
  if (diary.webtoon_format === 'reaction_focus') {
    return 'a short surprised Korean reaction phrase';
  }
  return 'a short diary line that summarizes the feeling of this moment';
}

function sanitizeImagePrompt(value: string | null | undefined): string {
  return (value ?? '')
    .replace(/["'“”‘’][^"'“”‘’]{1,80}["'“”‘’]/gu, ' ')
    .replace(/\b(text|caption|subtitle|speech bubble|dialogue|lettering|words?|sign says|written|Korean text)\b/giu, ' ')
    .replace(/[가-힣ㄱ-ㅎㅏ-ㅣ]+/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function sanitizeShortText(value: string): string {
  return value
    .replace(/\uFFFD/g, '')
    .replace(/[\u0000-\u001F\u007F]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function fallbackSummary(diary: DiaryRow): string {
  const source = diary.title?.trim() || diary.content.trim() || '오늘의 한 컷';
  return source.length > 38 ? `${source.slice(0, 35)}...` : source;
}

function diarySceneDirective(diary: DiaryRow): string {
  const title = diary.title?.trim() ? `title: ${diary.title.trim()}; ` : '';
  const tags = diary.keyword_tags.length
    ? `keyword tags that must affect the visible scene: ${
      diary.keyword_tags.map((tag) => `#${tag}`).join(', ')
    }; `
    : '';
  const content = diary.content.replace(/\s+/g, ' ').trim();
  const clipped = content.length > 700 ? `${content.slice(0, 700)}...` : content;
  return `${title}${tags}diary event to illustrate, not to write as text: ${clipped}`;
}

function mediumGuardPrompt(artStyle: string): string {
  if (artStyle === 'realistic_3d') {
    return '3D-inspired softness is allowed only as subtle toy-like volume, but the final output must still be a cute diary webtoon panel with line art and flat cel shading, not a render';
  }

  return 'pure cute 2D diary webtoon/comic drawing, rounded SD character, line art and cel shading, not photorealistic, not live action, not 3D render, not painterly concept art';
}

function stylePresetForDiary(diary: DiaryRow): string {
  switch (diary.art_style) {
    case 'anime_ld':
    case 'anime_sd':
      return 'anime';
    case 'comics_ld':
    case 'comics_sd':
      return 'comic-book';
    case 'realistic_3d':
      return '3d-model';
    case 'simple_2d':
      return 'digital-art';
    default:
      return 'comic-book';
  }
}

function styleLockPrompt(style: string, subStyle: string | null): {
  positive: string;
  detail: string;
  guard: string;
  negative: string[];
} {
  const subtype = subStyle ? ` Selected sub-style tag: ${subStyle}.` : '';
  switch (style) {
    case 'anime_ld':
      return {
        positive:
          `JAPANESE ANIME LD ONLY, 망가 style: manga-inspired Japanese anime drawing, delicate manga linework, expressive manga eyes, clean screen-tone/cel-shading feeling, readable diary webtoon acting, no western comic inking.${subtype}`,
        detail:
          'Use 망가 grammar: thin clean manga line art, expressive manga eyes, simplified nose and mouth, smooth hair clumps, soft cel shading, gentle screen-tone accents when useful, and clear manga panel acting. Keep it emotional and readable as a diary webtoon scene, not gritty western comics or a realistic portrait.',
        guard:
          'Keep the final image 망가 / Japanese anime LD style only. Do not use American comics, Marvel/DC style, thick western ink, Pixar 3D, Sanrio mascot style, realistic drama portrait, or oil painting.',
        negative: [
          'American comic book',
          'western comics',
          'Marvel style',
          'DC comics style',
          'heavy ink shadows',
          'crosshatching',
          'realistic portrait',
          'photorealistic face',
        ],
      };
    case 'anime_sd':
      return {
        positive:
          `JAPANESE ANIME SD ONLY, chibi style: two-head chibi proportions, tiny cute body, oversized expressive anime eyes, compact manga reaction acting, soft pastel cel shading.${subtype}`,
        detail:
          'Use chibi grammar: 2-head to 3-head proportions, tiny rounded hands, oversized sparkling eyes, small button nose, simplified mouth, cute manga reaction stickers, and compact vertical card composition. The scene must be a diary webtoon reaction cut with clear props and action, not a normal portrait.',
        guard:
          'Keep the final image chibi anime only. Do not use realistic anatomy, American cartoon, western superhero comic, Pixar 3D, Sanrio mascot style, or mature LD proportions.',
        negative: [
          'realistic anatomy',
          'long realistic body',
          'American comic book',
          'western cartoon',
          'Marvel style',
          'DC comics style',
          'semi-realistic portrait',
        ],
      };
    case 'comics_ld':
      return {
        positive:
          `COMICS LD ONLY, 극화풍: dramatic gekiga-like comic rendering, strong black ink outlines, realistic but stylized anatomy, high contrast shadows, serious dramatic panel energy, expressive comic effects.${subtype}`,
        detail:
          'Use 극화풍 grammar: thick black contour lines, angular shadow blocks, strong light-dark contrast, dramatic face planes, strong eyebrows, dynamic hands and shoulders, speed lines, impact marks, halftone or screentone accents, and a bold single-panel frame. Keep the diary event visible; do not turn it into a generic superhero poster or handsome portrait.',
        guard:
          'Keep the final image 극화풍 comics LD only. Do not use 망가, chibi, 카툰 SD, Pixar 3D, Sanrio/Kakao mascot style, moe eyes, or soft romance webtoon rendering.',
        negative: [
          'Japanese anime',
          'manga style',
          'moe anime eyes',
          'Korean romance webtoon face',
          'chibi',
          'soft anime shading',
          'idol portrait',
        ],
      };
    case 'comics_sd':
      return {
        positive:
          `COMICS SD ONLY, 카툰 style: playful cartoon character, thick outline, bouncy shapes, exaggerated goofy expression, bright flat colors, funny deformation, comic-strip gag timing.${subtype}`,
        detail:
          'Use 카툰 grammar: thick friendly outlines, bouncy simplified shapes, squat cute body, exaggerated mouth and eyebrows, rubbery pose, bright flat color blocks, playful impact marks, sweat drops, stars, and comic timing. It should feel like a gag cartoon diary card with one clear action, not anime sparkle-face rendering.',
        guard:
          'Keep the final image 카툰 comics SD only. Do not use 망가, chibi anime, 극화풍 LD, realistic portrait, Pixar 3D, or polished romance webtoon face.',
        negative: [
          'Japanese anime',
          'manga style',
          'realistic portrait',
          'romance webtoon',
          'semi-realistic face',
          'fashion model',
        ],
      };
    case 'realistic_3d':
      return {
        positive:
          `PIXAR-LIKE 3D GRAPHICS ONLY: cute stylized 3D animated character, soft rounded volume, Pixar-like family animation mood, cinematic daily scene, expressive but not photorealistic.${subtype}`,
        detail:
          'Use Pixar-like 3D graphics grammar: soft rounded volume, appealing stylized proportions, simple expressive eyes, sculpted toy-like hair shapes, gentle ambient occlusion, pastel materials, cinematic but cute lighting, and a cozy miniature diary environment. The pose and props must show the diary event. Do not drift into photorealistic human portrait, glossy fashion render, flat anime, or comic ink.',
        guard:
          'Keep the final image Pixar-like 3D graphics only. Do not use flat anime, 망가, chibi, comics, 카툰 ink, Sanrio/Kakao mascot flat 2D, or realistic human photography.',
        negative: [
          'flat anime',
          'manga',
          'comic book ink',
          'photorealistic human',
          'live action',
          'real person',
        ],
      };
    case 'simple_2d':
      return {
        positive:
          `SIMPLE 2D CHARACTER ONLY: heavily deformed mascot-like 2D character, Kakao Friends or Sanrio-like simplicity, minimal facial features, flat pastel colors, simple rounded shapes, clear icon-like silhouette.${subtype}`,
        detail:
          'Use Kakao Friends / Sanrio-like simple 2D mascot grammar: very deformed rounded body, iconic silhouette, minimal nose and mouth, simple dot or oval eyes, clean outlines, flat pastel fills, few details, readable props, and lots of calm negative space. The image should look like a cute simple character diary card, not anime illustration, western comic page, 3D render, or realistic portrait.',
        guard:
          'Keep the final image heavily deformed simple 2D mascot style only. Do not use 망가, chibi anime, 극화풍 comics, 카툰 gag comic, realistic portrait, or Pixar-like 3D render.',
        negative: [
          'detailed anime face',
          'American comic book',
          'realistic portrait',
          '3D render',
          'photorealistic',
          'complex painting',
        ],
      };
    default:
      return {
        positive: `SELECTED STYLE ONLY: ${style}.${subtype}`,
        detail:
          'Describe the selected visual style with concrete linework, proportions, shading, color, and composition choices, and keep it dominant across the whole image.',
        guard: 'The selected art style must dominate the whole image.',
        negative: [],
      };
  }
}

function personaLockPrompt(persona: PersonaRow | null): string | null {
  if (!persona) {
    return null;
  }

  const tags = persona.appearance_tags
    ? Object.entries(persona.appearance_tags)
      .map(([key, value]) => `${key}: ${String(value)}`)
      .join(', ')
    : '';
  const englishTags = persona.appearance_tags
    ? translateAppearanceTags(persona.appearance_tags)
    : '';
  const desc = sanitizeImagePrompt(persona.appearance_desc);
  return [
    'CHARACTER LOCK - MUST KEEP THIS CHARACTER DESIGN:',
    persona.name ? `character name/design label: ${persona.name}` : null,
    tags ? `fixed appearance tags: ${tags}` : null,
    englishTags ? `fixed appearance in English: ${englishTags}` : null,
    desc ? `fixed appearance description: ${desc}` : null,
    'Apply this identity to the actor in the diary scene, but keep the selected art style above. Do not invent a different hairstyle, hair color, eye color, outfit, age, or gender presentation.',
  ].filter(Boolean).join(' ');
}

function personaExpressionPrompt(
  persona: PersonaRow | null,
  panel: StructuredPanel,
): string | null {
  if (!persona?.expression_library) {
    return null;
  }

  const key = expressionKeyForPanel(panel);
  const expression = persona.expression_library[key];
  if (!expression) {
    return null;
  }

  return [
    'PERSONA EXPRESSION LIBRARY MATCH:',
    `emotion key=${key}`,
    `character expression reference=${sanitizeImagePrompt(expression)}`,
    'Blend this expression reference with the panel facial_expression, while preserving the selected art style.',
  ].join(' ');
}

function expressionKeyForPanel(
  panel: StructuredPanel,
): 'happy' | 'sad' | 'angry' | 'embarrassed' | 'calm' {
  const source = [
    panel.emotion,
    panel.dialogue,
    panel.facial_expression,
    panel.speech_bubble_intent,
  ].join(' ').toLowerCase();

  if (
    source.includes('angry') ||
    source.includes('rage') ||
    source.includes('분노') ||
    source.includes('화') ||
    source.includes('짜증')
  ) {
    return 'angry';
  }
  if (
    source.includes('sad') ||
    source.includes('tear') ||
    source.includes('슬픔') ||
    source.includes('우울') ||
    source.includes('최악')
  ) {
    return 'sad';
  }
  if (
    source.includes('embarrassed') ||
    source.includes('awkward') ||
    source.includes('anxious') ||
    source.includes('당황') ||
    source.includes('부끄') ||
    source.includes('민망')
  ) {
    return 'embarrassed';
  }
  if (
    source.includes('happy') ||
    source.includes('joy') ||
    source.includes('smile') ||
    source.includes('기쁨') ||
    source.includes('좋아') ||
    source.includes('신나')
  ) {
    return 'happy';
  }

  return 'calm';
}

function translateAppearanceTags(tags: Record<string, unknown>): string {
  const dictionary: Record<string, string> = {
    '밝은 피부': 'fair skin',
    '어두운 피부': 'dark skin',
    '검은 머리': 'black hair',
    '갈색 머리': 'brown hair',
    '금발': 'blonde hair',
    '파란 머리': 'blue hair',
    '분홍 머리': 'pink hair',
    '단발': 'short bob haircut',
    '긴 머리': 'long hair',
    '포니테일': 'ponytail',
    '푸른 눈': 'blue eyes',
    '갈색 눈': 'brown eyes',
    '검은 눈': 'black eyes',
    '초록 눈': 'green eyes',
    '왼쪽 하이라이트': 'eye highlight on the left side',
    '오른쪽 하이라이트': 'eye highlight on the right side',
    '차분함': 'calm personality',
    '장난스러움': 'playful personality',
    '활발함': 'energetic personality',
    '수줍음': 'shy personality',
    '후드': 'hoodie',
    '교복': 'school uniform',
    '셔츠': 'shirt',
    '니트': 'knit sweater',
    '치마': 'skirt',
    '바지': 'pants',
    '청바지': 'jeans',
  };

  const translated: string[] = [];
  for (const [key, value] of Object.entries(tags)) {
    const raw = `${key} ${String(value)}`;
    const matches = Object.entries(dictionary)
      .filter(([k]) => raw.includes(k))
      .map(([, v]) => v);
    if (matches.length) {
      translated.push(...matches);
    } else if (String(value).trim()) {
      translated.push(`${key}: ${String(value)}`);
    }
  }

  return [...new Set(translated)].join(', ');
}

function buildSelectedTagContract(
  diary: DiaryRow,
  persona: PersonaRow | null,
): Record<string, unknown> {
  return {
    persona_id: persona?.id ?? null,
    persona_name: persona?.name ?? null,
    persona_seed: persona?.default_seed ?? stableSeed(diary.id),
    persona_appearance_desc: persona?.appearance_desc ?? null,
    persona_appearance_tags: persona?.appearance_tags ?? null,
    expression_library: persona?.expression_library ?? null,
    webtoon_format: diary.webtoon_format,
    webtoon_format_prompt: webtoonFormatPrompt(diary.webtoon_format),
    art_style: diary.art_style,
    art_sub_style: diary.art_sub_style,
    art_style_prompt: artStylePrompt(diary.art_style, diary.art_sub_style),
    genre: diary.genre,
    genre_prompt: genrePrompt(diary.genre),
    genre_subtype: diary.genre_subtype,
    genre_subtype_prompt: genreSubtypePrompt(diary.genre_subtype),
    weather: diary.weather,
    weather_prompt: weatherPrompt(diary.weather),
    keyword_tags: diary.keyword_tags,
    keyword_prompt: keywordPrompt(diary.keyword_tags),
  };
}

function webtoonFormatPrompt(value: string): string {
  switch (value) {
    case 'image_focus':
      return 'image-focused webtoon card: minimize visual clutter, emphasize one memorable scene, make the illustration carry the emotion, no plain poster look';
    case 'qa_slide':
      return 'Q&A webtoon card: alternate question-like setup and answer-like reaction, cute character interaction, expressive pose, comic timing';
    case 'reaction_focus':
      return 'reaction-focused meme-like webtoon cut: simple background, exaggerated facial expression and pose, instantly readable emotion, comic effect marks';
    case 'card_slide':
    default:
      return 'story webtoon card slide: one vertical comic panel per scene, swipeable sequence, clear scene progression';
  }
}

function artStylePrompt(style: string, subStyle: string | null): string {
  const subtype = subStyle ? `, selected sub-style: ${subStyle}` : '';
  switch (style) {
    case 'comics_ld':
      return `코믹스 LD 극화풍 diary webtoon style${subtype}: bold ink lines, strong contrast, dramatic gekiga-like rendering, dynamic comic pose, but still a readable diary webtoon card`;
    case 'comics_sd':
      return `코믹스 SD 카툰 diary webtoon style${subtype}: compact cute proportions, bouncy colors, playful deformation, exaggerated comedy expressions, comic-strip gag drama in simplified cartoon form`;
    case 'anime_ld':
      return `일본 애니메이션 LD 망가 diary webtoon style${subtype}: delicate manga linework, expressive manga eyes, clean cel shading, cute panel acting`;
    case 'anime_sd':
      return `일본 애니메이션 SD chibi diary webtoon style${subtype}: two-head cute proportions, small body big emotion, reaction-friendly`;
    case 'realistic_3d':
      return `3D Pixar-like graphics diary webtoon style${subtype}: cute stylized 3D volume, rounded forms, cinematic family animation mood, not photorealistic`;
    case 'simple_2d':
      return `2D simple character diary webtoon style${subtype}: heavily deformed Kakao Friends or Sanrio-like mascot simplicity, clean outlines, flat pastel colors`;
    default:
      return `selected art style ${style}${subtype}: keep this style dominant in every panel`;
  }
}

function genrePrompt(value: string): string {
  switch (value) {
    case 'daily_comic':
      return 'daily comedy genre: light everyday humor, focus lines, sweat drops, surprise marks, charming small mistakes';
    case 'serious':
      return 'serious genre: introspective mood, stronger light and shadow, restrained colors, cinematic monologue feeling';
    case 'fantasy_action':
      return 'fantasy action genre as a diary gag: transform ordinary events into cute RPG-like exaggeration, but keep it a simple readable diary webtoon cut, not epic fantasy illustration';
    case 'healing_romance':
      return 'healing romance genre: warm emotional connection, soft light, gentle particles, flowers or bubbles when appropriate';
    default:
      return `selected genre ${value}: make the scene follow this genre strongly`;
  }
}

function genreSubtypePrompt(value: string | null): string | null {
  if (!value) {
    return null;
  }

  switch (value) {
    case 'school':
      return 'school-life subtype: classroom, campus, uniforms, study mood, youth empathy';
    case 'sitcom':
      return 'sitcom subtype: awkward timing, funny reaction beats, exaggerated everyday situation';
    case 'documentary':
      return 'documentary subtype: objective observation, dry realistic framing, less melodrama';
    case 'monologue':
      return 'monologue subtype: inner emotion, quiet composition, psychological atmosphere';
    case 'rpg':
    case 'RPG':
      return 'RPG subtype: quests, level-up feeling, guild fantasy metaphors, magical study or daily adventure';
    case 'hot_blooded':
      return 'hot-blooded action subtype: impact poses, speed lines, dramatic battle-manga energy';
    case 'youth':
      return 'youth subtype: blue sky, bicycle, school uniform, fresh growing-up atmosphere';
    case 'daily_healing':
      return 'daily healing subtype: peaceful silence, cozy food steam, soft empty space, calm domestic detail';
    default:
      return `selected genre subtype ${value}: reflect this subtype clearly`;
  }
}

function weatherPrompt(value: string): string {
  switch (value) {
    case 'sunny':
      return 'sunny weather: bright daylight, cheerful warm highlights';
    case 'cloudy':
      return 'cloudy weather: soft diffused light, calm muted sky';
    case 'rainy':
      return 'rainy weather: wet reflections, umbrella or rain streaks if relevant, cozy melancholy';
    case 'snowy':
      return 'snowy weather: cold clean air, snowflakes, quiet winter light';
    case 'foggy':
      return 'foggy weather: hazy depth, soft silhouettes, dreamy atmosphere';
    default:
      return `weather tag ${value}: use it as scene atmosphere`;
  }
}

function keywordPrompt(tags: string[]): string | null {
  if (!tags.length) {
    return null;
  }

  return `must include or strongly imply these Korean keyword tags as story anchors: ${
    tags.map((tag) => `#${tag}`).join(', ')
  }`;
}

async function generateStabilityImage(
  adminClient: ReturnType<typeof createClient>,
  apiKey: string,
  prompt: string,
  seed: number,
  storagePath: string,
  aspectRatio: string,
  stylePreset: string,
  styleNegativePrompt: string[],
): Promise<string> {
  const endpoint = Deno.env.get('STABILITY_IMAGE_ENDPOINT') ??
    'https://api.stability.ai/v2beta/stable-image/generate/core';
  const negativePrompt = [
    'text',
    'watermark',
    'logo',
    'signature',
    'blurry',
    'distorted face',
    'extra fingers',
    'multiple panels',
    'panel grid',
    'comic page',
    'page layout',
    'collage',
    'grid',
    'contact sheet',
    'character sheet',
    'reference sheet',
    'model sheet',
    'lineup',
    'portrait grid',
    'multiple portraits',
    'duplicated face',
    'duplicated person',
    'variations',
    'corporate headshot',
    'headshot',
    'close-up portrait',
    'bust portrait',
    'profile picture',
    'passport photo',
    'ID photo',
    'standing still',
    'posing for camera',
    'generic character portrait',
    'anime character portrait',
    'webtoon character portrait',
    'talking head',
    'solo monologue',
    'character talking to camera',
    'front-facing eye contact portrait',
    'centered character bust',
    'single character standing in empty background',
    'handsome man portrait',
    'pretty woman portrait',
    'beautiful girl portrait',
    'K-drama handsome man',
    'fashion model',
    'model photoshoot',
    'glamour shot',
    'face closeup',
    'detailed face closeup',
    'detailed realistic eyes',
    'photorealistic portrait',
    'photograph',
    'photo',
    'realistic photo',
    'DSLR',
    'cinematic still',
    'movie still',
    'realistic render',
    'painterly illustration',
    'concept art',
    'poster art',
    'splash art',
    'standalone illustration',
    'generic illustration',
    'wallpaper',
    'cover art',
    'visual novel CG',
    'game character art',
    'character art only',
    'beautiful portrait illustration',
    'semi-realistic painting',
    'adult realistic anatomy',
    'sharp jawline handsome face',
    'fashion illustration',
    'detailed realistic face',
    'dramatic realistic lighting',
    'epic fantasy illustration',
    'dark serious cinematic mood',
    ...styleNegativePrompt,
  ].join(', ');

  const buildFormData = (includeStylePreset: boolean): FormData => {
    const formData = new FormData();
    formData.append('prompt', prompt);
    formData.append('seed', seed.toString());
    formData.append('aspect_ratio', aspectRatio);
    formData.append('output_format', 'png');
    if (includeStylePreset) {
      formData.append('style_preset', stylePreset);
    }
    formData.append('negative_prompt', negativePrompt);
    return formData;
  };

  let response = await fetch(endpoint, {
    method: 'POST',
    signal: AbortSignal.timeout(90_000),
    headers: {
      authorization: `Bearer ${apiKey}`,
      accept: 'application/json',
    },
    body: buildFormData(true),
  });

  if (!response.ok) {
    const errorText = await response.text();
    if (errorText.toLowerCase().includes('style_preset')) {
      response = await fetch(endpoint, {
        method: 'POST',
        signal: AbortSignal.timeout(90_000),
        headers: {
          authorization: `Bearer ${apiKey}`,
          accept: 'application/json',
        },
        body: buildFormData(false),
      });
    } else {
      throw new Error(`Stability image generation failed: ${errorText}`);
    }
  }

  if (!response.ok) {
    throw new Error(`Stability image generation failed: ${await response.text()}`);
  }

  const json = await response.json();
  if (!json.image) {
    throw new Error('Stability response did not include image data.');
  }

  const imageBytes = Uint8Array.from(atob(json.image), (char) => char.charCodeAt(0));
  const { error: uploadError } = await adminClient.storage
    .from('diary-assets')
    .upload(storagePath, imageBytes, { contentType: 'image/png', upsert: true });

  if (uploadError) {
    throw new Error(`Image upload failed: ${uploadError.message}`);
  }

  const { data } = adminClient.storage.from('diary-assets').getPublicUrl(storagePath);
  return data.publicUrl;
}

async function generateImage(
  adminClient: ReturnType<typeof createClient>,
  imageContext: ImageGenerationContext,
  prompt: string,
  seed: number,
  storagePath: string,
  aspectRatio: string,
  stylePreset: string,
  styleNegativePrompt: string[],
): Promise<string> {
  if (imageContext.provider === 'gemini') {
    if (!imageContext.geminiApiKey) {
      throw new Error('Missing GEMINI_API_KEY.');
    }
    return generateGeminiImage(
      adminClient,
      imageContext.geminiApiKey,
      prompt,
      storagePath,
      aspectRatio,
    );
  }

  if (!imageContext.stabilityApiKey) {
    throw new Error('Missing STABILITY_API_KEY.');
  }

  return generateStabilityImage(
    adminClient,
    imageContext.stabilityApiKey,
    prompt,
    seed,
    storagePath,
    aspectRatio,
    stylePreset,
    styleNegativePrompt,
  );
}

async function generateGeminiImage(
  adminClient: ReturnType<typeof createClient>,
  apiKey: string,
  prompt: string,
  storagePath: string,
  aspectRatio: string,
): Promise<string> {
  const model = Deno.env.get('GEMINI_IMAGE_MODEL') ?? 'gemini-2.5-flash-image';
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  const geminiPrompt = [
    '아래 지시를 바탕으로 한국어 웹툰 카드 한 컷을 완성해줘.',
    '구글 Gemini에서 자연어로 이미지 만들라고 입력하는 것처럼 처리해줘. 너무 기술적인 포스터나 초상화가 아니라, 실제 일기 웹툰의 한 장면이어야 해.',
    '한 화면에 하나의 컷만 있고, 컷 안에는 배경, 캐릭터의 행동, 소품, 감정 연출, 효과선이 자연스럽게 들어가야 해.',
    '중요: 말풍선과 글자는 절대 그리지 마. 한국어, 영어, 해시태그, UI 배지, 로고, 워터마크, 가짜 글자, 깨진 글자는 전부 금지야.',
    '대신 나중에 앱이 말풍선을 그릴 수 있도록 얼굴, 손, 핵심 소품을 가리지 않는 깨끗한 여백을 하나 남겨줘.',
    '선택된 그림체와 캐릭터 외형은 유지하고, 일기 내용과 태그가 장면에 보이게 반영해줘.',
    '아래는 OpenAI가 일기와 태그를 분석해서 정리한 컷 지시야. 그대로 따라줘:',
    prompt,
  ].join('\n');

  const response = await fetch(endpoint, {
    method: 'POST',
    signal: AbortSignal.timeout(90_000),
    headers: {
      'x-goog-api-key': apiKey,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [{ text: geminiPrompt }],
        },
      ],
      generationConfig: {
        responseModalities: ['IMAGE'],
        imageConfig: { aspectRatio },
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini image generation failed: ${await response.text()}`);
  }

  const json = await response.json();
  const parts = json?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) {
    throw new Error('Gemini response did not include image parts.');
  }

  const imagePart = parts.find((part) => part?.inlineData?.data);
  const imageData = imagePart?.inlineData?.data;
  const mimeType = imagePart?.inlineData?.mimeType ?? 'image/png';
  if (typeof imageData !== 'string') {
    throw new Error('Gemini response did not include image data.');
  }

  const imageBytes = Uint8Array.from(atob(imageData), (char) => char.charCodeAt(0));
  const { error: uploadError } = await adminClient.storage
    .from('diary-assets')
    .upload(storagePath, imageBytes, { contentType: mimeType, upsert: true });

  if (uploadError) {
    throw new Error(`Image upload failed: ${uploadError.message}`);
  }

  const { data } = adminClient.storage.from('diary-assets').getPublicUrl(storagePath);
  return data.publicUrl;
}

function extractOutputText(json: Record<string, unknown>): string {
  if (typeof json.output_text === 'string') {
    return json.output_text;
  }

  const output = json.output;
  if (Array.isArray(output)) {
    for (const item of output) {
      const content = (item as { content?: unknown }).content;
      if (Array.isArray(content)) {
        for (const contentItem of content) {
          const text = (contentItem as { text?: unknown }).text;
          if (typeof text === 'string') {
            return text;
          }
        }
      }
    }
  }

  throw new Error('Could not find JSON text in GPT response.');
}

function stableSeed(input: string): number {
  let hash = 0;
  for (const char of input) {
    hash = (hash * 31 + char.charCodeAt(0)) & 0x7fffffff;
  }
  return Math.max(hash, 1);
}

async function safeJson<T>(request: Request): Promise<T | null> {
  try {
    return await request.json() as T;
  } catch (_) {
    return null;
  }
}

