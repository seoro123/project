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
  retry_feedback?: string;
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
  style_template_id: string | null;
  style_template_prompt: string | null;
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
  image_url: string | null;
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
        payload.retry_feedback,
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
      'id, name, appearance_desc, appearance_tags, expression_library, default_seed, image_url, base_image_url, default_art_style, default_genre',
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
  const displayTags = visibleKeywordTags(diary.keyword_tags);
  const tags = displayTags.length
    ? displayTags.map((tag) => `#${tag}`).join(' ')
    : '#일기';
  const personaBrief = persona?.appearance_desc || 'the selected diary character';
  const style = artStylePrompt(diary);
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
        `${style}. ${genre}. ${weather}. The chosen weather must be plainly visible through lighting, background, and at least one concrete weather prop or environmental effect. Finished Korean diary webtoon card panel, not a portrait. Show ${personaBrief} inside ${location}, interacting with ${props.join(', ')}. The scene establishes the diary event from: ${content}. Use vertical mobile card composition, visible panel border, readable action, and leave one clean upper-center open area for a later app-drawn speech bubble. Do not draw any speech bubble, text, hashtag, label, or caption. Pastel webtoon colors, clear background, body and hands visible. ${tags}`,
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
        `${style}. ${genre}. ${weather}. The chosen weather must be plainly visible through lighting, background, and at least one concrete weather prop or environmental effect. A real webtoon scene cut showing the diary problem/action, not a talking head. ${personaBrief} is actively doing the event from: ${content}. Include ${props.join(', ')}, visible hands, body movement, environmental context, sweat drop and motion marks. Vertical card-slide panel with clear single-panel frame and one clean bottom-right open area for later app-drawn dialogue. Do not draw any speech bubble, text, hashtag, label, or caption. ${tags}`,
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
        `${style}. ${genre}. ${weather}. The chosen weather must be plainly visible through lighting, background, and at least one concrete weather prop or environmental effect. Final Korean diary webtoon card panel showing payoff and emotion, not a portrait. ${personaBrief} reacts to finishing the event from: ${content}, with ${props.join(', ')} visible in the scene. Use cozy lighting, small sparkle effects, clear body pose, single vertical panel border, and one clean top open area for later app-drawn dialogue. Do not draw any speech bubble, text, hashtag, label, or caption. ${tags}`,
      emotion: 'relieved',
    },
  ];

  return normalizeStructuredDiary(
    {
      summary: `${title} - ${content}`,
      emotion_tags: visibleKeywordTags(diary.keyword_tags).length
        ? visibleKeywordTags(diary.keyword_tags)
        : ['일기'],
      panels,
    },
    diary,
  );
}

