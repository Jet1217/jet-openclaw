---
name: chraft-upload-file
description: Upload a local sandbox file or a remote URL to Chraft's permanent cloud storage (R2). Use this skill whenever a tool has generated a file on disk (image, video, audio, PDF, etc.) and you need to share it with the user as a viewable/downloadable link. Also use it to permanently re-host a temporary CDN URL before it expires. Supports files up to 500 MB via presigned direct upload.
---

# Chraft — File Upload to Cloud Storage

This skill uploads files to Chraft's permanent R2 cloud storage and returns a stable public URL.
All files are stored under `sandbox/{userId}/...` — fully isolated per user.

The skill automatically picks the right upload strategy based on file size:

| File size  | Strategy                                                      |
| ---------- | ------------------------------------------------------------- |
| < 4 MB     | Server buffer upload (one request)                            |
| ≥ 4 MB     | Presigned URL → direct PUT to R2 (two requests, up to 500 MB) |
| Remote URL | Server-side re-host (one request, up to 200 MB)               |

---

## Load credentials from sandbox context

```javascript
import fs from "fs";
import path from "path";

const stateDir = process.env.OPENCLAW_STATE_DIR || "/data";
const ctx = JSON.parse(fs.readFileSync(path.join(stateDir, "user-context.json"), "utf8"));
const { chraftUseKey } = ctx;
const CHRAFT_BASE_URL = process.env.CHRAFT_BASE_URL || "https://chraft.ai";

function authHeaders(contentType = "application/json") {
  return {
    "Content-Type": contentType,
    Authorization: `Bearer ${chraftUseKey}`,
  };
}
```

---

## uploadFile() — unified helper (use this in all skills)

This single function handles all three modes automatically. Copy it into your skill.

```javascript
/**
 * Upload a local file or remote URL to Chraft R2.
 * @param {string} source  - Local file path (e.g. '/tmp/out.mp4') or remote https:// URL
 * @param {string} [filenameHint]  - Override the stored filename (optional)
 * @returns {Promise<string>}  Public URL on success, throws on failure
 */
async function uploadFile(source, filenameHint) {
  // ── Remote URL: re-host via server ──────────────────────────────────────
  if (source.startsWith("http://") || source.startsWith("https://")) {
    const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/upload`, {
      method: "POST",
      headers: authHeaders(),
      body: JSON.stringify({ url: source, filename: filenameHint }),
    });
    const data = await res.json();
    if (!data.success) throw new Error(data.error || "URL re-host failed");
    return data.url;
  }

  // ── Local file ───────────────────────────────────────────────────────────
  const fileBuffer = fs.readFileSync(source);
  const filename = filenameHint || path.basename(source);
  const fileSizeBytes = fileBuffer.length;

  const formData = new FormData();
  formData.append("file", new Blob([fileBuffer]), filename);

  const res = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/upload`, {
    method: "POST",
    headers: { Authorization: `Bearer ${chraftUseKey}` },
    body: formData,
  });
  const data = await res.json();
  if (!data.success) throw new Error(data.error || "Upload failed");

  // ── Small file: done ─────────────────────────────────────────────────────
  if (!data.needsPresign) return data.url;

  // ── Large file: PUT directly to R2 with presigned URL ───────────────────
  const putRes = await fetch(data.uploadUrl, {
    method: "PUT",
    headers: { "Content-Type": data.contentType },
    body: fileBuffer,
  });
  if (!putRes.ok) throw new Error(`Presigned PUT failed: ${putRes.status} ${putRes.statusText}`);

  // Confirm upload and get final public URL
  const confirmRes = await fetch(`${CHRAFT_BASE_URL}/api/openclaw/media/upload/confirm`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify({ key: data.key }),
  });
  const confirmData = await confirmRes.json();
  if (!confirmData.success) throw new Error(confirmData.error || "Confirm failed");

  return confirmData.url;
}
```

---

## Usage examples

**Upload a local file after a tool generates it:**

