---
name: chraft-generate-music
description: Generate music or songs via the Chraft media API. Use this skill whenever the user wants to create, compose, or generate any kind of music, background track, song, or audio — even if they don't say "generate" explicitly. Supports two providers: ElevenLabs (fast, prompt-based, up to 60s, returns immediately) and Suno (full song with lyrics, vocals, and custom style, async). Authentication is handled automatically from the sandbox user context.
---

# Chraft — Music Generation

This skill generates music by calling Chraft's `/api/openclaw/media/music` endpoint.

Two providers are available:

| Provider               | Best for                                     | Mode                                         | Cost       |
| ---------------------- | -------------------------------------------- | -------------------------------------------- | ---------- |
| `elevenlabs` (default) | Background music, short tracks, fast results | Synchronous — audio URL returned immediately | 30 credits |
| `suno`                 | Full songs with vocals, lyrics, custom style | Async — poll until complete                  | 50 credits |

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

## Provider A — ElevenLabs (synchronous, default)

Use for background music, ambient tracks, short clips, or any time the user wants a quick result without lyrics.

### Step 1 — Generate

```javascript
const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/music`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    provider: "elevenlabs", // optional — this is the default
    prompt, // music description, style, mood
    duration, // seconds, 1–60 (default: 30)
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Failed to generate music");
}

const data = await res.json();
// data.status === 'completed' — audio is ready immediately
const { audioUrl, duration: actualDuration, creditsConsumed } = data;
```

ElevenLabs is **synchronous** — `audioUrl` is returned directly in the POST response. No polling needed.

**Prompt tips for ElevenLabs:**

- Include vocals/lyrics directly in the prompt: `"upbeat pop song with female vocals singing: [lyrics here]"`
- For instrumental only: add `"instrumental only"` to the prompt
- Be descriptive about mood, genre, tempo, instruments

---

## Provider B — Suno (async, full songs)

Use when the user wants a complete song with vocals, custom lyrics, a specific style, or a named title.

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
🎵 **[Song Title](https://...)**

Provider: ElevenLabs · Duration: 30s · Credits used: 30
```

For Suno with multiple variants:

```markdown
🎵 **Variant 1 — [Title](https://...)**
🎵 **Variant 2 — [Title](https://...)**

Provider: Suno · Credits used: 50
```

The chat UI detects audio URLs (`.mp3`, `.wav`, `.ogg`, `.m4a`) and renders an inline player automatically.

---

## Choosing the right provider

| Signal from user                                           | Provider                                                                                    |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| "background music", "ambient", "quick track", "short clip" | `elevenlabs`                                                                                |
| "song", "with lyrics", "vocals", "write a song about..."   | `suno`                                                                                      |
| Provides lyrics text                                       | `suno` with `custom_mode: true`                                                             |
| Wants instrumental only                                    | Either — pass `instrumental: true` (Suno) or add "instrumental only" to prompt (ElevenLabs) |
| Needs result fast                                          | `elevenlabs`                                                                                |
| Wants full production quality                              | `suno`                                                                                      |

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
→ `provider: "elevenlabs"`, `prompt: "lo-fi hip hop, soft piano, rain sounds, relaxing, instrumental only"`, `duration: 30`

**"Create a chill ambient track for my video"**
→ `provider: "elevenlabs"`, `prompt: "ambient electronic, slow tempo, atmospheric pads, cinematic, instrumental only"`, `duration: 60`

**"Write and generate a pop song about summer"**
→ `provider: "suno"`, `prompt: "<generated lyrics>`, `style: "pop, upbeat, female vocals"`, `title: "Summer Vibes"`

**"Generate an instrumental jazz track"**
→ `provider: "suno"`, `prompt: "smooth jazz, saxophone, piano, upright bass"`, `instrumental: true`, `model: "V4_5"`

**"Make a song with these lyrics: [user provides lyrics]"**
→ `provider: "suno"`, `prompt: "<user's lyrics>"`, `style: "<inferred style>"`, `title: "<inferred title>"`