function inferFallbackLocation(diary: DiaryRow): string {
  const text = `${diary.title ?? ''} ${diary.content} ${visibleKeywordTags(diary.keyword_tags).join(' ')}`;
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
  const text = `${diary.title ?? ''} ${diary.content} ${visibleKeywordTags(diary.keyword_tags).join(' ')}`;
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
  visibleKeywordTags(diary.keyword_tags).slice(0, 3).forEach((tag) => props.add(tag));
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
  const desiredPanelCount = requestedPanelCount(diary);
  const visibleTags = visibleKeywordTags(diary.keyword_tags);
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
        'You are a Korean webtoon storyboard writer and a prompt director for Nano Banana / Gemini image generation. OpenAI must first analyze the diary, selected tags, persona, art style, genre, and weather, then write a complete Nano Banana-ready prompt for each card-slide cut. The output format is always card-slide: one vertical webtoon cut per image, shown one by one in the app. Do not create Q&A format, reaction-only format, image-focus format, page layout, grid, collage, or multi-panel image. The image generator must create a finished illustrated Korean diary webtoon scene cut without any rendered text or speech bubble; the Flutter app will draw the final Korean speech bubble after generation. Convert the diary into as many separate card-slide panels as the diary naturally needs. Do not force a 3 to 5 cut limit; a short diary may be 1 to 3 cuts, and a longer diary may use more cuts when the story needs them. Return only JSON that follows the schema. Every panel must contain a concrete location, visible event action, exact facial expression, exact body pose, props, camera shot, preferred bubble placement, layout notes, comic effects, and natural Korean dialogue. The character is an actor inside a scene; the diary event is the subject. dialogue must sound like a real Korean diary webtoon line: usually one sentence, sometimes two short sentences, specific to the scene and emotion, not a generic one-word reaction. speech_bubble_intent must be English-only and summarize the meaning/emotion of the Korean dialogue. image_prompt must be English-only, 700-1200 characters, written as a complete detailed art-direction paragraph for a finished webtoon cut with reserved open space for a later app-drawn bubble. The selected_tags_contract is a hard visual direction from the user, not optional metadata. Each image_prompt must describe exactly one finished webtoon scene cut, never a solo portrait, never a page layout, never a grid, never a character sheet.',
        },
        {
          role: 'user',
          content: JSON.stringify({
            target_output: 'card_slide_only',
            title: diary.title,
            diary: diary.content,
            weather: diary.weather,
            requested_webtoon_format: 'card_slide',
            art_style: diary.art_style,
            art_sub_style: diary.art_sub_style,
            genre: diary.genre,
            genre_subtype: diary.genre_subtype,
            keyword_tags: visibleTags,
            persona_appearance: persona?.appearance_desc,
            persona_appearance_tags: persona?.appearance_tags,
            expression_library: persona?.expression_library,
            selected_tags_contract: tagContract,
            diary_content_length_no_spaces: countKoreanLikeChars(diary.content),
            desired_panel_count: desiredPanelCount,
            minimum_panel_count: desiredPanelCount ?? (shouldForceAtLeastTwoPanels(diary) ? 2 : 1),
            prompt_priority: [
              '1. the diary content and keyword tags decide the actual scene, action, props, location, and emotion',
              '2. selected genre and genre subtype decide the direction and mood',
              '3. output is always card-slide: one vertical finished webtoon cut per generated image',
              '4. selected art style and art sub-style decide rendering style',
              '5. persona appearance is only the actor design inside the diary scene',
              '6. weather/date mood must be visible when relevant',
              '6a. the selected weather is mandatory visual direction: every image_prompt must include concrete visible weather cues in lighting, background, and props, not just mood words',
            ],
            rules: [
              desiredPanelCount
                ? `return exactly ${desiredPanelCount} separate vertical card-slide panel(s), no more and no less`
                : 'choose the number of vertical card panels from the diary content; do not force a fixed 3 to 5 cut limit',
              desiredPanelCount
                ? 'respect desired_panel_count over diary length heuristics'
                : 'if diary_content_length_no_spaces is 50 or more, return at least 2 separate card-slide panels no matter what; split the diary into setup/action and emotional reaction/payoff',
              'make enough panels to show setup, action/conflict, reaction/change, and payoff when those beats exist; very short diary content may use fewer cuts',
              'never make a panel where the character only faces the camera and talks; no solo talking-head monologue panels',
              'every panel must show the character physically interacting with something: laptop, phone, food, door, desk, weather, friend, school/work object, fantasy prop, or another scene element',
              'at least half of the image_prompt must describe the environment, props, action, camera, and comic effects, not the face',
              'if the diary is introspective, externalize it visually with symbolic props, changing weather, messy desk, calendar, mirror, phone notification, RPG quest UI-like prop, or other story device',
              'compose each panel like an actual webtoon cut first: background, actor, action, props, effects, and one reserved open area for a later app-drawn speech bubble',
              'OpenAI should choose the emotional intent and write natural Korean dialogue for the Flutter app to render later',
              'the image generator must render no speech bubble and no text; no captions, hashtags, labels, pseudo-text, logos, UI badges, or any letters',
              'avoid random pseudo-text, unreadable glyphs, logos, watermarks, hashtags, labels, captions, or extra lettering in the generated image',
              'choose a natural speech_bubble_position for the later app-drawn bubble; leave enough clean visual space without asking the image model to draw a bubble',
              'speech_bubble_position must avoid the face, hands, key props, or main action when the app overlays the bubble',
              'speech_bubble_intent must describe the meaning of the dialogue in English, not copy the Korean text',
              'facial_expression must be specific enough for an illustrator, not a vague emotion word',
              'body_pose must include shoulders/hands/body direction so the image does not become a portrait',
              'preserve the same character design across every panel, but never replace the diary scene with a generic character portrait',
              'character identity is mandatory: every image_prompt must repeat concrete persona traits such as hair color, hairstyle silhouette, bangs, eye shape/color, outfit colors, accessories, and gender presentation when available',
              'if the selected art style is realistic_3d, every image_prompt must explicitly ask for a fully rendered stylized 3D animated scene with volumetric body, sculpted hair, 3D materials, cast shadows, ambient occlusion, and depth; do not describe flat 2D line art or cel-shaded illustration for realistic_3d',
              'OpenAI writes the exact final Korean line to render. dialogue should be 10-38 Korean characters when possible, with natural spacing and punctuation',
              'dialogue should feel spoken, not narrated: the character should react to what is happening in the panel rather than explain the whole diary',
              'dialogue should contain only the bubble text, without speaker labels like "나:" or quotation marks',
              'do not end dialogue with ... unless the character is genuinely hesitating or trailing off',
              'avoid stiff diary-report sentences ending in 했다/였다/이다 unless it is a calm narration panel',
              'prefer speech endings like 해야지!, 큰일인데?, 좀만 더 해보자, 이거 맞아?, 드디어 됐다!, 생각보다 빡세네',
              'good Korean dialogue examples: 오늘은 진짜 해낸다! / 어라, 왜 또 안 되지? / 이거 생각보다 빡세네 / 그래도 조금씩 된다! / 아, 이제 감 잡았어!',
              'bad Korean dialogue examples: 오늘은 앱 개발을 시작했다, 나는 매우 기뻤다, 이 장면은 공부를 의미한다, one generic word only, mixed English/Korean labels, irrelevant slogans, copied prompt metadata',
              'genre contract has exactly five user-facing moods: daily_comic=유쾌하고 웃긴 날, serious=진지하고 차분한 날, healing_romance=따뜻하고 행복한 날, growth=뿌듯하고 성취감 있는 날, hard_day=힘들고 지친 날',
              'for daily_comic, make the day bright, positive, funny, and lively; daily subtype means ordinary bright slice-of-life, gag subtype means exaggerated comic actions and playful embarrassment',
              'for serious, make the panels descriptive, restrained, heavy, and calm; inner subtype focuses on the character emotions, reflection subtype observes external causes and relationships',
              'for healing_romance, avoid gag comedy and instead make the panels warm, soft, cozy, and emotionally tender; warm_emotion subtype uses soft healing particles and special memories, youth subtype uses refreshing youth, friendship, dream, festival, water/sparkle effects',
              'for growth, make the panels preserve achievement and self-belief; growth subtype emphasizes visible personal progress and may use cute RPG-like level-up staging, passion subtype uses flame/energy effects and sustained effort',
              'for hard_day, make the panels validate tired, sad, or hurt emotions without pretending everything is happy; healing subtype gently resolves and soothes, empathy subtype stays with the sadness and amplifies honest emotional recognition',
              'for fantasy_action genre, support legacy data only by mapping it to daily_comic/growth-style cute exaggeration; do not expose it as a separate genre',
              'never create Q&A cards, reaction-only cards, image-focus cards, or meme-only cards; all panels are normal card-slide diary webtoon cuts with a concrete story beat',
              'image_prompt must not ask the image model to draw a speech bubble; it should reserve clean space for the later app-drawn bubble',
              'image_prompt must be English-only; if the diary includes words, convert them into visual actions or props',
              'use clean webtoon/card composition with one clear diary action per panel',
              'each panel must be a storyboarded webtoon cut, not a decorative standalone image',
              'each panel must include a concrete location, a visible action, at least one prop, and comic effects',
              'selected webtoon format, art style, genre, genre subtype, weather, keyword tags, and persona must all be visible or structurally reflected',
              'weather must be described as visible scene evidence: sky/window condition, rain/snow/fog/sunlight/cloud light, wet or snowy ground, clothing, props, or reflections as appropriate',
              'image_prompt must include a visible action, prop, or location from the diary content',
              'image_prompt must repeat the chosen art style in concrete visual terms: line thickness, eye shape, proportions, shading method, color contrast, texture, and what styles to avoid',
              'image_prompt must not merely say anime/comics/3D/simple; it must describe the exact rendering grammar for the selected style',
              'style tag contract: comics_ld means 사실적 스타일 LD / 극화형 Semi-Realistic, anime_ld means 사실적 스타일 LD / 애니형 Graphic, comics_sd means 단순화 스타일 SD / 캐주얼 만화형 Cartoon, simple_2d means 단순화 스타일 SD / 캐릭터형 Simple Character, realistic_3d means 입체형 스타일 3D / 입체 렌더링 3D Style',
              'for comics_ld, explicitly include Semi-Realistic 극화형; for anime_ld, explicitly include Graphic 애니형; for comics_sd, explicitly include Cartoon 캐주얼 만화형',
              'for simple_2d, explicitly describe Simple Character mascot-like simplified 2D; for realistic_3d, explicitly describe 3D Style stylized 3D rendering',
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
      dialogue: sanitizeDialogue(panel.dialogue, diary),
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
      styleLockPrompt(diary).negative,
      personaReferenceImageUrl(persona),
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
  retryFeedback?: string,
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
  const feedback = sanitizeShortText(retryFeedback ?? '');
  const retryPrompt = [
    panel.prompt ?? diary.content,
    feedback
      ? `RETRY REVISION REQUEST FROM USER: ${sanitizeImagePrompt(feedback)}. Fix this complaint strongly while preserving the diary story, selected art style, character identity, and panel continuity.`
      : 'RETRY REVISION REQUEST FROM USER: improve composition, acting, and visual clarity while preserving the diary story, selected art style, character identity, and panel continuity.',
    'This is a regenerated replacement for the same card-slide cut, not a new story beat.',
  ].join('\n');
  const persona = await loadPersona(adminClient, diary);
  const imageUrl = await generateImage(
    adminClient,
    imageContext,
    retryPrompt,
    retrySeed,
    `${diary.user_id}/diaries/${diary.id}/panel-${panel.panel_order}-retry-${panel.retry_count + 1}-${storageNonce}.png`,
    '2:3',
    stylePresetForDiary(diary),
    styleLockPrompt(diary).negative,
    personaReferenceImageUrl(persona),
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
  const styleDirective = styleLockPrompt(diary);
  const personaDirective = personaLockPrompt(persona);
  const expressionDirective = personaExpressionPrompt(persona, panel);
  const stylePriorityDirective = stylePriorityPrompt(diary.art_style);
  return [
    'IMAGE PROMPT MODE: detailed art direction paragraph, not tag soup. Follow every style and scene instruction literally.',
    stylePriorityDirective,
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
    personaReferenceImageUrl(persona)
      ? 'use the attached saved persona reference image as the strongest identity source. Reinterpret the same identity into the selected art style; if the selected style is 3D, convert the same hair color, hair silhouette, eyes, outfit, accessories, and gender presentation into a 3D character instead of copying a flat 2D rendering.'
      : null,
    styleDirective.guard,
    `STYLE AVOID LIST: ${styleDirective.negative.join(', ')}`,
    'consistent character, no speech bubble drawn by the image model, no hashtags, no UI badges, no 1 CUT label, no clock icon, no broken pseudo text, no random lettering, no watermark, no logo',
    'high readability, clean background, coherent lighting, no extra fingers',
  ].filter(Boolean).join(', ');
}

function personaReferenceImageUrl(persona: PersonaRow | null): string | null {
  return persona?.image_url ?? persona?.base_image_url ?? null;
}

function stylePriorityPrompt(artStyle: string): string {
  if (artStyle === 'realistic_3d') {
    return [
      'TOP PRIORITY STYLE: 3D STYLE RENDERING. The image must visibly be 3D, not a 2D webtoon drawing.',
      'Required visible 3D evidence: volumetric character body, sculpted hair mass, rounded 3D facial features, material surface shading, cast shadows, ambient occlusion, depth, and 3D camera lighting.',
      'Convert all webtoon/comic/panel wording into a 3D animated diary card scene. Do not draw outlines as the main look; do not use flat cel-shaded 2D illustration.',
    ].join(' ');
  }
  return 'TOP PRIORITY STYLE: preserve the selected art style exactly; do not drift into another style family.';
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
    `must-show props=${sanitizeStringList(panel.key_props, visibleKeywordTags(diary.keyword_tags)).join(' | ')}`,
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
  const panels = structured.panels.map((panel, index) => ({
    panel_type: panel.panel_type,
    scene_title: sanitizeShortText(panel.scene_title) || `컷 ${index + 1}`,
    dialogue: sanitizeDialogue(panel.dialogue, diary),
    location: sanitizeShortText(panel.location) || 'diary scene location',
    character_action: sanitizeShortText(panel.character_action) ||
      'the persona acts out the diary event',
    facial_expression: sanitizeShortText(panel.facial_expression) ||
      fallbackFacialExpression(panel.emotion),
    body_pose: sanitizeShortText(panel.body_pose) ||
      'expressive body pose that shows the diary event',
    gaze_direction: sanitizeShortText(panel.gaze_direction) ||
      'looking toward the main diary prop',
    key_props: sanitizeStringList(panel.key_props, visibleKeywordTags(diary.keyword_tags)),
    camera_shot: sanitizeShortText(panel.camera_shot) || 'vertical medium shot',
    speech_bubble_position: sanitizeBubblePosition(panel.speech_bubble_position),
    speech_bubble_shape: sanitizeBubbleShape(panel.speech_bubble_shape),
    speech_bubble_intent: sanitizeImagePrompt(panel.speech_bubble_intent) ||
      fallbackSpeechIntent(),
    comic_effects: sanitizeStringList(panel.comic_effects, ['webtoon motion lines']),
    panel_layout_notes: sanitizeImagePrompt(panel.panel_layout_notes) ||
      'keep the character, props, action, and later dialogue safe space balanced in a vertical card',
    image_prompt: sanitizeImagePrompt(panel.image_prompt),
    emotion: sanitizeShortText(panel.emotion) || 'calm',
  }));

  const normalizedPanels = normalizePanelCount(panels, diary);

  return {
    summary: structured.summary?.trim() || fallbackSummary(diary),
    emotion_tags: structured.emotion_tags?.length
      ? structured.emotion_tags.map((tag) => sanitizeShortText(tag)).filter(Boolean)
      : ['일기'],
    panels: normalizedPanels,
  };
}

function countKoreanLikeChars(value: string | null | undefined): number {
  return (value ?? '').replace(/\s+/g, '').length;
}

function visibleKeywordTags(tags: string[] | null | undefined): string[] {
  return (tags ?? []).filter((tag) => !/^__cut_count_\d+$/u.test(tag));
}

function requestedPanelCount(diary: DiaryRow): number | null {
  for (const tag of diary.keyword_tags ?? []) {
    const match = /^__cut_count_(\d+)$/u.exec(tag);
    if (!match) continue;
    const value = Number(match[1]);
    if (Number.isFinite(value)) {
      return Math.max(1, Math.min(16, Math.round(value)));
    }
  }
  return null;
}

function shouldForceAtLeastTwoPanels(diary: DiaryRow): boolean {
  return countKoreanLikeChars(diary.content) >= 50;
}

function normalizePanelCount(
  panels: StructuredPanel[],
  diary: DiaryRow,
): StructuredPanel[] {
  const requested = requestedPanelCount(diary);
  if (requested != null) {
    return fitPanelsToRequestedCount(panels, requested, diary);
  }
  return ensureMinimumPanelsForDiaryLength(panels, diary);
}

function ensureMinimumPanelsForDiaryLength(
  panels: StructuredPanel[],
  diary: DiaryRow,
): StructuredPanel[] {
  if (!shouldForceAtLeastTwoPanels(diary) || panels.length !== 1) {
    return panels;
  }

  const source = panels[0];
  return [
    {
      ...source,
      panel_type: source.panel_type === 'cover' ? 'scene' : source.panel_type,
      scene_title: source.scene_title || '상황',
      speech_bubble_position: 'center_top',
      speech_bubble_intent: source.speech_bubble_intent ||
        'setup and main action of the diary moment',
      panel_layout_notes:
        `${source.panel_layout_notes}. First of a forced two-cut sequence for a 50+ character diary: focus on setup and visible action.`,
      image_prompt:
        `${source.image_prompt} This is cut 1 of a minimum two-cut sequence for a longer diary; focus on setup, location, props, and the first visible action.`,
    },
    {
      ...source,
      panel_type: 'reaction',
      scene_title: '감정 변화',
      dialogue: sanitizeDialogue('그래도 해냈다!', diary),
      facial_expression: 'clear emotional reaction, relieved or surprised eyes, expressive eyebrows',
      body_pose: 'body reacts to the result with shoulders, hands, and posture visibly changing',
      camera_shot: 'vertical medium reaction shot with the previous prop or result still visible',
      speech_bubble_position: 'bottom_right',
      speech_bubble_shape: 'rounded_speech_bubble',
      speech_bubble_intent: 'emotional reaction or payoff after the diary action',
      comic_effects: ['sparkle', 'sweat drop', 'small motion line'],
      panel_layout_notes:
        'Second of a forced two-cut sequence for a 50+ character diary: show the emotional reaction or payoff, keep props and result visible, reserve clean bubble space.',
      image_prompt:
        `${source.image_prompt} This is cut 2 of a minimum two-cut sequence for a longer diary; change the composition into a payoff or emotional reaction scene, with the result of the diary action visible, different camera framing, stronger facial emotion, and clear body language. Do not repeat the first cut composition.`,
      emotion: source.emotion || 'relieved',
    },
  ];
}

function fitPanelsToRequestedCount(
  panels: StructuredPanel[],
  requested: number,
  diary: DiaryRow,
): StructuredPanel[] {
  if (panels.length >= requested) {
    return panels.slice(0, requested).map((panel, index) => ({
      ...panel,
      scene_title: panel.scene_title || `컷 ${index + 1}`,
      image_prompt: `${panel.image_prompt} This is cut ${index + 1} of exactly ${requested}; keep the sequence progression clear and do not merge multiple cuts into one image.`,
    }));
  }

  const result = [...panels];
  const source = panels[panels.length - 1] ?? fallbackStructuredPanel(diary);
  while (result.length < requested) {
    const index = result.length;
    result.push({
      ...source,
      panel_type: index === requested - 1 ? 'reaction' : 'scene',
      scene_title: `컷 ${index + 1}`,
      dialogue: sanitizeDialogue(index === requested - 1 ? '드디어 됐다!' : '조금만 더 해보자!', diary),
      camera_shot: index % 2 === 0
        ? 'vertical medium shot with clear props'
        : 'vertical close medium shot with changed angle',
      panel_layout_notes:
        `${source.panel_layout_notes}. Extra requested cut ${index + 1} of exactly ${requested}: use a different composition and story beat from the previous cut.`,
      image_prompt:
        `${source.image_prompt} This is extra requested cut ${index + 1} of exactly ${requested}; change the pose, camera angle, emotional beat, and visible props so it does not repeat earlier cuts.`,
    });
  }
  return result;
}

function fallbackStructuredPanel(diary: DiaryRow): StructuredPanel {
  return {
    panel_type: 'scene',
    scene_title: '일기 장면',
    dialogue: sanitizeDialogue(fallbackSummary(diary), diary),
    location: inferFallbackLocation(diary),
    character_action: 'the persona acts out the diary moment with visible props',
    facial_expression: 'focused expressive face',
    body_pose: 'medium shot with hands and shoulders visible',
    gaze_direction: 'looking toward the main diary prop',
    key_props: inferFallbackProps(diary),
    camera_shot: 'vertical medium shot',
    speech_bubble_position: 'upper_left',
    speech_bubble_shape: 'rounded_speech_bubble',
    speech_bubble_intent: fallbackSpeechIntent(),
    comic_effects: ['webtoon motion lines'],
    panel_layout_notes: 'balanced vertical card with clean upper speech bubble space',
    image_prompt: 'A finished Korean diary webtoon scene cut with one clear daily action, visible environment, props, expressive character acting, and clean upper speech bubble space. No text or speech bubble rendered.',
    emotion: 'calm',
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
): string {
  const cleaned = sanitizeShortText(value ?? '')
    .replace(/^(나|내|캐릭터|주인공|질문|답변|대사)\s*[:：]\s*/u, '')
    .replace(/^["'“”‘’]+|["'“”‘’]+$/gu, '')
    .trim();

  if (cleaned) {
    return compactKoreanDialogue(cleaned);
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

function fallbackSpeechIntent(): string {
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
  const displayTags = visibleKeywordTags(diary.keyword_tags);
  const tags = displayTags.length
    ? `keyword tags that must affect the visible scene: ${
      displayTags.map((tag) => `#${tag}`).join(', ')
    }; `
    : '';
  const content = diary.content.replace(/\s+/g, ' ').trim();
  const clipped = content.length > 700 ? `${content.slice(0, 700)}...` : content;
  return `${title}${tags}diary event to illustrate, not to write as text: ${clipped}`;
}

function mediumGuardPrompt(artStyle: string): string {
  if (artStyle === 'realistic_3d') {
    return 'full stylized 3D rendered diary scene, volumetric character, rounded sculpted forms, 3D lighting and materials, not flat 2D line art';
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

function styleLockPrompt(diary: DiaryRow): {
  positive: string;
  detail: string;
  guard: string;
  negative: string[];
} {
  const style = diary.art_style;
  const subStyle = diary.art_sub_style;
  const subtype = subStyle ? ` Selected sub-style tag: ${subStyle}.` : '';
  const templatePrompt = sanitizeImagePrompt(diary.style_template_prompt);
  if (templatePrompt) {
    const baseNegative = style === 'realistic_3d'
      ? [
        'flat anime',
        '2D illustration',
        'line art',
        'cel shading',
        'manga',
        'comic ink',
        'webtoon line art',
        'photorealistic human',
      ]
      : [
        'photorealistic live action',
        'unrelated style',
        'different rendering style',
        'generic AI illustration',
      ];
    return {
      positive:
        `STYLE TEMPLATE LOCK - MUST FOLLOW THIS TEMPLATE EXACTLY: ${templatePrompt}.${subtype}`,
      detail:
        `The selected style template is the only source of art direction: ${templatePrompt}. Apply it to every panel consistently, including linework, proportions, shading, color, lighting, material, and composition.`,
      guard:
        'Do not reinterpret the template as a loose tag. The template overrides all older art-style tags and generic webtoon wording. Keep character identity, but render it strictly in this template.',
      negative: baseNegative,
    };
  }
  switch (style) {
    case 'anime_ld':
      return {
        positive:
          `GRAPHIC ANIMATION LD ONLY, 애니형 Graphic: polished anime/graphic webtoon drawing, clean stylized linework, expressive eyes, crisp cel shading, readable diary webtoon acting, not semi-realistic and not cartoon SD.${subtype}`,
        detail:
          'Use 애니형 Graphic grammar: clean graphic line art, expressive animated eyes, simplified nose and mouth, smooth hair clumps, crisp cel shading, controlled color blocks, and clear animated panel acting. Keep it emotional and readable as a diary webtoon scene, not gritty semi-realism or a casual cartoon gag.',
        guard:
          'Keep the final image 애니형 Graphic LD style only. Do not use 극화형 semi-realistic ink, 캐주얼 만화형 Cartoon, Simple Character mascot, 3D render, realistic drama portrait, or oil painting.',
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
          `CARTOON SD ONLY, 캐주얼 만화형 Cartoon: cute simplified proportions, small body big emotion, reaction-friendly cartoon acting, soft flat colors.${subtype}`,
        detail:
          'Use 캐주얼 만화형 Cartoon grammar: simplified proportions, rounded hands, expressive eyes, simplified mouth, reaction stickers, and compact vertical card composition. The scene must be a diary webtoon reaction cut with clear props and action, not a normal portrait.',
        guard:
          'Keep the final image 캐주얼 만화형 Cartoon SD only. Do not use realistic anatomy, 극화형 Semi-Realistic, 애니형 Graphic LD, 3D render, Simple Character mascot, or mature LD proportions.',
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
          `SEMI-REALISTIC LD ONLY, 극화형 Semi-Realistic: dramatic realistic-but-stylized webtoon rendering, firm ink outlines, believable anatomy, high contrast shadows, serious dramatic panel energy, expressive comic effects.${subtype}`,
        detail:
          'Use 극화형 Semi-Realistic grammar: firm contour lines, believable face planes, stylized but realistic anatomy, strong light-dark contrast, dynamic hands and shoulders, speed lines, impact marks, and a bold single-panel frame. Keep the diary event visible; do not turn it into a generic handsome portrait.',
        guard:
          'Keep the final image 극화형 Semi-Realistic LD only. Do not use 애니형 Graphic, 캐주얼 만화형 Cartoon, Simple Character mascot, 3D render, moe eyes, or soft romance webtoon rendering.',
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
          `CARTOON SD ONLY, 캐주얼 만화형 Cartoon: playful cartoon character, friendly outline, bouncy shapes, exaggerated goofy expression, bright flat colors, funny deformation, comic-strip gag timing.${subtype}`,
        detail:
          'Use 캐주얼 만화형 Cartoon grammar: friendly outlines, bouncy simplified shapes, compact cute body, exaggerated mouth and eyebrows, rubbery pose, bright flat color blocks, playful impact marks, sweat drops, stars, and comic timing. It should feel like a casual cartoon diary card with one clear action, not anime sparkle-face rendering.',
        guard:
          'Keep the final image 캐주얼 만화형 Cartoon SD only. Do not use 애니형 Graphic, 극화형 Semi-Realistic, realistic portrait, 3D render, or polished romance webtoon face.',
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
          `MANDATORY 3D STYLE RENDERING ONLY, 입체 렌더링 3D Style: the final image must look like a fully rendered stylized 3D animated scene, with volumetric character body, rounded sculpted hair, 3D materials, ambient occlusion, depth, shadows, and cinematic daily-scene lighting. No flat 2D drawing.${subtype}`,
        detail:
          'Use 입체 렌더링 3D Style grammar: actual 3D-rendered look, soft rounded volumes, appealing stylized proportions, simple expressive eyes built as 3D shapes, sculpted hair clumps, visible material surfaces, gentle ambient occlusion, cast shadows, depth of field, cinematic but cute lighting, and a cozy miniature diary environment. The pose and props must show the diary event. Do not drift into flat anime, 2D webtoon line art, comic ink, photorealistic human portrait, or glossy fashion render.',
        guard:
          'HARD STYLE OVERRIDE: if any other instruction says webtoon, comic, line art, cel shading, manga, cartoon, or illustration, reinterpret it as a 3D animated diary card scene. Keep the final image 입체 렌더링 3D Style only. No flat anime, no semi-realistic comic ink, no cartoon 2D, no Simple Character flat mascot, no line-art webtoon, no hand-drawn cel shading, and no realistic human photography.',
        negative: [
          'flat anime',
          '2D illustration',
          'line art',
          'cel shading',
          'hand drawn',
          'manga',
          'comic book ink',
          'webtoon line art',
          'cartoon 2D',
          'flat colors',
          'photorealistic human',
          'live action',
          'real person',
        ],
      };
    case 'simple_2d':
      return {
        positive:
          `SIMPLE CHARACTER SD ONLY, 캐릭터형 Simple Character: heavily simplified mascot-like 2D character, minimal facial features, flat pastel colors, simple rounded shapes, clear icon-like silhouette.${subtype}`,
        detail:
          'Use 캐릭터형 Simple Character grammar: very simplified rounded body, iconic silhouette, minimal nose and mouth, simple dot or oval eyes, clean outlines, flat pastel fills, few details, readable props, and calm negative space. The image should look like a cute simple character diary card, not anime illustration, western comic page, 3D render, or realistic portrait.',
        guard:
          'Keep the final image 캐릭터형 Simple Character SD only. Do not use 애니형 Graphic, 극화형 Semi-Realistic, 캐주얼 만화형 Cartoon, realistic portrait, or 3D render.',
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
    'Before drawing, audit the character identity: hair color, hairstyle silhouette, bangs, hair length, eye shape/color, face shape, outfit colors, accessories, age impression, and gender presentation must match this persona.',
    'Repeat those identity cues on the actor in every panel even when the pose, camera angle, or art style changes.',
    'Apply this identity to the actor in the diary scene, but keep the selected art style above. Do not invent a different hairstyle, hair color, eye color, outfit, age, body type, or gender presentation.',
    'If style and identity seem to conflict, preserve identity traits first, then render those same traits in the selected art style.',
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
    webtoon_format: 'card_slide',
    webtoon_format_prompt: webtoonFormatPrompt(),
    style_template_id: diary.style_template_id,
    style_template_prompt: diary.style_template_prompt,
    art_style: diary.art_style,
    art_sub_style: diary.art_sub_style,
    art_style_prompt: artStylePrompt(diary),
    genre: diary.genre,
    genre_prompt: genrePrompt(diary.genre),
    genre_subtype: diary.genre_subtype,
    genre_subtype_prompt: genreSubtypePrompt(diary.genre_subtype),
    weather: diary.weather,
    weather_prompt: weatherPrompt(diary.weather),
    keyword_tags: visibleKeywordTags(diary.keyword_tags),
    keyword_prompt: keywordPrompt(visibleKeywordTags(diary.keyword_tags)),
  };
}

function webtoonFormatPrompt(): string {
  return 'story webtoon card slide only: one vertical comic panel per generated image, swipeable sequence, clear scene progression, no Q&A format, no reaction-only meme format, no image-focus poster format';
}

function artStylePrompt(diary: DiaryRow): string {
  const style = diary.art_style;
  const subStyle = diary.art_sub_style;
  const templatePrompt = sanitizeImagePrompt(diary.style_template_prompt);
  const subtype = subStyle ? `, selected template/sub-style: ${subStyle}` : '';
  if (templatePrompt) {
    return `DB style template locked${subtype}: ${templatePrompt}. This template replaces all user-facing art tags; follow it exactly in every generated panel.`;
  }
  switch (style) {
    case 'comics_ld':
      return `사실적 스타일 LD / 극화형 Semi-Realistic diary webtoon style${subtype}: believable stylized anatomy, firm lines, strong contrast, dramatic semi-realistic rendering, dynamic pose, but still a readable diary webtoon card`;
    case 'comics_sd':
      return `단순화 스타일 SD / 캐주얼 만화형 Cartoon diary webtoon style${subtype}: compact cute proportions, bouncy colors, playful deformation, exaggerated comedy expressions, comic-strip gag drama in simplified cartoon form`;
    case 'anime_ld':
      return `사실적 스타일 LD / 애니형 Graphic diary webtoon style${subtype}: clean graphic linework, expressive animated eyes, crisp cel shading, readable animated panel acting`;
    case 'anime_sd':
      return `단순화 스타일 SD / 캐주얼 만화형 Cartoon diary webtoon style${subtype}: cute simplified proportions, small body big emotion, reaction-friendly`;
    case 'realistic_3d':
      return `입체형 스타일 3D / 입체 렌더링 3D Style diary webtoon style${subtype}: stylized 3D volume, rounded forms, cinematic daily animation mood, not photorealistic`;
    case 'simple_2d':
      return `단순화 스타일 SD / 캐릭터형 Simple Character diary webtoon style${subtype}: simplified mascot-like character, clean outlines, flat pastel colors, iconic readable silhouette`;
    default:
      return `selected art style ${style}${subtype}: keep this style dominant in every panel`;
  }
}

function genrePrompt(value: string): string {
  switch (value) {
    case 'daily_comic':
      return '유쾌하고 웃긴 날 genre: bright and positive diary cuts, funny lively mood, playful comic timing, cheerful effects, friendly everyday humor';
    case 'serious':
      return '진지하고 차분한 날 genre: descriptive serious diary cuts, restrained colors, calm heavy atmosphere, clear emotional weight without forced happiness';
    case 'fantasy_action':
      return 'legacy fantasy_action genre: map it to cute daily-comic or growth exaggeration, readable diary webtoon staging, not a separate epic fantasy illustration';
    case 'healing_romance':
      return '따뜻하고 행복한 날 genre: warm cozy emotion, soft healing mood, tender memories, gentle positive feeling, not gag comedy';
    case 'growth':
      return '뿌듯하고 성취감 있는 날 genre: achievement preserved as motivation, visible effort and progress, confidence, pride, renewed passion';
    case 'hard_day':
      return '힘들고 지친 날 genre: tired, sad, hurt, or exhausted emotions are acknowledged honestly; comforting or empathetic diary cuts, no forced cheerfulness';
    default:
      return `selected genre ${value}: make the scene follow this genre strongly`;
  }
}

function genreSubtypePrompt(value: string | null): string | null {
  if (!value) {
    return null;
  }

  switch (value) {
    case 'daily':
    case 'daily_sitcom':
      return '일상 subtype: ordinary slice-of-life diary staging, bright but natural mood, simple daily events and small positive moments';
    case 'gag':
    case 'gag_action':
      return '개그 subtype: humorous exaggerated acting, playful embarrassment, funny conversation timing, expressive comic effects';
    case 'inner':
    case 'inner_monologue':
      return '내면 subtype: focus on the character inner feelings from the diary body, heavier emotional narration externalized visually';
    case 'reflection':
    case 'fact_observation':
      return '성찰 subtype: observe external causes, relationships, mistakes, conflict, and why the difficulty happened with calm distance';
    case 'warm_emotion':
      return '감성 subtype: warm special anecdote, cozy healing circles or soft particles, sentimental tender memory, gentle positive image';
    case 'youth_emotion':
    case 'youth':
      return '청춘 subtype: refreshing youth mood, friendship and dreams, festival or school energy, splashing water or clear blue effects when appropriate';
    case 'growth':
      return '성장 subtype: personal progress and achievement, proud positive staging, possible cute RPG-like level-up effects';
    case 'passion':
    case 'hot_blooded':
      return '열정 subtype: flame or energy effects, effort poured into a goal, motivational intensity that the user can return to later';
    case 'healing':
      return '치유 subtype: gently soothe negative emotion, healing light and soft recovery effects, comfort after loss or exhaustion';
    case 'empathy':
      return '공감 subtype: do not rush to heal; validate the sadness or hurt honestly, deepen the mood so the user feels understood';
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
    case 'daily_healing':
      return 'daily healing subtype: peaceful silence, cozy food steam, soft empty space, calm domestic detail';
    default:
      return `selected genre subtype ${value}: reflect this subtype clearly`;
  }
}

function weatherPrompt(value: string): string {
  switch (value) {
    case 'sunny':
      return 'sunny weather directive: visibly show bright daylight, warm sun highlights, crisp outdoor or window light, and cheerful clear-sky atmosphere in the panel';
    case 'cloudy':
      return 'cloudy weather directive: visibly show overcast sky or muted window light, soft diffused shadows, gray-blue ambient color, and calm cloudy atmosphere';
    case 'rainy':
      return 'rainy weather directive: visibly show rain streaks, wet reflections, umbrella/window droplets or puddles, damp cool lighting, and cozy melancholy mood';
    case 'snowy':
      return 'snowy weather directive: visibly show falling snowflakes or accumulated snow, cold white-blue lighting, winter clothing or frosty window detail, and quiet winter atmosphere';
    case 'foggy':
      return 'foggy weather directive: visibly show mist, hazy depth, softened silhouettes, low-contrast background, and dreamy foggy atmosphere';
    default:
      return `weather directive ${value}: make this weather visibly affect lighting, background, props, and mood in every panel`;
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
  referenceImageUrl?: string | null,
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
      referenceImageUrl,
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
  referenceImageUrl?: string | null,
): Promise<string> {
  const model = Deno.env.get('GEMINI_IMAGE_MODEL') ?? 'gemini-2.5-flash-image';
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
  const referencePart = referenceImageUrl
    ? await buildReferenceImagePart(adminClient, referenceImageUrl)
    : null;
  const geminiPrompt = [
    '아래 지시를 바탕으로 한국어 웹툰 카드 한 컷을 완성해줘.',
    '구글 Gemini에서 자연어로 이미지 만들라고 입력하는 것처럼 처리해줘. 너무 기술적인 포스터나 초상화가 아니라, 실제 일기 웹툰의 한 장면이어야 해.',
    referencePart
      ? '첨부된 캐릭터 이미지는 정체성 기준이야. 같은 캐릭터로 재해석하되 포즈와 상황은 컷 지시에 맞게 바꿔줘. 머리색, 머리 실루엣, 앞머리, 눈, 의상색, 액세서리, 성별 표현은 바꾸지 마.'
      : null,
    referencePart
      ? '선택 스타일이 3D라면 첨부 이미지를 그대로 복사하지 말고, 동일 캐릭터 특징을 입체 렌더링 캐릭터로 변환해줘.'
      : null,
    '만약 지시에 "3D STYLE RENDERING", "입체 렌더링", "realistic_3d"가 있으면 결과물은 반드시 입체적인 3D 애니메이션 렌더처럼 보여야 해. 평면 2D 선화, 만화 잉크, 셀채색 일러스트로 만들지 마.',
    '캐릭터 외형 지시가 있으면 머리색, 머리 실루엣, 앞머리, 눈 모양/색, 의상색, 액세서리, 성별 표현을 장면 속 캐릭터에 반드시 유지해줘.',
    '한 화면에 하나의 컷만 있고, 컷 안에는 배경, 캐릭터의 행동, 소품, 감정 연출, 효과선이 자연스럽게 들어가야 해.',
    '중요: 말풍선과 글자는 절대 그리지 마. 한국어, 영어, 해시태그, UI 배지, 로고, 워터마크, 가짜 글자, 깨진 글자는 전부 금지야.',
    '대신 나중에 앱이 말풍선을 그릴 수 있도록 얼굴, 손, 핵심 소품을 가리지 않는 깨끗한 여백을 하나 남겨줘.',
    '선택된 그림체와 캐릭터 외형은 유지하고, 일기 내용과 태그가 장면에 보이게 반영해줘.',
    '아래는 OpenAI가 일기와 태그를 분석해서 정리한 컷 지시야. 그대로 따라줘:',
    prompt,
  ].filter(Boolean).join('\n');

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
          parts: [
            { text: geminiPrompt },
            ...(referencePart ? [referencePart] : []),
          ],
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

async function loadReferenceImageData(
  adminClient: ReturnType<typeof createClient>,
  referenceImageUrl: string,
): Promise<{ mimeType: string; base64: string; bytes: Uint8Array } | null> {
  try {
    let mimeType = 'image/png';
    let bytes: Uint8Array | null = null;

    const storagePath = diaryAssetPathFromPublicUrl(referenceImageUrl);
    if (storagePath) {
      const { data, error } = await adminClient.storage
        .from('diary-assets')
        .download(storagePath);
      if (!error && data) {
        mimeType = data.type || mimeType;
        bytes = new Uint8Array(await data.arrayBuffer());
      }
    }

    if (!bytes) {
      const response = await fetch(referenceImageUrl, {
        signal: AbortSignal.timeout(20_000),
      });
      if (!response.ok) {
        return null;
      }
      mimeType =
        response.headers.get('content-type')?.split(';')[0] ?? mimeType;
      bytes = new Uint8Array(await response.arrayBuffer());
    }

    mimeType = normalizeSupportedImageMimeType(mimeType, bytes, referenceImageUrl);
    if (!mimeType) {
      return null;
    }

    return {
      mimeType,
      base64: uint8ToBase64(bytes),
      bytes,
    };
  } catch (_) {
    return null;
  }
}

function normalizeSupportedImageMimeType(
  mimeType: string,
  bytes: Uint8Array,
  sourceUrl: string,
): string | null {
  const normalized = mimeType.toLowerCase().split(';')[0].trim();
  if (
    normalized === 'image/jpeg' ||
    normalized === 'image/png' ||
    normalized === 'image/gif' ||
    normalized === 'image/webp'
  ) {
    return normalized;
  }

  const detected = detectSupportedImageMimeType(bytes);
  if (detected) {
    return detected;
  }

  const lowerUrl = sourceUrl.toLowerCase().split('?')[0];
  if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lowerUrl.endsWith('.png')) {
    return 'image/png';
  }
  if (lowerUrl.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lowerUrl.endsWith('.webp')) {
    return 'image/webp';
  }
  return null;
}

function detectSupportedImageMimeType(bytes: Uint8Array): string | null {
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47
  ) {
    return 'image/png';
  }
  if (bytes.length >= 6) {
    const header = String.fromCharCode(...bytes.slice(0, 6));
    if (header === 'GIF87a' || header === 'GIF89a') {
      return 'image/gif';
    }
  }
  if (bytes.length >= 12) {
    const riff = String.fromCharCode(...bytes.slice(0, 4));
    const webp = String.fromCharCode(...bytes.slice(8, 12));
    if (riff === 'RIFF' && webp === 'WEBP') {
      return 'image/webp';
    }
  }
  return null;
}

async function buildReferenceImagePart(
  adminClient: ReturnType<typeof createClient>,
  referenceImageUrl: string,
): Promise<Record<string, unknown> | null> {
  const referenceData = await loadReferenceImageData(
    adminClient,
    referenceImageUrl,
  );
  if (!referenceData) {
    return null;
  }

  return {
    inline_data: {
      mime_type: referenceData.mimeType,
      data: referenceData.base64,
    },
  };
}

function diaryAssetPathFromPublicUrl(url: string): string | null {
  const marker = '/storage/v1/object/public/diary-assets/';
  const index = url.indexOf(marker);
  if (index < 0) {
    return null;
  }
  return decodeURIComponent(url.slice(index + marker.length).split('?')[0]);
}

function uint8ToBase64(bytes: Uint8Array): string {
  let binary = '';
  const chunkSize = 0x8000;
  for (let index = 0; index < bytes.length; index += chunkSize) {
    const chunk = bytes.subarray(index, index + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
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

