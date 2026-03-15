---
name: chraft-generate-music
description: Generate music or songs via the Chraft media API. Use this skill whenever the user wants to create, compose, or generate any kind of music, background track, song, or audio — even if they don't say "generate" explicitly. Uses Suno (full song with lyrics, vocals, and custom style, async). Authentication is handled automatically from the sandbox user context.
---

# Chraft — Music Generation

This skill generates music by calling Chraft's `/api/openclaw/media/music` endpoint using Suno.

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

## Suno — async, full songs (50 credits)

Use when the user wants any music: background tracks, full songs with vocals, custom lyrics, instrumental, or a specific style.

### Step 1 — Start the generation job

```javascript
const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/music`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    provider: "suno",
    prompt, // song description (simple mode) OR lyrics text (custom mode)
    style, // music style tags, e.g. "pop, upbeat, female vocals"
    title, // song title (optional)
    instrumental, // true = no vocals (default: false)
    model, // "V3_5" | "V4" | "V4_5" | "V4_5PLUS" | "V5" (default: V3_5)
    negative_tags, // styles/elements to avoid (optional, max 200 chars)
    vocal_gender, // "m" | "f" (optional)
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to start music generation");
}

const { audioId, taskId, estimatedTime, creditsConsumed } = await res.json();
```

**Suno mode selection:**

- `custom_mode` is auto-inferred: if you provide both `style` + `title`, custom mode activates automatically
- In custom mode, `prompt` is treated as the **lyrics** (max 3000 chars for V3_5/V4, 5000 for newer)
- In simple mode, `prompt` is a song description (max 500 chars)

### Step 2 — Poll for completion

Suno typically takes 60–120 seconds. Poll every 5 seconds with a 3-minute timeout.

```javascript
const deadline = Date.now() + 180_000; // 3 minutes

while (Date.now() < deadline) {
  await new Promise((r) => setTimeout(r, 5000));

  const poll = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/music?audio_id=${audioId}`, {
    headers: authHeaders(),
  });
  const data = await poll.json();

  if (data.status === "completed" || data.status === "succeeded") {
    // data.audioUrls is an array — Suno typically returns 2 song variants
    return data.audioUrls; // string[]
  }
  if (data.status === "failed" || data.status === "error") {
    throw new Error("Music generation failed");
  }
  // processing → keep polling
}

throw new Error("Music generation timed out after 3 minutes");
```

---

## Step 3 — Present results

Always present the audio inline so the chat UI renders a player:

```markdown
🎵 **Variant 1 — [Title](https://...)**
🎵 **Variant 2 — [Title](https://...)**

Provider: Suno · Credits used: 50
```

The chat UI detects audio URLs (`.mp3`, `.wav`, `.ogg`, `.m4a`) and renders an inline player automatically.

---

## Error handling

| Status | Meaning                              | What to do                                   |
| ------ | ------------------------------------ | -------------------------------------------- |
| `401`  | Key not found or inactive            | Check that the sandbox is running and paired |
| `400`  | Missing `prompt` or invalid provider | Fix the request parameters                   |
| `402`  | Insufficient credits                 | Tell the user to top up credits on Chraft    |
| `502`  | AI provider error                    | Retry once; if persistent, report            |
| `500`  | Database error                       | Retry once                                   |

All errors return `{ success: false, error: "..." }`. A `402` also includes `errorType: "INSUFFICIENT_CREDITS"`.

---

## Example interactions

**"Generate 30 seconds of lo-fi background music"**
→ `provider: "suno"`, `prompt: "lo-fi hip hop, soft piano, rain sounds, relaxing"`, `instrumental: true`, `model: "V4_5"`

**"Create a chill ambient track for my video"**
→ `provider: "suno"`, `prompt: "ambient electronic, slow tempo, atmospheric pads, cinematic"`, `instrumental: true`, `model: "V4_5"`

**"Write and generate a pop song about summer"**
→ `provider: "suno"`, `prompt: "<generated lyrics>"`, `style: "pop, upbeat, female vocals"`, `title: "Summer Vibes"`

**"Generate an instrumental jazz track"**
→ `provider: "suno"`, `prompt: "smooth jazz, saxophone, piano, upright bass"`, `instrumental: true`, `model: "V4_5"`

**"Make a song with these lyrics: [user provides lyrics]"**
→ `provider: "suno"`, `prompt: "<user's lyrics>"`, `style: "<inferred style>"`, `title: "<inferred title>"`
