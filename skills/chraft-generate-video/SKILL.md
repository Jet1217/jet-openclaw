---
name: chraft-generate-video
slug: chraft-generate-video
version: 1.0.0
author: Chraft Official
category: Video
tags:
  - video-gen
  - text-to-video
  - image-to-video
description: Generate videos via the Chraft media API. Use this skill whenever the user wants to create, generate, make, or animate a video — including text-to-video (describe a scene) and image-to-video (animate an existing image). Authentication is handled automatically from the sandbox user context; no API key setup required. Use this even if the user says "make a clip", "create a reel", or "animate this photo".
---

# Chraft — Video Generation

This skill generates videos by calling Chraft's `/api/evostudio/media/video` endpoint, then polls until the job completes. It supports both text-to-video (T2V) and image-to-video (I2V).

Videos take longer than images — typically 1–3 minutes — because the AI model has to render multiple frames. The polling loop handles this transparently.

---

## Detect the mode

| Situation                                | Mode                     |
| ---------------------------------------- | ------------------------ |
| User describes a scene in text, no image | **Text-to-Video (T2V)**  |
| User provides an image URL or file path  | **Image-to-Video (I2V)** |

For I2V, upload the image to get a URL if only a local path is provided, then pass it as `start_image_url`.

---

## Load credentials from sandbox context

```javascript
import fs from "fs";
import path from "path";

const stateDir = process.env.OPENCLAW_STATE_DIR || "/data";
const ctx = JSON.parse(fs.readFileSync(path.join(stateDir, "user-context.json"), "utf8"));
const { chraftUseKey } = ctx;
const CHRAFT_BASE_URL = process.env.CHRAFT_BASE_URL || "https://chraft.ai";

function authHeaders() {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${chraftUseKey}`,
  };
}
```

If `chraftUseKey` is empty, tell the user their sandbox hasn't been linked to a Chraft account yet.

---

## Step 1 — Start the generation job

```javascript
const res = await fetch(`${CHRAFT_BASE_URL}/api/evostudio/media/video`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    model, // see references/video-models.md for aliases
    prompt,
    start_image_url: startImageUrl, // I2V only — omit for T2V
    end_image_url: endImageUrl, // PixVerse / Seedance 2 transition only
    duration: duration ?? 5, // seconds; respect each model's max
    aspect_ratio: aspectRatio ?? "9:16",
    resolution: "hd", // "hd" (720p) · "fhd" (1080p) · "uhd" (4K, Kling 3.0 4K + Veo 3.1 only)

    // ── Seedance 2 OMNI only (seedance2-omni, seedance2-fast-omni) ──
    image_urls: imageUrls, // string[] — multiple reference images
    video_urls: videoUrls, // string[] — reference videos
    audio_url: audioUrl, // string — reference audio

    // ── Reference-to-video / Video-edit inputs ──
    // wan2.7-ref, happyhorse-ref, happyhorse-edit
    reference_images: referenceImages, // string[] — up to 5 for Happy Horse
    // wan2.7-edit / happyhorse-edit / kling-o3 video editors: [0] is the source video
    reference_videos: referenceVideos, // string[]
    // kling-o3-ref / kling-o3-pro-ref only
    o3_image_urls: o3ImageUrls, // string[] — referenced as @Image1, @Image2 in prompt
    o3_elements: o3Elements, // Array<{ frontal_image_url, reference_image_urls? }>
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start video generation");
}

