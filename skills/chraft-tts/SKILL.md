---
name: chraft-tts
description: Convert text to natural-sounding speech via the Ploval TTS API (ElevenLabs). Use this skill whenever the user wants to generate a voiceover, narration, spoken audio, or any text-to-speech output — including phrases like "read this aloud", "generate audio for", "make a voiceover", or "speak this text". Authentication is handled automatically from the sandbox user context; no API key setup required.
---

# Ploval — Text-to-Speech (TTS)

This skill converts text to speech by calling Ploval's `/api/openclaw/media/tts` endpoint, powered by ElevenLabs.

TTS is **synchronous** — the API call returns the audio URL directly, with no polling required. Generation typically takes 3–10 seconds.

**Cost:** 15 credits per request.

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

## Generate speech

```javascript
const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/tts`, {
  method: "POST",
  headers: authHeaders(),
  body: JSON.stringify({
    text, // required — up to 5000 characters
    voice_id, // optional — see voice table below (default: Paige)
    model_id, // optional — see model table below
    stability, // optional — 0.0–1.0 (default: 0.5)
    similarity_boost, // optional — 0.0–1.0 (default: 0.75)
    style, // optional — 0.0–1.0 (default: 0.0)
    use_speaker_boost, // optional — boolean (default: true)
  }),
});

if (!res.ok) {
  const err = await res.json();
  throw new Error(err.error || "TTS generation failed");
}

const { audioUrl, creditsConsumed, metadata } = await res.json();
// audioUrl is an R2-hosted MP3 — render it directly as a player
```

---

## Voices

Use the `voice_id` field with the ElevenLabs ID from the table below. When the user doesn't specify a voice, use **Paige** (default).

| Name                  | ElevenLabs ID          | Gender    | Description              |
| --------------------- | ---------------------- | --------- | ------------------------ |
| **Paige** _(default)_ | `NDTYOmYEjbDIVCKB35i3` | Female 🇺🇸 | Engaging Narrator        |
| Rachel                | `21m00Tcm4TlvDq8ikWAM` | Female 🇺🇸 | Calm & Professional      |
| Jessica               | `cgSgspJ2msm6clMCkdW9` | Female 🇺🇸 | Conversational & Natural |
| Laura                 | `FGY2WhTYpPnrIDTdsKH5` | Female 🇺🇸 | Social & Engaging        |
| Bella                 | `EXAVITQu4vr4xnSDxMaL` | Female 🇺🇸 | Soft & Sweet             |
| Matilda               | `XrExE9yKIg1WjnnlVkGX` | Female 🇺🇸 | Educational & Clear      |
| Josh                  | `TxGEqnHWrfWFTfGW9XjX` | Male 🇺🇸   | Young & Casual           |
| Antoni                | `ErXwobaYiN019PkySvjV` | Male 🇺🇸   | Warm & Friendly          |
| Arnold                | `VR6AewLTigWG4xSOukaG` | Male 🇺🇸   | Strong & Crisp           |
| Ethan                 | `g5CIjZEefAph4nQFvHAz` | Male 🇺🇸   | Smooth & Articulate      |

You can also pass any valid ElevenLabs voice ID (20+ alphanumeric characters) directly.

---

## Models

| model_id                             | Description                                   |
| ------------------------------------ | --------------------------------------------- |
| `eleven_multilingual_v2` _(default)_ | 70+ languages, emotion control — best quality |
| `eleven_turbo_v2_5`                  | Faster generation, good quality               |
| `eleven_v3`                          | Latest V3 model                               |

---

## Voice parameter guide

| Parameter           | Range   | Default | Effect                                            |
| ------------------- | ------- | ------- | ------------------------------------------------- |
| `stability`         | 0.0–1.0 | 0.5     | Low = expressive; High = consistent               |
| `similarity_boost`  | 0.0–1.0 | 0.75    | How closely the output matches the original voice |
| `style`             | 0.0–1.0 | 0.0     | Style exaggeration; 0.0 = neutral                 |
| `use_speaker_boost` | bool    | true    | Enhances similarity to the source speaker         |

---

## Present results

The `audioUrl` is a direct MP3 link. Show it as a markdown audio link so the chat UI renders an inline player:

```markdown
🎙️ **Voiceover ready**

[Listen](https://...)

Voice: Paige · Model: eleven_multilingual_v2 · Credits used: 15
```

The chat UI auto-renders inline audio players for `.mp3`, `.wav`, `.ogg`, and `.m4a` URLs.

---

## Error handling

| Status | Meaning                                         | What to do                                   |
| ------ | ----------------------------------------------- | -------------------------------------------- |
| `401`  | Key not found or inactive                       | Check that the sandbox is running and paired |
| `400`  | Missing `text` or text too long / invalid model | Fix the request parameters                   |
| `402`  | Insufficient credits                            | Tell the user to top up credits on Ploval    |
| `502`  | ElevenLabs API error                            | Retry once; if persistent, report            |
| `500`  | Server error                                    | Retry once                                   |

All errors return `{ success: false, error: "..." }`. A `402` also includes `errorType: "INSUFFICIENT_CREDITS"`.

---

## Example interactions

**"Read this aloud: 'Welcome to our platform!'"**
→ `text: "Welcome to our platform!"`, default voice (Paige)

**"Generate a calm female voiceover for my intro script"**
→ `voice_id: "21m00Tcm4TlvDq8ikWAM"` (Rachel), `stability: 0.7`

**"Make an energetic male narrator say: 'Introducing the future of AI!'"**
→ `voice_id: "VR6AewLTigWG4xSOukaG"` (Arnold), `stability: 0.3`, `style: 0.5`

**"Generate a Japanese voiceover"**
→ `model_id: "eleven_multilingual_v2"` (supports 70+ languages including Japanese)

**"Create a soft ASMR-style reading of this text"**
→ `voice_id: "EXAVITQu4vr4xnSDxMaL"` (Bella), `stability: 0.8`, `similarity_boost: 0.9`, `style: 0.0`
