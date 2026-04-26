---
name: chraft-image-relight
description: Relight an existing image with new lighting conditions using the Chraft relight API. Use whenever the user wants to change the lighting of an image, add dramatic lighting, change light direction, add studio lighting, make it look like sunset/neon/candlelight, or adjust brightness. Authentication uses the sandbox user context (chraftUseKey); no API key prompts.
---

# Chraft — Image Relight

This skill relights an existing image by calling Chraft's `/api/evostudio/media/relight` endpoint, then polls until complete.

The model preserves all subject details, composition, and style — only the lighting changes.

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

## Step 1 — Start the relight job

```javascript
const payload = {
  image_url: imageUrl, // Source image URL (required)
  lighting_style: lightingStyle ?? "studio", // See style table below (default: 'studio')
  light_angle: lightAngle ?? 270, // Horizontal light direction 0–360° (default: 270 = left)
  light_elevation: lightElevation ?? 0, // Vertical elevation -90–90° (default: 0 = eye level)
  brightness: brightness ?? 50, // Brightness 0–100 (default: 50)
};

const res = await fetch(`${CHRAFT_BASE_URL}/api/evostudio/media/relight`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify(payload),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start relight generation");
}

const { imageId, creditsConsumed } = await res.json();
```

**Lighting style reference:**

| Style         | Description                                  |
| ------------- | -------------------------------------------- |
| `studio`      | Clean professional studio lighting (default) |
| `natural`     | Soft daylight / outdoor natural light        |
| `dramatic`    | High-contrast dramatic shadows               |
| `soft`        | Diffused soft-box lighting                   |
| `neon`        | Colorful neon/cyberpunk glow                 |
| `golden_hour` | Warm golden sunset tones                     |
| `candlelight` | Warm, flickering intimate light              |
| `moonlight`   | Cool, dim night-time light                   |

**Light angle reference (horizontal_angle):**

| Direction           | Value           |
| ------------------- | --------------- |
| Front (straight on) | `0` or `360`    |
| Left                | `270` (default) |
| Right               | `90`            |
| Back-left           | `225`           |
| Back-right          | `135`           |

---

## Step 2 — Poll for completion

Relight takes 15–45 seconds. Poll every 3 seconds.

```javascript
const deadline = Date.now() + 120_000; // 2 minutes

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 3000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/evostudio/media/relight?image_id=${imageId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed") {
    return data.imageUrl; // string — URL to the relit image
  }
  if (data.status === "failed") {
    throw new Error(data.error || "Relight failed");
  }
  // processing → keep polling
}

throw new Error("Relight timed out after 2 minutes");
```

---

## Step 3 — Present results

Show the relit image inline:

```markdown
![Relit Image](https://...)

Style: dramatic · Light angle: 270° · Credits used: 10
```

---

## Error handling

| Status | Meaning                   | What to do                                   |
| ------ | ------------------------- | -------------------------------------------- |
| `401`  | Key not found or inactive | Check that the sandbox is running and paired |
| `400`  | Missing `image_url`       | Fix the request parameters                   |
| `402`  | Insufficient credits      | Tell the user to top up credits on Chraft    |
| `502`  | AI provider error         | Retry once; if persistent, report            |
| `500`  | Database error            | Retry once                                   |

All errors return `{ success: false, error: "..." }`. A `402` also includes `errorType: "INSUFFICIENT_CREDITS"`.

---

## Example interactions

**"Add dramatic lighting to this photo"**
→ `image_url: <url>`, `lighting_style: "dramatic"`

**"Make this look like it's shot at golden hour"**
→ `image_url: <url>`, `lighting_style: "golden_hour"`

**"Add studio lighting with light coming from the right"**
→ `image_url: <url>`, `lighting_style: "studio"`, `light_angle: 90`

**"Give this a neon cyberpunk look"**
→ `image_url: <url>`, `lighting_style: "neon"`

**"Relight with soft natural light from above"**
→ `image_url: <url>`, `lighting_style: "natural"`, `light_elevation: 45`
