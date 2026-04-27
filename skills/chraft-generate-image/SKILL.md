---
name: chraft-generate-image
description: Generate, edit, or inpaint images via the Chraft media API using the user's sandbox credentials. Supports text-to-image, image editing (pass input_images), and inpainting (describe what to replace in a region). Defaults to GPT Image 2 (model alias "gpt-image-2") for text-to-image and GPT Image 2 edit ("gpt-image-2-edit") for edit/inpaint. Use whenever the user wants to create, generate, draw, edit, retouch, replace a region, or inpaint any kind of image. Authentication uses the sandbox user context (chraftUseKey); no API key prompts.
---

# Chraft — Image Generation, Editing & Inpainting

This skill covers three modes — all using the same `/api/evostudio/media/image` endpoint:

| Mode              | When to use                                                                            | Key parameters                                                            |
| ----------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| **Text-to-image** | No reference image; generate from a prompt                                             | `prompt` only                                                             |
| **Edit**          | Modify an existing image (change background, swap object, adjust style)                | `input_images: [url]` + descriptive `prompt`                              |
| **Inpaint**       | Replace or fill a specific region of an image (remove object, change outfit, fix area) | `input_images: [url]` + `prompt` describing what the region should become |

The skill uses two calls: one to start the job, one (repeated) to check if it's done. Generation is async and takes 5–30 seconds.

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

**Reference images (`input_images`):** Pass publicly reachable image URLs so the model can use them as conditioning. Use **`input_images` only** — a string array. One image is `["https://..."]`; multiple references are more elements in the same array (duplicates are removed server-side, order preserved).

- **Edit mode:** `input_images` = the image to edit; `prompt` = what change to make
- **Inpaint mode:** `input_images` = the image to inpaint; `prompt` = describe what the target region should look like (e.g. "replace the red jacket with a blue hoodie", "remove the person in the background")
- When `input_images` is provided, switch the default model to the edit variant (`gpt-image-2-edit`) so the request routes to the edit/inpaint endpoint.

```javascript
const DEFAULT_MODEL = "gpt-image-2";
const DEFAULT_EDIT_MODEL = "gpt-image-2-edit";

const hasReferenceImages = !!referenceImageUrls?.length;

const payload = {
  model: model ?? (hasReferenceImages ? DEFAULT_EDIT_MODEL : DEFAULT_MODEL),
  prompt,
  aspect_ratio: aspectRatio ?? "1:1",
  quality: "hd",
  num_outputs: numOutputs ?? 1, // 1–4
  output_format: "png",
};

// Edit / inpaint: include the source image URL(s)
if (hasReferenceImages) {
  payload.input_images = referenceImageUrls;
}

const res = await fetch(`${CHRAFT_BASE_URL}/api/evostudio/media/image`, {
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

**Model selection for text-to-image:**

| Need                                        | Recommended model  |
| ------------------------------------------- | ------------------ |
| General generation (default, high fidelity) | `gpt-image-2`      |
| Fast / lightweight generation               | `nano-banana-2`    |
| Higher quality / more detail                | `nano-banana-pro`  |
| Photorealistic, multi-reference             | `flux-2-pro`       |
| Artistic / stylized                         | `seedream-v5-lite` |

**Model selection for edit / inpaint:**

| Need                              | Recommended model       |
| --------------------------------- | ----------------------- |
| General edit or inpaint (default) | `gpt-image-2-edit`      |
| Fast / lightweight edit           | `nano-banana-2-edit`    |
| Higher-quality edit               | `nano-banana-pro`       |
| Photorealistic context edit       | `flux-2-pro`            |
| Artistic style edit               | `seedream-v5-lite-edit` |

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

Poll the status endpoint every 3 seconds. Generation usually finishes within 30 seconds; allow up to 120 seconds before giving up.

```javascript
const deadline = Date.now() + 120_000;

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 3000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/evostudio/media/image?image_id=${imageId}`, {
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

Model: gpt-image-2 · Credits used: 10
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
→ text-to-image, default `model: "gpt-image-2"`, prompt as-is

**"Make a 16:9 landscape wallpaper of mountains at sunset"**
→ `aspect_ratio: "16:9"`, default model, prompt as-is

**"Generate 4 logo concepts for a coffee brand"**
→ `num_outputs: 4`, `aspect_ratio: "1:1"`

**"Edit this product photo to add holiday packaging"** (user provides image URL)
→ edit mode: `input_images: [url]`, `prompt: "add holiday packaging"`, default model

**"Change the background to a snowy forest"** (user provides image URL)
→ edit mode: `input_images: [url]`, `prompt: "change the background to a snowy forest"`, default `model: "gpt-image-2-edit"`

**"Remove the person standing in the background"** (user provides image URL)
→ inpaint mode: `input_images: [url]`, `prompt: "remove the person in the background, fill with natural scenery"`, default model

**"Replace the red jacket with a blue hoodie"** (user provides image URL)
→ inpaint mode: `input_images: [url]`, `prompt: "replace the red jacket with a blue hoodie"`, default model

**"Fix the blurry area in the top-right corner"** (user provides image URL)
→ inpaint mode: `input_images: [url]`, `prompt: "clean sharp continuation of the background in the top-right corner"`, default model

**"Create a photorealistic portrait, high quality"**
→ `model: "nano-banana-pro"` or `model: "flux-2-pro"`, `aspect_ratio: "2:3"` (see references for full alias list)

**"Use a faster / cheaper model"**
→ `model: "nano-banana-2"` (text-to-image) or `model: "nano-banana-2-edit"` (edit/inpaint)

**"Edit this image with precise context-aware changes"** (user provides image URL)
→ edit mode: `input_images: [url]`, `model: "nano-banana-pro"` or `model: "flux-2-pro"`, descriptive prompt
