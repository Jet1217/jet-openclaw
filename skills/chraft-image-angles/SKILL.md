---
name: chraft-image-angles
description: Generate a new view of a subject from a different camera angle using the Ploval angles API. Use whenever the user wants to see an image from a different angle, rotate the camera, change the viewpoint, show the back/side/front of a subject, or generate a multi-angle view. Authentication uses the sandbox user context (chraftUseKey); no API key prompts.
---

# Ploval — Multiple Angles Generation

This skill generates a new image of the same subject from a different camera angle by calling Ploval's `/api/openclaw/media/angles` endpoint, then polls until complete.

The model keeps the subject identical — only the camera position changes. Works best with people, characters, objects, and products.

---

## Load credentials from sandbox context

```javascript
import fs from "fs";
import path from "path";

const stateDir = process.env.OPENCLAW_STATE_DIR || "/data";
const ctx = JSON.parse(fs.readFileSync(path.join(stateDir, "user-context.json"), "utf8"));
const { chraftUseKey } = ctx;
const CHRAFT_BASE_URL = process.env.CHRAFT_BASE_URL || "https://ploval.ai";

function authHeaders() {
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${chraftUseKey}`,
  };
}
```

If `chraftUseKey` is empty, tell the user their sandbox hasn't been linked to a Ploval account yet.

---

## Step 1 — Start the angles generation job

```javascript
const payload = {
  image_url: imageUrl, // Source image URL (required)
  horizontal_angle: horizontalAngle ?? 45, // Horizontal camera rotation in degrees (default: 45)
  vertical_angle: verticalAngle ?? 0, // Vertical tilt in degrees (default: 0)
  zoom: zoom ?? 5, // Zoom level 1–10 (default: 5)
};

const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/angles`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify(payload),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start angles generation");
}

const { imageId, creditsConsumed } = await res.json();
```

**Angle reference:**

| View                  | horizontal_angle | vertical_angle |
| --------------------- | ---------------- | -------------- |
| Front (same as input) | `0`              | `0`            |
| Left side             | `-90`            | `0`            |
| Right side            | `90`             | `0`            |
| Back                  | `180`            | `-180`         |
| Front-left            | `-45`            | `0`            |
| Front-right           | `45`             | `0`            |
| Bird's eye            | `0`              | `45`           |
| Low angle             | `0`              | `-30`          |

---

## Step 2 — Poll for completion

Angles generation takes 20–60 seconds. Poll every 3 seconds.

```javascript
const deadline = Date.now() + 120_000; // 2 minutes

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 3000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/angles?image_id=${imageId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed") {
    return data.imageUrl; // string — URL to the re-angled image
  }
  if (data.status === "failed") {
    throw new Error(data.error || "Angles generation failed");
  }
  // processing → keep polling
}

throw new Error("Angles generation timed out after 2 minutes");
```

---

## Step 3 — Present results

Show the result image inline:

```markdown
![Side View](https://...)

Angle: 90° horizontal · Credits used: 10
```

---

## Error handling

| Status | Meaning                   | What to do                                   |
| ------ | ------------------------- | -------------------------------------------- |
| `401`  | Key not found or inactive | Check that the sandbox is running and paired |
| `400`  | Missing `image_url`       | Fix the request parameters                   |
| `402`  | Insufficient credits      | Tell the user to top up credits on Ploval    |
| `502`  | AI provider error         | Retry once; if persistent, report            |
| `500`  | Database error            | Retry once                                   |

All errors return `{ success: false, error: "..." }`. A `402` also includes `errorType: "INSUFFICIENT_CREDITS"`.

---

## Example interactions

**"Show me the back of this character"**
→ `image_url: <url>`, `horizontal_angle: 180`

**"Generate a right-side view of this product"**
→ `image_url: <url>`, `horizontal_angle: 90`

**"Show this person from a 45-degree angle"**
→ `image_url: <url>`, `horizontal_angle: 45`

**"Bird's eye view of this scene"**
→ `image_url: <url>`, `vertical_angle: 45`

**"Low angle heroic shot"**
→ `image_url: <url>`, `vertical_angle: -30`