const { videoId, creditsConsumed } = await res.json();
```

See `references/video-models.md` for the full model list organised by series (Kling, Seedance, Veo, Sora 2, Hailuo, Wan, Vidu, Grok, PixVerse).

**Aspect ratio quick reference:**

| Use case               | Value  |
| ---------------------- | ------ |
| TikTok / Reels / Short | `9:16` |
| YouTube / landscape    | `16:9` |
| Square                 | `1:1`  |
| Standard TV            | `4:3`  |
| Ultra-wide             | `21:9` |

**Model selection strategy** (apply in priority order):

1. **User explicitly requests a model** → use exactly what the user asked for.
2. **UGC ad / product ad / commercial** (user mentions ad, commercial, UGC, product video, etc.) → use Sora 2:
   - T2V → `sora2`
   - I2V → `sora2-i2v`
   - Supported durations: 4, 8, 12, 16, 20 s — default to `8` if unspecified.
3. **All other cases (default)** → use Seedance 1.5:
   - T2V + I2V → `seedance1.5`
   - Supported duration: 4–12 s (flexible, any integer) — default to `5` if unspecified.

**Kling 3 duration note:** supports 3–15 s (integer seconds). Clamp user input to this range when Kling 3 is selected.

**Kling 3.0 4K notes (`kling3-4k`, `kling3-4k-t2v`, `kling3-4k-i2v`):**

- You **must** pass `resolution: "uhd"` — these variants only support 4K output. Any other value will be rejected.
- Supported durations: 3–15 s; aspect ratios: `16:9`, `9:16`, `1:1`.
- `kling3-4k-i2v` requires `start_image_url`; `end_image_url` is optional (first→last frame interpolation).

**Veo 3.1 4K note:** `veo3.1` and `veo3.1-fast` also accept `resolution: "uhd"` for 4K output (1.5× the 1080p credit cost for `veo3.1`, 2.33× for `veo3.1-fast`).

**Seedance 2.0 notes:**

- Standard models: `seedance2`, `seedance2-i2v`, `seedance2-omni`
- Fast models (lower cost, faster render): `seedance2-fast`, `seedance2-fast-i2v`, `seedance2-fast-omni`
- I2V variants require `start_image_url`; pass `end_image_url` as well for a first+last-frame transition
- **OMNI variants** (`seedance2-omni`, `seedance2-fast-omni`) accept any combination of reference inputs — at least one must be supplied:
  - `image_urls: string[]` — one or more reference images (falls back to `[start_image_url]` if omitted)
  - `video_urls: string[]` — one or more reference videos
  - `audio_url: string` — a reference audio track
- Supported durations: 4–15 s (any integer); supported aspect ratios: `16:9`, `9:16`, `1:1`, `4:3`, `3:4`, `21:9`
- **Resolution:** Standard (non-fast) models support `hd` (720p, default) and `fhd` (1080p). Fast models are `hd` (720p) only — `fhd` is ignored and falls back to 720p.

**PixVerse duration note:** v5 supports 5 or 8 s only; v5.5 and v5.6 support 5, 8, or 10 s (10 s only at 720p). v6 supports **1–15 s** (any integer). v5 has no audio; v5.5/v5.6/v6 auto-generate native audio.

**PixVerse v6 resolution:** `sd360` (360p) · `sd540` (540p) · `hd` (720p) · `fhd` (1080p). Credits billed per second with audio: 360p=7/s · 540p=9/s · 720p=12/s · 1080p=23/s.

**PixVerse v6 aspect ratios (T2V only):** supports all standard ratios plus `2:3`, `3:2`, `21:9`.

**PixVerse transition (first+last frame):** When the user provides two images (start and end), pass both `start_image_url` and `end_image_url` with a PixVerse I2V model to interpolate between the two frames. Supported on v5, v5.5, v5.6, and v6.

**Happy Horse 1.0 notes:**

- Aliases: `happyhorse` / `happyhorse-t2v` (T2V), `happyhorse-i2v` (I2V), `happyhorse-ref` (reference-to-video, up to 5 reference images), `happyhorse-edit` (video edit, up to 5 reference images + a source video).
- Supported durations: 3–15 s (any integer). Supported aspect ratios: `16:9`, `9:16`, `1:1`, `4:3`, `3:4`.
- Resolution: `hd` (720p) or `fhd` (1080p). Native lip-sync and Foley audio in 7 languages — good for dialogue-driven scenes.
- **`happyhorse-ref`** (reference-to-video): pass `reference_images: string[]` (up to 5). `start_image_url` is also treated as a reference image if provided.
- **`happyhorse-edit`** (video edit): required — `reference_videos: [sourceVideoUrl]` (the first entry is the source video). Optional — `reference_images: string[]` (up to 5) for style/character reference. `start_image_url` is also treated as a reference image. Do NOT pass the source video as `start_image_url`.

**WAN 2.7 notes:**

- Aliases: `wan2.7` (T2V), `wan2.7-i2v` (I2V), `wan2.7-ref` (reference-to-video), `wan2.7-edit` (video edit), `wan2.2`, `wan2.2-fast`, `wan2.2-t2v-fast`.
- Supported durations: 2–10 s. Resolution: `hd` (720p) or `fhd` (1080p).
- **`wan2.7-ref`**: pass `reference_images: string[]` and/or `reference_videos: string[]`. `start_image_url` is also added to the reference-image list if provided.
- **`wan2.7-edit`**: required — `reference_videos: [sourceVideoUrl]`. Optional — `start_image_url` as a single style reference image. `duration: 0` (or omit) means "match input video length"; otherwise 2–10 s.

**Kling O3 reference-to-video notes (`kling-o3-ref`, `kling-o3-pro-ref`):**

- Supported durations: 3–15 s (any integer). Aspect ratios: `16:9`, `9:16`, `1:1`.
- Input options (pass any combination):
  - `start_image_url` / `end_image_url` — first/last frame images
  - `o3_image_urls: string[]` — reference images referenced as `@Image1`, `@Image2`, etc. in the prompt
  - `o3_elements: Array<{ frontal_image_url: string; reference_image_urls?: string[] }>` — structured character/object elements

---

## Step 2 — Poll for completion

Videos can take up to 20 minutes depending on the model and queue. Poll every 5 seconds and keep the user informed if they're waiting.

```javascript
const deadline = Date.now() + 1_200_000; // 20 minutes

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 5_000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/evostudio/media/video?video_id=${videoId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed" || data.status === "succeeded") {
    return { videoUrls: data.videoUrls, duration: data.duration };
  }
  if (data.status === "failed" || data.status === "error") {
    throw new Error("Video generation failed");
  }
  // pending / processing → keep polling
}