```javascript
// After ffmpeg generates a video
const cloudUrl = await uploadFile("/tmp/output.mp4");
// → "https://cdn.chraft.ai/sandbox/{userId}/videos/uuid-output.mp4"
```

**Upload with a custom filename:**

```javascript
const cloudUrl = await uploadFile("/workspace/render.png", "my-artwork.png");
```

**Re-host a temporary CDN URL permanently:**

```javascript
const permanentUrl = await uploadFile(
  "https://replicate.delivery/pbxt/abc123/result.mp4",
  "generated-video.mp4",
);
```

---

## Response format

**Small file / URL re-host** (`needsPresign: false`):

```json
{
  "success": true,
  "needsPresign": false,
  "url": "https://cdn.chraft.ai/sandbox/{userId}/videos/uuid-output.mp4",
  "filename": "output.mp4",
  "contentType": "video/mp4",
  "size": 4194304,
  "category": "videos"
}
```

**Large file** (`needsPresign: true`) — first response:

```json
{
  "success": true,
  "needsPresign": true,
  "uploadUrl": "https://r2-presigned-url...",
  "publicUrl": "https://cdn.chraft.ai/sandbox/{userId}/videos/uuid-output.mp4",
  "key": "sandbox/{userId}/videos/uuid-output.mp4",
  "filename": "output.mp4",
  "contentType": "video/mp4",
  "category": "videos"
}
```

**Confirm response** (after presigned PUT):

```json
{
  "success": true,
  "url": "https://cdn.chraft.ai/sandbox/{userId}/videos/uuid-output.mp4",
  "key": "sandbox/{userId}/videos/uuid-output.mp4"
}
```

---

## Present the result in chat

After uploading, always present the file inline so the chat UI renders it:

**Images:**

```markdown
![Description](https://cdn.chraft.ai/sandbox/...)
```

**Videos:**

```markdown
![Video title](https://cdn.chraft.ai/sandbox/...)
```

**Other files (PDF, audio, zip, etc.):**

```markdown
[Download filename.pdf](https://cdn.chraft.ai/sandbox/...)
```

The chat UI automatically detects image and video URLs and renders them with a preview and download button.

---

## Size limits

| Path                               | Limit  |
| ---------------------------------- | ------ |
| Small file (server buffer, < 4 MB) | 4 MB   |
| Large file (presigned PUT, ≥ 4 MB) | 500 MB |
| URL re-host                        | 200 MB |

---

## Error handling

| Status | Meaning                         | What to do                                    |
| ------ | ------------------------------- | --------------------------------------------- |
| `401`  | Invalid API key                 | Check sandbox is running and paired           |
| `400`  | Missing file / invalid URL      | Fix the request parameters                    |
| `403`  | Key doesn't belong to this user | Never modify the `key` returned by the server |
| `413`  | File exceeds size limit         | Compress or split the file                    |
| `500`  | R2 error                        | Retry once; if persistent, report             |

All errors return `{ success: false, error: "..." }`.

---

## Full example — generate image, upload, present

```javascript
// 1. Generate image with chraft-generate-image skill
const { imageUrls } = await generateImage({ model: "nano-banana-pro", prompt: "..." });

// 2. Re-host to permanent storage (imageUrls are already R2 URLs, but this ensures longevity)
const permanentUrl = await uploadFile(imageUrls[0], "generated-image.png");

// 3. Present in chat
return `![Generated Image](${permanentUrl})`;
```

## Full example — run ffmpeg, upload result

```javascript
import { execSync } from "child_process";

// 1. Process video with ffmpeg
execSync("ffmpeg -i /data/input.mp4 -vf scale=1280:-1 -c:v libx264 /tmp/output.mp4");

// 2. Upload (automatically uses presigned path if > 10 MB)
const cloudUrl = await uploadFile("/tmp/output.mp4", "processed-video.mp4");

// 3. Present in chat
return `Processing complete!\n\n![Processed Video](${cloudUrl})`;
```
