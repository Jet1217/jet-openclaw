---
name: chraft-generate-image
description: Generate images via the Chraft media API using the user's sandbox credentials. Supports optional reference images via input_images (string array; one URL or many). Defaults to Nano Banana 2 (fal-ai/nano-banana-2). Use whenever the user wants to create, generate, draw, edit from a reference, or make any kind of image. Authentication uses the sandbox user context (chraftUseKey); no API key prompts.
---

# Chraft — Image Generation

This skill generates images by calling Chraft's `/api/openclaw/media/image` endpoint, then polls until the job completes and returns the image URLs.

The skill uses two calls: one to start the job, one (repeated) to check if it's done. Image generation is async because it takes 5–30 seconds depending on the model.

---

## Load credentials from sandbox context

Read the user context file — this is where the sandbox stores the Chraft API key. The key is already injected; there's nothing to configure.

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

Send a POST request with the model and prompt. The response immediately returns an `imageId` — the actual image isn't ready yet.

**Reference images (optional):** Pass publicly reachable image URLs so the model can use them as conditioning ("垫图"). Use **`input_images` only** — a string array. One reference image is `["https://..."]`; multiple references are more elements in the same array (duplicates are removed server-side, order preserved).

When reference images are provided, Fal routes (including Nano Banana 2) automatically use the provider's **edit** endpoint where supported. Use `fal-ai/nano-banana-2` as the model value.

```javascript
const DEFAULT_MODEL = "fal-ai/nano-banana-2";

const payload = {
  model: model ?? DEFAULT_MODEL,
  prompt,
  aspect_ratio: aspectRatio ?? "1:1",
  quality: "hd",
  num_outputs: numOutputs ?? 1, // 1–4
  output_format: "png",
};

// Optional: one or more reference images (omit if text-only)
if (referenceImageUrls?.length) {
  payload.input_images = referenceImageUrls;
}

const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/image`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify(payload),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start image generation");
}

const { imageId, creditsConsumed } = await res.json();
```

See `references/image-models.md` for the full model list with descriptions.

**Aspect ratio quick reference:**

| Use case                  | Value  |
| ------------------------- | ------ |
| Square / avatar / social  | `1:1`  |
| YouTube / landscape       | `16:9` |
| TikTok / Reels / portrait | `9:16` |
| Photo / print             | `3:2`  |
| Pinterest / blog          | `2:3`  |
| Cinematic ultra-wide      | `21:9` |

---

## Step 2 — Poll for completion

Poll the status endpoint every 3 seconds. Image generation usually finishes within 30 seconds; allow up to 120 seconds before giving up.

```javascript
const deadline = Date.now() + 120_000;

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 3000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/image?image_id=${imageId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed" || data.status === "succeeded") {
    return data.imageUrls; // string[] — one URL per output image
  }
  if (data.status === "failed" || data.status === "error") {
    throw new Error("Image generation failed");
  }
  // any other status (processing, pending) → keep polling
}

throw new Error("Image generation timed out after 120s");
```

---

## Step 3 — Present results

Show each image inline as a markdown image, followed by a brief summary:

```markdown
![Generated Image](https://...)

Model: fal-ai/nano-banana-2 · Credits used: 10
```

If multiple images were requested, show all of them.

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

**"Generate a futuristic city at night"**
→ default `model: "fal-ai/nano-banana-2"`, prompt as-is

**"Make a 16:9 landscape wallpaper of mountains at sunset"**
→ `aspect_ratio: "16:9"`, default model, prompt as-is

**"Generate 4 logo concepts for a coffee brand"**
→ `num_outputs: 4`, `aspect_ratio: "1:1"`

**"Edit this product photo to add holiday packaging"** (user provides image URL(s))
→ `input_images: [url1, ...]`, same default model, prompt describes the edit

**"Create a photorealistic portrait, high quality"**
→ `model: "black-forest-labs/flux-2-pro"`, `aspect_ratio: "2:3"` (see references for exact `model` strings)
