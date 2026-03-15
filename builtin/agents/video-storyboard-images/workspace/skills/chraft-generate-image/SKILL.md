---
name: chraft-generate-image
description: Generate storyboard reference images via the Chraft media API. RESTRICTED to nano-banana-2 and nano-banana-pro models only. Use for batch storyboard frame generation.
---

# Chraft — Storyboard Image Generation

Generates storyboard reference images using the Chraft media API.

**Model restriction:** Only `nano-banana-2` and `nano-banana-pro` are permitted in this agent.

---

## Load credentials

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

---

## Allowed Models

| Model             | When to use            |
| ----------------- | ---------------------- |
| `nano-banana-2`   | Default — most shots   |
| `nano-banana-pro` | Hero shots, key frames |

**Do not use any other model.** If a different model is requested, use `nano-banana-2` and note the substitution.

---

## Step 1 — Start generation

```javascript
// model must be 'nano-banana-2' or 'nano-banana-pro'
const ALLOWED_MODELS = ["nano-banana-2", "nano-banana-pro"];
const safeModel = ALLOWED_MODELS.includes(model) ? model : "nano-banana-2";

const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/image`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    model: safeModel,
    prompt,
    aspect_ratio: aspectRatio ?? "9:16",
    quality: "hd",
    num_outputs: 1,
    output_format: "png",
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start image generation");
}

const { imageId, creditsConsumed } = await res.json();
```

---

## Step 2 — Poll for completion

```javascript
const deadline = Date.now() + 120_000;

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 3000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/image?image_id=${imageId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed" || data.status === "succeeded") {
    return data.imageUrls[0];
  }
  if (data.status === "failed" || data.status === "error") {
    throw new Error("Image generation failed");
  }
}

throw new Error("Image generation timed out after 120s");
```

---

## Step 3 — Present result

```markdown
![Shot N](https://...)
Model: nano-banana-2 · Credits: N
```

---

## Batch Processing

For storyboard batches, process one shot at a time. After each image:

1. Show the image inline
2. Note the shot number and model used
3. Continue to the next shot

If a shot fails, log the error, skip it, and continue the batch.

---

## Error Handling

| Status | Meaning              | Action                  |
| ------ | -------------------- | ----------------------- |
| `401`  | Key inactive         | Check sandbox pairing   |
| `402`  | Insufficient credits | Notify user, stop batch |
| `400`  | Invalid params       | Fix prompt, retry       |
| `502`  | Provider error       | Retry once              |
