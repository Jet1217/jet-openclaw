---
name: chraft-analyze-video
description: Analyze video content using Chraft's AI vision API. Use this skill whenever the user wants to understand, describe, inspect, or extract information from a video — including YouTube videos, TikTok/Instagram Reels, and direct video file URLs (.mp4, .mov, etc.). This skill returns a structured analysis with video metadata, scene-by-scene breakdown, and a Sora2 regeneration prompt. Use this even if the user says "what's in this video", "describe this clip", "analyze this reel", or "clone/remix this video" (analysis step).
---

# Chraft — Video Analysis

This skill analyzes videos by calling Chraft's `/api/openclaw/media/analyze` endpoint. It supports YouTube URLs (analyzed directly via OpenRouter), TikTok / Instagram Reels, and direct video file URLs (`.mp4`, `.mov`, etc.) — the latter two are automatically downloaded and uploaded to Gemini before analysis.

The response always contains three structured sections:

1. **Video Metadata** — duration and aspect ratio
2. **Detailed Video Analysis** — scene-by-scene breakdown with visuals, camera work, and audio
3. **Sora2 Generation Prompt** — a ready-to-use prompt for recreating a similar video

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

## Step 1 — Call the analyze endpoint

```javascript
const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/analyze`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    video_url: videoUrl, // YouTube, TikTok, Instagram Reels, or direct .mp4/.mov URL
    prompt: prompt, // optional — omit to use the default full analysis
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "Video analysis failed");
}

const { success, data } = await res.json();
if (!success) throw new Error("Video analysis returned unsuccessful response");
```

The endpoint handles platform detection, downloading, and Gemini upload automatically. No polling required — the response is returned once analysis is complete (typically 15–60 seconds).

### Supported URL types

| URL pattern                                    | Platform  |
| ---------------------------------------------- | --------- |
| `youtube.com` / `youtu.be`                     | YouTube   |
| `tiktok.com` / `vm.tiktok.com`                 | TikTok    |
| `instagram.com/reel` or `/reels`               | Instagram |
| Direct file URL ending in `.mp4`, `.mov`, etc. | Direct    |

### Prompt guidance

| Goal                          | Suggested `prompt`                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------------- |
| General description (default) | omit `prompt` field                                                                   |
| Clone / recreate the video    | `"Analyze this video for cloning. Describe every scene, style, and camera movement."` |
| Style / aesthetic analysis    | `"Analyze the visual style, color grading, and editing rhythm of this video."`        |
| Specific question             | Any natural-language question about the video content                                 |

---

## Step 2 — Present the analysis

The `data` field is a markdown string. Render it directly:

```markdown
## Video Metadata:

**Video Duration:** 15 seconds
**Aspect Ratio:** 9:16

## Detailed Video Analysis:

### Scene 1 (00:00 - 00:05):

- **Visuals:** ...
- **Camera:** ...
- **Audio:** ...

...

## Sora2 Prompt for Creating Similar Video:

[Ready-to-use generation prompt]
```

After rendering, offer the user next steps:

- **Generate a similar video** → use the `chraft-generate-video` skill with the extracted Sora2 prompt and detected aspect ratio
- **Ask follow-up questions** → re-run this skill with a more specific `prompt`

---

## Error handling

| Status | Error pattern                | Meaning                       | What to do                                                      |
| ------ | ---------------------------- | ----------------------------- | --------------------------------------------------------------- |
| `401`  | —                            | API key not found or inactive | Check sandbox is running and paired                             |
| `400`  | `URL_ROBOTED` / `robots.txt` | Video URL blocked             | Ask user to use YouTube, TikTok, or upload directly             |
| `400`  | `Unsupported video URL`      | Platform not supported        | Ask user to use YouTube, TikTok, Instagram Reels, or direct URL |
| `429`  | —                            | AI rate limit exceeded        | Wait a few seconds and retry once                               |
| `504`  | `download timeout`           | Video download took too long  | Suggest a shorter video or YouTube URL                          |
| `500`  | —                            | Server or AI provider error   | Retry once; if persistent, report to user                       |

All errors return `{ success: false, error: "..." }`.

---

## Example interactions

**"What happens in this YouTube video? https://youtu.be/abc123"**
→ POST `video_url: "https://youtu.be/abc123"`, no prompt (default analysis)

**"Analyze this TikTok for cloning: https://vm.tiktok.com/xyz"**
→ POST `video_url: "https://vm.tiktok.com/xyz"`, `prompt: "Analyze this video for cloning. Describe every scene, style, and camera movement."`

**"Describe the visual style of this video: https://example.com/clip.mp4"**
→ POST `video_url: "https://example.com/clip.mp4"`, `prompt: "Analyze the visual style, color grading, and editing rhythm of this video."`

**"What's the aspect ratio and duration of this Instagram reel?"**
→ POST `video_url: "https://instagram.com/reel/..."`, `prompt: "What is the aspect ratio and duration of this video?"`
