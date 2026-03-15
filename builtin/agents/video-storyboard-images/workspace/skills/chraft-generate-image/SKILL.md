---
name: chraft-generate-image
description: Generate images via the Chraft media API using the user's sandbox credentials. Use this skill whenever the user wants to create, generate, draw, or make any kind of image — even if they don't say "generate" explicitly. This skill handles authentication automatically via the sandbox user context, so there's no need to ask the user for API keys.
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

```javascript
const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/image`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    model, // see references/image-models.md for options; default: "nano-banana-pro"
    prompt,
    aspect_ratio: aspectRatio ?? "1:1",
    quality: "hd",
    num_outputs: numOutputs ?? 1, // 1–4
    output_format: "png",
  }),
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

Model: nano-banana-pro · Credits used: 10
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
→ `model: "nano-banana-pro"`, defaults, prompt as-is

**"Make a 16:9 landscape wallpaper of mountains at sunset"**
→ `aspect_ratio: "16:9"`, prompt as-is

**"Generate 4 logo concepts for a coffee brand"**
→ `num_outputs: 4`, `aspect_ratio: "1:1"`

**"Create a photorealistic portrait, high quality"**
→ `model: "flux-2-pro"`, `aspect_ratio: "2:3"`