// Timed out — don't throw, let the user resume later
return {
  videoUrls: [],
  videoId,
  timedOut: true,
  message: `Video is still generating after 40 minutes. Your video ID is \`${videoId}\` — check back later or ask me to poll again.`,
};
```

---

## Step 3 — Present results

Show a markdown link for each video, plus a summary:

```markdown
[Watch Video](https://...)

Model: kling3-standard · Duration: 5s · Credits used: 42
```

---

## Error handling

| Status | Meaning                                   | What to do                                   |
| ------ | ----------------------------------------- | -------------------------------------------- |
| `401`  | Key not found or inactive                 | Check that the sandbox is running and paired |
| `400`  | Missing `model`/`prompt` or invalid model | Fix the request parameters                   |
| `402`  | Insufficient credits                      | Tell the user to top up credits on Chraft    |
| `502`  | AI provider error                         | Retry once; if persistent, report            |
| `500`  | Database error                            | Retry once                                   |

All errors return `{ success: false, error: "..." }`. A `402` also includes `errorType: "INSUFFICIENT_CREDITS"`.

---

## Example interactions

**"Generate a 9:16 TikTok video of a cat playing in snow"**
→ T2V, `seedance1.5` (default), `aspect_ratio: "9:16"`, `duration: 5`

**"Animate this image into a 10-second video"**
→ I2V, `seedance1.5` (default), `start_image_url: <url>`, `duration: 10`

**"Make a UGC ad for our new sneakers"**
→ T2V, `sora2` (UGC ad), `aspect_ratio: "9:16"`, `duration: 8`

**"Create a product commercial, 16 seconds"**
→ T2V, `sora2` (UGC ad), `aspect_ratio: "9:16"`, `duration: 16`

**"Make a video with Kling 3, 12 seconds"**
→ T2V, `kling3-standard` (user-specified), `duration: 12`

**"Generate a 4K Kling 3 video of a mountain sunrise"**
→ T2V, `kling3-4k`, `resolution: "uhd"`, `aspect_ratio: "16:9"`, `duration: 5`

**"Animate this image in 4K with Kling 3"**
→ I2V, `kling3-4k-i2v`, `start_image_url: <url>`, `resolution: "uhd"`, `duration: 5`

**"Create a 4K Veo 3.1 cinematic shot"**
→ T2V, `veo3.1`, `resolution: "uhd"`, `aspect_ratio: "16:9"`, `duration: 8`

**"Make a video with Seedance 2"**
→ T2V, `seedance2` (user-specified), `aspect_ratio: "9:16"`, `duration: 5`

**"Make a fast Seedance 2 video"**
→ T2V, `seedance2-fast` (user-specified), `aspect_ratio: "9:16"`, `duration: 5`

**"Animate this image with Seedance 2"**
→ I2V, `seedance2-i2v` (user-specified), `start_image_url: <url>`, `duration: 5`

**"Animate this image with Seedance 2 Fast"**
→ I2V, `seedance2-fast-i2v` (user-specified), `start_image_url: <url>`, `duration: 5`

**"Seedance 2 transition between two images"**
→ I2V, `seedance2-i2v`, `start_image_url: <first>`, `end_image_url: <last>`, `duration: 5`

**"Seedance 2 OMNI with multiple reference images"**
→ `seedance2-omni`, `image_urls: [<url1>, <url2>, <url3>]`, `duration: 5`

**"Seedance 2 OMNI with a reference video and audio"**
→ `seedance2-omni`, `video_urls: [<videoUrl>]`, `audio_url: <audioUrl>`, `duration: 5`

**"Create a cinematic landscape with Google Veo"**
→ T2V, `veo3.1` (user-specified), `aspect_ratio: "16:9"`, `duration: 8`

**"Generate a 10-second PixVerse v6 video of a neon cityscape"**
→ T2V, `pixverse-v6` (user-specified), `aspect_ratio: "16:9"`, `duration: 10`, `resolution: "hd"`

**"PixVerse v6 transition between two images"**
→ I2V, `pixverse-v6-i2v`, `start_image_url: <first>`, `end_image_url: <last>`, `duration: 5`

**"Generate a 10-second Happy Horse video of two people chatting in a café"**
→ T2V, `happyhorse` (user-specified), `aspect_ratio: "16:9"`, `duration: 10`, `resolution: "hd"`

**"Animate this portrait into a talking-head clip with Happy Horse"**
→ I2V, `happyhorse-i2v` (user-specified), `start_image_url: <url>`, `duration: 8`

**"Happy Horse reference video using these 3 character images"**
→ `happyhorse-ref`, `reference_images: [<url1>, <url2>, <url3>]`, `duration: 8`

**"Edit this video with Happy Horse using these reference images"**
→ `happyhorse-edit`, `reference_videos: [<sourceVideoUrl>]`, `reference_images: [<url1>, <url2>]`, `duration: 8`

**"WAN 2.7 reference video from multiple images"**
→ `wan2.7-ref`, `reference_images: [<url1>, <url2>]`, `duration: 5`, `aspect_ratio: "16:9"`

**"Edit this video with WAN 2.7"**
→ `wan2.7-edit`, `reference_videos: [<sourceVideoUrl>]`, `start_image_url: <styleRefUrl>`, `duration: 0` (match input length)

**"Kling O3 reference video with @Image1 and @Image2 in prompt"**
→ `kling-o3-ref`, `prompt: "@Image1 walks toward @Image2 ..."`, `o3_image_urls: [<url1>, <url2>]`, `duration: 5`
