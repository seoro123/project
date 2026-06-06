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
  retry_feedback?: string;
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
        minLength: 360,
        description:
          'English-only image prompt. Write 500-1200 characters with clear character identity, subject species/type, body shape, fur/hair color, silhouette, face shape, eye shape, markings, accessories or outfit only if visible, personality, linework, shading, and color palette. If a reference image is provided, analyze it visually first and translate only safe non-identifying visual traits into a reusable webtoon character design. If the reference subject is an animal such as a cat, keep it as that animal; do not turn it into a human or humanoid unless the user explicitly asks.',
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
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  const openAiPromptDisabled =
    Deno.env.get('OPENAI_PROMPT_DISABLED')?.toLowerCase() === 'true';

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse({ error: 'Missing Supabase environment variables.' }, 500);
  }

  if (!openAiApiKey) {
    return jsonResponse({ error: 'Missing OPENAI_API_KEY.' }, 500);
  }

  if (!geminiApiKey) {
    return jsonResponse({ error: 'Missing GEMINI_API_KEY.' }, 500);
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
    const promptApiKey = persona.base_image_url
      ? openAiApiKey
      : openAiPromptDisabled
      ? undefined
      : openAiApiKey;
    const promptResult = await writePersonaPromptWithFallback(
      adminClient,
      promptApiKey,
      persona,
      payload.retry_feedback,
    );
    const imagePrompt = persona.base_image_url
      ? buildReferenceFirstImagePrompt(persona, promptResult.image_prompt)
      : promptResult.image_prompt;
    const imageUrl = await generateImage(
      adminClient,
      {
        geminiApiKey,
      },
      imagePrompt,
      `${persona.user_id}/personas/${persona.id}-${Date.now()}.png`,
      '2:3',
      persona.base_image_url,
    );

    const { error: updateError } = await adminClient
      .from('personas')
      .update({
        appearance_desc: imagePrompt,
        image_url: imageUrl,
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
  adminClient: ReturnType<typeof createClient>,
  apiKey: string | undefined,
  persona: PersonaRow,
  retryFeedback?: string,
): Promise<PersonaPromptResult> {
  if (!apiKey) {
    return fallbackPersonaPrompt(persona, retryFeedback);
  }

  try {
    return await writePersonaPrompt(adminClient, apiKey, persona, retryFeedback);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const lower = message.toLowerCase();
    if (
      persona.base_image_url &&
      (lower.includes('valid image') ||
        lower.includes('invalid_value') ||
        lower.includes('unsupported image') ||
        lower.includes('image data') ||
        lower.includes('could not find json text') ||
        lower.includes('could not find json') ||
        lower.includes('json text'))
    ) {
      return fallbackPersonaPrompt(persona, retryFeedback);
    }
    if (persona.base_image_url) {
      throw error;
    }
    if (
      message.includes('insufficient_quota') ||
      lower.includes('quota') ||
      lower.includes('billing')
    ) {
      return fallbackPersonaPrompt(persona, retryFeedback);
    }
    throw error;
  }
}

function fallbackPersonaPrompt(
  persona: PersonaRow,
  retryFeedback?: string,
): PersonaPromptResult {
  const tagText = flattenTags(persona.appearance_tags).join(', ');
  const feedback = String(retryFeedback ?? '').trim();
  const base = [
    `Reusable Korean diary webtoon character named ${persona.name}.`,
    persona.appearance_desc,
    persona.base_image_url
      ? [
        `A reference image was uploaded at ${persona.base_image_url}.`,
        'Use it as the primary design source, not decoration. First identify the visible subject species/type: human, cat, dog, animal, object mascot, or other. Preserve that species/type exactly.',
        'If the subject is a cat or other animal, keep it as an animal webtoon character with the same fur color, markings, ears, muzzle, eye shape, body silhouette, posture, and mood. Do not add a human body, human hair, human outfit, or human gender presentation unless the user explicitly requested anthropomorphism.',
        'Extract concrete safe traits: species/type, face silhouette, cheek/jaw or muzzle impression, eye shape and gaze, eyebrow/marking impression, fur or hair color, ears, tail/body shape, outfit or accessory hints only if visible, and overall mood.',
        'Translate those traits into an original reusable diary webtoon character. Do not copy a real person or pet exactly.',
        'The final prompt must mention at least five extracted visual traits from the reference image in plain English.',
        'Written tags are secondary style hints. If tags conflict with visible image traits, keep the image traits.',
      ].join(' ')
      : null,
    tagText ? `Selected appearance tags: ${tagText}.` : null,
    feedback
      ? `User retry feedback to fix: ${feedback}. Apply this strongly while preserving the character identity.`
      : null,
    'Exactly one character only, centered half-body or full-body for humans, or clear full animal body/mascot pose for animals. Keep the original subject species/type, clean silhouette, readable eyes, markings, colors, and personality.',
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

function buildReferenceFirstImagePrompt(
  persona: PersonaRow,
  generatedPrompt: string,
): string {
  const tagText = flattenTags(persona.appearance_tags).join(', ');
  return [
    'Transform the attached reference image into one original Korean diary webtoon character.',
    'This is image-to-image transformation, not text-only character invention.',
    'The attached image is the visual base. First identify and preserve the main subject species/type exactly: human stays human, cat stays cat, dog stays dog, animal stays animal, object mascot stays object mascot.',
    'If the image shows a cat or other animal, create a webtoon animal character, not a human, not a humanoid, not an anime person with cat ears. Preserve ears, muzzle, fur color, fur markings, eye shape, body silhouette, posture, and mood.',
    'Preserve the visible silhouette, pose impression, hairstyle/fur structure, bangs only if human hair is actually visible, hair/fur length, face or muzzle impression, eye shape, outfit shape only if visible, color family, accessories, and overall mood from the image as much as possible.',
    'If the image includes a background or strong setting, simplify it into a soft webtoon background instead of replacing it with an unrelated scene.',
    'Convert the subject into clean Korean diary webtoon/anime style with pastel color, clean line art, soft cel shading, and a reusable character look.',
    'Do not invent a different character when the reference image already provides visual information.',
    'Written tags and memo are secondary. They may adjust art style or mood only after the reference image is preserved.',
    tagText ? `Secondary tags: ${tagText}.` : null,
    persona.appearance_desc
      ? `Secondary memo: ${persona.appearance_desc}.`
      : null,
    'Exactly one character only. No model sheet, no grid, no collage, no multiple variations, no readable text, no watermark.',
    `Previous prompt draft for minor context only: ${generatedPrompt}`,
  ].filter(Boolean).join('\n');
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
  adminClient: ReturnType<typeof createClient>,
  apiKey: string,
  persona: PersonaRow,
  retryFeedback?: string,
): Promise<PersonaPromptResult> {
  const feedback = String(retryFeedback ?? '').trim();
  const referenceData = persona.base_image_url
    ? await loadReferenceImageData(adminClient, persona.base_image_url)
    : null;
  const promptInput = {
    name: persona.name,
    input_mode: persona.input_mode,
    appearance_desc: persona.appearance_desc,
    reference_image_url: persona.base_image_url,
    appearance_tags: persona.appearance_tags,
    retry_feedback: feedback,
    default_art_style: persona.default_art_style,
    default_genre: persona.default_genre,
    requirements: [
      'exactly one single character only',
      'one finished 2D webtoon character portrait or full-body image; if the reference subject is an animal, make it an animal webtoon character, not a human character',
      'centered character, simple clean background',
      'never make a character sheet, model sheet, reference sheet, lineup, collage, contact sheet, or multiple portraits',
      'clean silhouette and readable face',
      'soft pastel palette, not monochrome',
      'no text, no watermark, no logo',
      'details must be reusable for later diary panels',
      'write one compact art direction paragraph, not a long instruction sheet',
      'if a reference image is attached, first identify the subject species/type explicitly: human, cat, dog, animal, object mascot, or other',
      'if a reference image is attached, analyze the visible visual design carefully: species/type, face or muzzle shape, ears, tail/body silhouette, hairline/bangs only for humans, fur or hair length, fur or hair volume, eye shape, eyelid impression, eyebrow/marking angle, nose/mouth simplification, skin or fur tone, outfit colors only if visible, accessory hints, and overall mood',
      'when a reference image is attached, identify the subject species/type and main color explicitly; these two traits are critical and must be repeated near the beginning of image_prompt',
      'when a reference image is attached, identity preservation is higher priority than beauty, style trend, or generic anime defaults',
      'when a reference image is attached, never swap the subject species/type. A cat must remain a cat. A dog must remain a dog. Do not humanize animals unless retry_feedback explicitly asks for anthropomorphic design',
      'when a reference image is attached, never swap the subject to a different gender presentation for humans, species/type for animals, hair/fur color, hair/fur length, body silhouette, or clothing color family unless retry_feedback explicitly asks for it',
      'when a reference image is attached, the image_prompt must begin with a short "Reference-derived traits:" phrase followed by subject species/type and concrete visual traits observed from the actual pixels',
      'when a reference image is attached, reconstruct the final image prompt almost entirely from those observed visual traits',
      'when a reference image is attached, the image_prompt must be fully self-contained because the downstream Gemini image generator will receive text only, not the image',
      'do not write instructions that depend on seeing the attached image later; spell out every important visual trait in words',
      'do not copy a real person exactly; reinterpret the reference as a safe original webtoon character while preserving the selected visual cues',
      'reference image analysis must be reflected inside image_prompt as concrete visual words, not as "use the reference image"',
      'the reference image has higher priority than appearance tags when they conflict',
      'appearance tags are secondary style and mood hints; use them only after preserving visible image-derived traits',
      feedback
        ? 'this is a regeneration request; the retry_feedback is the most important correction after safety and single-character rules'
        : 'this is the first generation request',
      'describe subject species/type, body shape, hair or fur shape, hair or fur color, eye color, eye highlight, face or muzzle shape, skin or fur tone, markings, outfit top/bottom only if visible or requested, personality, expression baseline, linework, shading, palette, and silhouette',
      'avoid model sheet, reference sheet, grid, collage, multiple portrait variations, photorealistic portrait, and generic pretty character',
    ],
  };
  const userContent = referenceData
    ? [
      {
        type: 'input_text',
        text: JSON.stringify(promptInput),
      },
      {
        type: 'input_image',
        image_url: `data:${referenceData.mimeType};base64,${referenceData.base64}`,
        detail: 'high',
      },
    ]
    : JSON.stringify(promptInput);

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
            'You are a GPT vision analyst and image prompt director for a Korean diary webtoon character. Return only JSON that follows the schema. If a reference image is attached, inspect the actual pixels first and rebuild the prompt from what you see. The downstream Gemini image generator will receive text only, not the image, so the image_prompt must be fully self-contained and must not rely on phrases like "attached image" or "reference image". The image_prompt must begin with "Reference-derived traits:" and immediately state the subject species/type and main color before any style words. If the subject is a cat, dog, or other animal, keep it as that animal character; do not turn it into a human, humanoid, anime person, or person with animal ears unless retry feedback explicitly asks for anthropomorphism. Then name concrete visible traits: subject type/species, pose, body silhouette, face or muzzle silhouette, cheek/jaw impression, eye shape, gaze, eyebrow/marking angle, ears/tail if visible, hair/fur color, hair/fur length, hair/fur volume, outfit shape only if visible, outfit colors only if visible, accessories, background mood, and palette. Appearance tags are secondary style hints and must not override visible image traits. Do not swap species/type, gender presentation for humans, hair/fur color, hair/fur length, outfit color family, or silhouette unless retry feedback explicitly requests it. Do not mention the image URL. Write a clear English prompt optimized for Gemini image generation. The output must be a newly drawn webtoon/anime illustration, not a copy, crop, filter, or lightly edited version. The image must show exactly one character only, never a reference sheet, never a grid, never multiple variations.',
        },
        {
          role: 'user',
          content: userContent,
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
    const errorText = await response.text();
    if (referenceData && isInvalidImageError(errorText)) {
      const retryInput = {
        ...promptInput,
        reference_image_url: null,
        reference_image_note:
          'The uploaded reference image could not be decoded by GPT vision. Use the written memo, file-provided context, and tags only.',
      };
      return writePersonaPromptTextOnly(apiKey, retryInput);
    }
    throw new Error(`GPT prompt generation failed: ${errorText}`);
  }

  return JSON.parse(extractOutputText(await response.json())) as PersonaPromptResult;
}

function isInvalidImageError(text: string): boolean {
  const lower = text.toLowerCase();
  return (
    lower.includes('valid image') ||
    lower.includes('invalid_value') ||
    lower.includes('unsupported image') ||
    lower.includes('image data')
  );
}

async function writePersonaPromptTextOnly(
  apiKey: string,
  promptInput: Record<string, unknown>,
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
            'You are an image prompt director for a Korean diary webtoon character. Return only JSON that follows the schema. Write a clear English prompt optimized for Gemini image generation. The image must show exactly one character only, never a reference sheet, never a grid, never multiple variations.',
        },
        {
          role: 'user',
          content: JSON.stringify(promptInput),
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
  storagePath: string,
  aspectRatio: string,
  referenceImageUrl?: string | null,
): Promise<string> {
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
  const geminiPrompt = [
    referenceImageUrl
      ? 'Create a NEW stylized Korean diary webtoon/anime character illustration inspired by the attached image. Preserve the subject species/type exactly. Do not output the original image unchanged.'
      : 'Create exactly one reusable Korean diary webtoon character image for later comic panels.',
    referenceImageUrl
      ? 'Use the attached image as the primary character design reference for identity cues: subject species/type, animal or human body structure, fur/hair color, hairstyle or fur markings, ears/tail/muzzle if animal, outfit colors only if visible, accessories, pose impression, and mood.'
      : 'Show one main character only, centered half-body or full-body, clean silhouette, expressive face, simple soft background.',
    referenceImageUrl
      ? 'Identity lock: preserve the visible subject species/type first. If the image is a cat, the result must be a cat character, not a human, not a humanoid, not a person with cat ears. Preserve exact fur/hair color family, markings, ears, muzzle/face shape, eye impression, outfit color family only if visible, accessory hints, and body/pose impression. Do not drift into a generic pretty character.'
      : null,
    referenceImageUrl
      ? 'Strongly redraw and restyle the subject into clean 2D webtoon art: simplified facial features, expressive anime/webtoon eyes, clean ink line art, soft cel shading, pastel-friendly colors, polished character illustration.'
      : 'The character must clearly preserve the requested hair, eyes, skin tone, outfit, personality, and silhouette.',
    referenceImageUrl
      ? 'Do not preserve photographic texture, raw 3D render texture, screenshot artifacts, lighting noise, or exact pixels. This must look like a newly drawn webtoon character, not a copy, crop, filter, or lightly edited version of the input.'
      : null,
    referenceImageUrl
      ? 'Keep the key identity cues from the image while changing the rendering style dramatically into webtoon/anime illustration.'
      : null,
    referenceImageUrl
      ? 'If written tags or memo conflict with the image identity cues, follow the image identity cues first. Tags are secondary style hints only.'
      : null,
    referenceImageUrl
      ? 'The generated character should be a reinterpretation of the same visible design cues, not a new character with different species/type, fur/hair, outfit, or gender presentation.'
      : null,
    'Use rounded webtoon/anime character design, pastel colors, clean line art, soft cel shading, warm and friendly mood.',
    'Do not create a model sheet, reference sheet, grid, collage, lineup, multiple portraits, multiple outfits, or multiple variations.',
    'Do not draw readable text, watermark, logo, UI, or captions.',
    'Follow this character brief exactly:',
    prompt,
  ].join('\n');

  const imageParts: Array<Record<string, unknown>> = [];
  if (referenceImageUrl) {
    const referencePart = await buildReferenceImagePart(
      adminClient,
      referenceImageUrl,
    );
    if (referencePart) {
      imageParts.push(referencePart);
    } else {
      throw new Error('Reference image could not be loaded for image-based generation.');
    }
  }

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
            ...imageParts,
          ],
        },
      ],
      generationConfig: {
        responseModalities: ['TEXT', 'IMAGE'],
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

  const imagePart = parts.find(
    (part) => part?.inlineData?.data || part?.inline_data?.data,
  );
  const imageData = imagePart?.inlineData?.data ?? imagePart?.inline_data?.data;
  const mimeType =
    imagePart?.inlineData?.mimeType ??
    imagePart?.inline_data?.mime_type ??
    'image/png';
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

    if (!bytes) {
      return null;
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

  try {
    return {
      inline_data: {
        mime_type: referenceData.mimeType,
        data: referenceData.base64,
      },
    };
  } catch (_) {
    return null;
  }
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
          const outputText = (contentItem as { output_text?: unknown }).output_text;
          if (typeof outputText === 'string') {
            return outputText;
          }
          const jsonText = findJsonObjectText(contentItem);
          if (jsonText) {
            return jsonText;
          }
        }
      }
      const itemText = findJsonObjectText(item);
      if (itemText) {
        return itemText;
      }
    }
  }

  throw new Error('Could not find JSON text in GPT response.');
}

function findJsonObjectText(value: unknown): string | null {
  if (typeof value === 'string') {
    const trimmed = value.trim();
    return trimmed.startsWith('{') && trimmed.endsWith('}') ? trimmed : null;
  }
  if (!value || typeof value !== 'object') {
    return null;
  }
  for (const item of Object.values(value as Record<string, unknown>)) {
    const found = findJsonObjectText(item);
    if (found) {
      return found;
    }
  }
  return null;
}

async function safeJson<T>(request: Request): Promise<T | null> {
  try {
    return await request.json() as T;
  } catch (_) {
    return null;
  }
}
