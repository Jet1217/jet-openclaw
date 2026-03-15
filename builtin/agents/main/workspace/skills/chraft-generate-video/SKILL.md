---
name: chraft-generate-video
description: Generate videos via the Chraft media API. Use this skill whenever the user wants to create, generate, make, or animate a video — including text-to-video (describe a scene) and image-to-video (animate an existing image). Authentication is handled automatically from the sandbox user context; no API key setup required. Use this even if the user says "make a clip", "create a reel", or "animate this photo".
---

# Chraft — Video Generation

This skill generates videos by calling Chraft's `/api/openclaw/media/video` endpoint, then polls until the job completes. It supports both text-to-video (T2V) and image-to-video (I2V).

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
const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/video`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    model, // see references/video-models.md for options
    prompt,
    start_image_url: startImageUrl, // I2V only — omit for T2V
    duration: duration ?? 5, // seconds; respect each model's max
    aspect_ratio: aspectRatio ?? "9:16",
    resolution: "hd",
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start video generation");
}

const { videoId, creditsConsumed } = await res.json();
```

See `references/video-models.md` for the full model list organised by series (Kling, Seedance, Veo, Sora 2, Hailuo, Wan, Vidu, Grok).

**Aspect ratio quick reference:**

| Use case               | Value  |
| ---------------------- | ------ |
| TikTok / Reels / Short | `9:16` |
| YouTube / landscape    | `16:9` |
| Square                 | `1:1`  |
| Standard TV            | `4:3`  |

**Model selection strategy** (apply in priority order):

1. **User explicitly requests a model** → use exactly what the user asked for.
2. **UGC ad / product ad / commercial** (user mentions ad, commercial, UGC, product video, etc.) → use Sora 2:
   - T2V → `fal-ai/sora-2/text-to-video`
   - I2V → `fal-ai/sora-2/image-to-video`
   - Supported durations: 4, 8, 12, 16, 20 s — default to `8` if unspecified.
3. **All other cases (default)** → use Seedance 1.5:
   - T2V + I2V → `bytedance/seedance-1.5-pro`
   - Supported duration: 4–12 s (flexible, any integer) — default to `5` if unspecified.

**Kling 3 duration note:** supports 3–15 s (integer seconds). Clamp user input to this range when Kling 3 is selected.

---

## Step 2 — Poll for completion

Videos can take up to 5 minutes. Poll every 5 seconds and keep the user informed if they're waiting.

```javascript
const deadline = Date.now() + 300_000; // 5 minutes

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 5000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/video?video_id=${videoId}`, {
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

throw new Error("Video generation timed out after 5 minutes");
```

---

## Step 3 — Present results

Show a markdown link for each video, plus a summary:

```markdown
[Watch Video](https://...)

Model: kling-v3-standard · Duration: 5s · Credits used: 42
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
→ T2V, `bytedance/seedance-1.5-pro` (default), `aspect_ratio: "9:16"`, `duration: 5`

**"Animate this image into a 10-second video"**
→ I2V, `bytedance/seedance-1.5-pro` (default), `start_image_url: <url>`, `duration: 10`

**"Make a UGC ad for our new sneakers"**
→ T2V, `fal-ai/sora-2/text-to-video` (UGC ad), `aspect_ratio: "9:16"`, `duration: 8`

**"Create a product commercial, 16 seconds"**
→ T2V, `fal-ai/sora-2/text-to-video` (UGC ad), `aspect_ratio: "9:16"`, `duration: 16`

**"Make a video with Kling 3, 12 seconds"**
→ T2V, `fal-ai/kling-video/v3/standard/text-to-video` (user-specified), `duration: 12`

**"Create a cinematic landscape with Google Veo"**
→ T2V, `google/veo-3.1` (user-specified), `aspect_ratio: "16:9"`, `duration: 8`
