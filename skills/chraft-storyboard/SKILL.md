---
name: chraft-storyboard
description: Generate a cinematic storyboard grid from a reference image using the Chraft storyboard API. Use whenever the user wants to create a storyboard, multi-panel grid, shot breakdown, scene panels, or cinematic panels from an image. Authentication uses the sandbox user context (chraftUseKey); no API key prompts.
---

# Chraft — Cinematic Storyboard Generation

This skill generates a multi-panel cinematic storyboard grid from a reference image by calling Chraft's `/api/openclaw/media/storyboard` endpoint, then polls until complete.

The storyboard renders the subject from multiple distinct camera angles arranged in a grid. Character appearance, style, and lighting are kept consistent across all panels — only camera positions change.

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

## Step 1 — Start the storyboard generation job

```javascript
const payload = {
  image_url: imageUrl, // Reference image URL (required)
  prompt: sceneDescription, // Optional scene context (omit to use subject from image)
  grid_size: gridSize ?? "3x3", // '3x3' (9 panels) or '5x5' (25 panels)
  aspect_ratio: "16:9", // Output aspect ratio for each panel
};

const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/storyboard`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify(payload),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start storyboard generation");
}

const { imageId, creditsConsumed } = await res.json();
```

**Grid size reference:**

| Value | Panels    | Use case                   |
| ----- | --------- | -------------------------- |
| `3x3` | 9 panels  | Default — quick storyboard |
| `5x5` | 25 panels | Detailed shot breakdown    |

---

## Step 2 — Poll for completion

Storyboard generation takes 30–90 seconds. Poll every 5 seconds.

```javascript
const deadline = Date.now() + 180_000; // 3 minutes

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 5000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/storyboard?image_id=${imageId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed") {
    return data.imageUrl; // string — URL to the storyboard grid image
  }
  if (data.status === "failed") {
    throw new Error(data.error || "Storyboard generation failed");
  }
  // processing → keep polling
}

throw new Error("Storyboard generation timed out after 3 minutes");
```

---

## Step 3 — Present results

Show the storyboard grid image inline:

```markdown
![Cinematic Storyboard](https://...)

Grid: 3×3 (9 panels) · Credits used: 25
```

---

## Error handling

| Status | Meaning                                    | What to do                                   |
| ------ | ------------------------------------------ | -------------------------------------------- |
| `401`  | Key not found or inactive                  | Check that the sandbox is running and paired |
| `400`  | Missing `image_url` or invalid `grid_size` | Fix the request parameters                   |
| `402`  | Insufficient credits                       | Tell the user to top up credits on Chraft    |
| `502`  | AI provider error                          | Retry once; if persistent, report            |
| `500`  | Database error                             | Retry once                                   |

All errors return `{ success: false, error: "..." }`. A `402` also includes `errorType: "INSUFFICIENT_CREDITS"`.

---

## Example interactions

**"Create a storyboard from this image"** (user provides image URL)
→ `image_url: <url>`, `grid_size: "3x3"` (default)

**"Make a 25-panel storyboard of this character"**
→ `image_url: <url>`, `grid_size: "5x5"`

**"Generate a cinematic shot breakdown of this scene with dramatic lighting"**
→ `image_url: <url>`, `prompt: "dramatic cinematic lighting, action scene"`, `grid_size: "3x3"`
