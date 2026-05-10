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

type GeneratePersonaImagePayload = {
  persona_id: string;
  force_regenerate?: boolean;
};

type PersonaRow = {
  id: string;
  user_id: string;
  name: string;
  input_mode: string;
  appearance_desc: string;
  appearance_tags: Record<string, unknown>;
  default_seed: number;
  default_art_style: string;
  default_genre: string;
  generation_status: string;
  image_url: string | null;
  base_image_url: string | null;
};

type PersonaPromptResult = {
  image_prompt: string;
  expression_library: Record<string, string>;
};

type ImageGenerationContext = {
  provider: 'stability' | 'gemini';
  stabilityApiKey?: string;
  geminiApiKey?: string;
};

const personaPromptSchema = {
  name: 'persona_prompt_result',
  schema: {
    type: 'object',
    additionalProperties: false,
    required: ['image_prompt', 'expression_library'],
    properties: {
      image_prompt: {
        type: 'string',
        minLength: 220,
        description:
          'English-only Stability AI prompt. Write 220-500 characters with clear character identity, hair, eyes, outfit, personality, linework, shading, and color palette. Keep it simple and stable.',
      },
      expression_library: {
        type: 'object',
        additionalProperties: false,
        required: ['happy', 'sad', 'angry', 'embarrassed', 'calm'],
        properties: {
          happy: { type: 'string' },
          sad: { type: 'string' },
          angry: { type: 'string' },
          embarrassed: { type: 'string' },
          calm: { type: 'string' },
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

  const payload = await safeJson<GeneratePersonaImagePayload>(request);
  if (!payload?.persona_id) {
    return jsonResponse({ error: 'persona_id is required.' }, 400);
  }

  const { data: persona, error: personaError } = await adminClient
    .from('personas')
    .select('id, user_id, name, input_mode, appearance_desc, appearance_tags, default_seed, default_art_style, default_genre, generation_status, image_url, base_image_url')
    .eq('id', payload.persona_id)
    .eq('user_id', userData.user.id)
    .single<PersonaRow>();

  if (personaError || !persona) {
    return jsonResponse({ error: 'Character was not found.' }, 404);
  }

  const existingImageUrl = persona.image_url ?? persona.base_image_url;
  if (
    persona.generation_status === 'completed' &&
    existingImageUrl &&
    payload.force_regenerate !== true
  ) {
    return jsonResponse({
      message: 'Persona image already exists.',
      persona_id: persona.id,
      image_url: existingImageUrl,
    }, 200);
  }

  await adminClient
    .from('personas')
    .update({ generation_status: 'processing', error_message: null })
    .eq('id', persona.id);

  try {
    const promptResult = await writePersonaPromptWithFallback(
      openAiPromptDisabled ? undefined : openAiApiKey,
      persona,
    );
    const imageUrl = await generateImage(
      adminClient,
      {
        provider: imageProvider === 'gemini' ? 'gemini' : 'stability',
        stabilityApiKey,
        geminiApiKey,
      },
      promptResult.image_prompt,
      persona.default_seed,
      `${persona.user_id}/personas/${persona.id}.png`,
      '2:3',
    );

    const { error: updateError } = await adminClient
      .from('personas')
      .update({
        appearance_desc: promptResult.image_prompt,
        image_url: imageUrl,
        base_image_url: imageUrl,
        expression_library: promptResult.expression_library,
        generation_status: 'completed',
        error_message: null,
      })
      .eq('id', persona.id);

    if (updateError) {
      throw updateError;
    }

    return jsonResponse({ persona_id: persona.id, image_url: imageUrl }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    await adminClient
      .from('personas')
      .update({ generation_status: 'failed', error_message: message })
      .eq('id', persona.id);

    return jsonResponse({ error: message }, 500);
  }
});

async function writePersonaPromptWithFallback(
  apiKey: string | undefined,
  persona: PersonaRow,
): Promise<PersonaPromptResult> {
  if (!apiKey) {
    return fallbackPersonaPrompt(persona);
  }

  try {
    return await writePersonaPrompt(apiKey, persona);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (
      message.includes('insufficient_quota') ||
      message.toLowerCase().includes('quota') ||
      message.toLowerCase().includes('billing')
    ) {
      return fallbackPersonaPrompt(persona);
    }
    throw error;
  }
}

function fallbackPersonaPrompt(persona: PersonaRow): PersonaPromptResult {
  const tagText = flattenTags(persona.appearance_tags).join(', ');
  const base = [
    `Reusable Korean diary webtoon character named ${persona.name}.`,
    persona.appearance_desc,
    tagText ? `Selected appearance tags: ${tagText}.` : null,
    'Exactly one character only, centered half-body or full-body, clean silhouette, readable hairstyle, eye color, outfit, and personality.',
    'Rounded webtoon/anime character design, pastel colors, clean line art, soft cel shading, simple soft background, no text, no model sheet, no grid, no multiple variations.',
  ].filter(Boolean).join(' ');

  return {
    image_prompt: base,
    expression_library: {
      happy: 'bright smiling face with lively eyes',
      sad: 'teary sad face with lowered eyebrows',
      angry: 'pouting angry face with sharp eyebrows',
      embarrassed: 'flustered sweaty face with blush',
      calm: 'calm neutral face with relaxed eyes',
    },
  };
}

function flattenTags(value: Record<string, unknown> | null): string[] {
  if (!value) {
    return [];
  }

  return Object.values(value)
    .flatMap((item) => Array.isArray(item) ? item : [item])
    .map((item) => String(item).trim())
    .filter((item) => item.length > 0)
    .slice(0, 16);
}

async function writePersonaPrompt(
  apiKey: string,
  persona: PersonaRow,
): Promise<PersonaPromptResult> {
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
            'You are an image prompt director for a webtoon character. Return only JSON that follows the schema. Write a clear, simple English prompt optimized for Stability AI and a Korean expression library. The image must show exactly one character only, never a reference sheet, never a grid, never multiple variations.',
        },
        {
          role: 'user',
          content: JSON.stringify({
            name: persona.name,
            input_mode: persona.input_mode,
            appearance_desc: persona.appearance_desc,
            appearance_tags: persona.appearance_tags,
            default_art_style: persona.default_art_style,
            default_genre: persona.default_genre,
            requirements: [
              'exactly one single character only',
              'one finished 2D webtoon character portrait or full-body image',
              'centered character, simple clean background',
              'never make a character sheet, model sheet, reference sheet, lineup, collage, contact sheet, or multiple portraits',
              'clean silhouette and readable face',
              'soft pastel palette, not monochrome',
              'no text, no watermark, no logo',
              'details must be reusable for later diary panels',
              'write one compact art direction paragraph, not a long instruction sheet',
              'describe hair shape, hair color, eye color, eye highlight, face shape, skin tone, outfit top/bottom, personality, expression baseline, linework, shading, palette, and silhouette',
              'avoid model sheet, reference sheet, grid, collage, multiple portrait variations, photorealistic portrait, and generic pretty character',
            ],
          }),
        },
      ],
      text: {
        format: {
          type: 'json_schema',
          ...personaPromptSchema,
        },
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`GPT prompt generation failed: ${await response.text()}`);
  }

  return JSON.parse(extractOutputText(await response.json())) as PersonaPromptResult;
}

async function generateImage(
  adminClient: ReturnType<typeof createClient>,
  imageContext: ImageGenerationContext,
  prompt: string,
  seed: number,
  storagePath: string,
  aspectRatio: string,
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
    'Create exactly one reusable Korean diary webtoon character image for later comic panels.',
    'Show one main character only, centered half-body or full-body, clean silhouette, expressive face, simple soft background.',
    'The character must clearly preserve the requested hair, eyes, skin tone, outfit, personality, and silhouette.',
    'Use rounded webtoon/anime character design, pastel colors, clean line art, soft cel shading, warm and friendly mood.',
    'Do not create a model sheet, reference sheet, grid, collage, lineup, multiple portraits, multiple outfits, or multiple variations.',
    'Do not draw readable text, watermark, logo, UI, or captions.',
    'Follow this character brief exactly:',
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

async function generateStabilityImage(
  adminClient: ReturnType<typeof createClient>,
  apiKey: string,
  prompt: string,
  seed: number,
  storagePath: string,
  aspectRatio: string,
): Promise<string> {
  const endpoint = Deno.env.get('STABILITY_IMAGE_ENDPOINT') ??
    'https://api.stability.ai/v2beta/stable-image/generate/core';
  const formData = new FormData();
  formData.append('prompt', buildPersonaStabilityPrompt(prompt));
  formData.append('seed', seed.toString());
  formData.append('aspect_ratio', aspectRatio);
  formData.append('output_format', 'png');
  formData.append(
    'negative_prompt',
    [
      'text',
      'watermark',
      'logo',
      'signature',
      'blurry',
      'distorted face',
      'extra fingers',
      'multiple people',
      'multiple characters',
      'duplicated person',
      'character sheet',
      'reference sheet',
      'model sheet',
      'lineup',
      'collage',
      'grid',
      'contact sheet',
      'portrait grid',
      'split screen',
      'variations',
      'corporate headshot',
      'photorealistic portrait',
    ].join(', '),
  );

  const response = await fetch(endpoint, {
    method: 'POST',
    signal: AbortSignal.timeout(90_000),
    headers: {
      authorization: `Bearer ${apiKey}`,
      accept: 'application/json',
    },
    body: formData,
  });

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

function buildPersonaStabilityPrompt(prompt: string): string {
  return [
    'Create one clean reusable Korean diary webtoon character image.',
    'Single character only, centered half-body or full-body, simple soft background, clean silhouette.',
    'Cute webtoon design, clean line art, pastel colors, soft cel shading, readable hairstyle, outfit, and eyes.',
    'No reference sheet, no model sheet, no grid, no collage, no multiple variations, no text.',
    'Character brief:',
    prompt,
  ].join('\n');
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

async function safeJson<T>(request: Request): Promise<T | null> {
  try {
    return await request.json() as T;
  } catch (_) {
    return null;
  }
}
