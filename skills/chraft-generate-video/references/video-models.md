# Ploval Video Models

Pass the full model ID string as the `model` field. Short aliases (e.g. `kling3.0-pro`) are also accepted by the API.

---

## Kling Series (Kuaishou)

Kling 3 supported duration range: **3–15 s** (integer seconds).

| Model ID                                                | Mode    | Max Duration |
| ------------------------------------------------------- | ------- | ------------ |
| `fal-ai/kling-video/v3/pro/text-to-video`               | T2V     | 15s          |
| `fal-ai/kling-video/v3/pro/image-to-video`              | I2V     | 15s          |
| `fal-ai/kling-video/v3/standard/text-to-video`          | T2V     | 15s          |
| `fal-ai/kling-video/v3/standard/image-to-video`         | I2V     | 15s          |
| `fal-ai/kling-video/v2.6/pro/text-to-video`             | T2V     | 10s          |
| `fal-ai/kling-video/v2.6/pro/image-to-video`            | I2V     | 10s          |
| `fal-ai/kling-video/v2.5-turbo/pro/text-to-video`       | T2V     | 10s          |
| `fal-ai/kling-video/v2.5-turbo/standard/image-to-video` | I2V     | 10s          |
| `kwaivgi/kling-v2.5-turbo-pro`                          | T2V+I2V | 10s          |
| `kwaivgi/kling-v2.1`                                    | I2V     | 10s          |
| `kwaivgi/kling-v2.1-master`                             | T2V+I2V | 10s          |
| `fal-ai/kling-video/v1.6/standard/text-to-video`        | T2V     | 10s          |
| `fal-ai/kling-video/v1.6/standard/image-to-video`       | I2V     | 10s          |
| `fal-ai/kling-video/o1/image-to-video`                  | I2V     | 10s          |
| `fal-ai/kling-video/o1/standard/image-to-video`         | I2V     | 10s          |
| `fal-ai/kling-video/o3/standard/reference-to-video`     | I2V     | 15s          |
| `fal-ai/kling-video/o3/pro/reference-to-video`          | I2V     | 15s          |

---

## Seedance Series (ByteDance)

Seedance 2.0 supported duration range: **4–15 s** (any integer).

| Model ID                        | Mode    | Max Duration | Notes                                              |
| ------------------------------- | ------- | ------------ | -------------------------------------------------- |
| `seedance2/text-to-video`       | T2V     | 15s          | Seedance 2.0 standard                              |
| `seedance2/image-to-video`      | I2V     | 15s          | Seedance 2.0 standard — requires `start_image_url` |
| `seedance2/omni-reference`      | T2V+I2V | 15s          | Seedance 2.0 standard                              |
| `seedance2/fast/text-to-video`  | T2V     | 15s          | Seedance 2.0 Fast — lower cost, faster             |
| `seedance2/fast/image-to-video` | I2V     | 15s          | Seedance 2.0 Fast — requires `start_image_url`     |
| `seedance2/fast/omni-reference` | T2V+I2V | 15s          | Seedance 2.0 Fast                                  |
| `bytedance/seedance-1.5-pro`    | T2V+I2V | 4–12s        | native audio, flexible duration                    |
| `bytedance/seedance-1-pro`      | T2V+I2V | 12s          |                                                    |

---

## Google Veo Series

| Model ID              | Mode    | Max Duration           |
| --------------------- | ------- | ---------------------- |
| `google/veo-3.1`      | T2V+I2V | 8s — native audio, R2V |
| `google/veo-3.1-fast` | T2V+I2V | 8s                     |

---

## OpenAI Sora 2

Supported durations: **4, 8, 12, 16, 20 s** (fixed steps only — do not pass arbitrary values).

| Model ID                           | Mode | Max Duration |
| ---------------------------------- | ---- | ------------ |
| `fal-ai/sora-2/text-to-video`      | T2V  | 20s          |
| `fal-ai/sora-2/text-to-video/pro`  | T2V  | 20s          |
| `fal-ai/sora-2/image-to-video`     | I2V  | 20s          |
| `fal-ai/sora-2/image-to-video/pro` | I2V  | 20s          |

---

## MiniMax Hailuo

| Model ID                  | Mode    | Max Duration |
| ------------------------- | ------- | ------------ |
| `minimax/hailuo-2.3`      | T2V+I2V | 10s          |
| `minimax/hailuo-2.3-fast` | I2V     | 10s          |
| `minimax/hailuo-02`       | T2V+I2V | 10s          |

---

## Wan Video

| Model ID                               | Mode | Max Duration |
| -------------------------------------- | ---- | ------------ |
| `wan/v2.6/text-to-video`               | T2V  | 15s          |
| `wan/v2.6/image-to-video`              | I2V  | 15s          |
| `fal-ai/wan-25-preview/text-to-video`  | T2V  | 10s          |
| `fal-ai/wan-25-preview/image-to-video` | I2V  | 10s          |
| `wan-video/wan-2.2-t2v-fast`           | T2V  | 5s           |
| `wan-video/wan-2.2-i2v-fast`           | I2V  | 5s           |
| `wan-video/wan-2.2-i2v-a14b`           | I2V  | 5s           |

---

## Vidu

| Model ID                        | Mode | Max Duration       |
| ------------------------------- | ---- | ------------------ |
| `fal-ai/vidu/q3/text-to-video`  | T2V  | 16s — native audio |
| `fal-ai/vidu/q3/image-to-video` | I2V  | 16s — native audio |

---

## Grok

| Model ID                                | Mode | Max Duration |
| --------------------------------------- | ---- | ------------ |
| `xai/grok-imagine-video/text-to-video`  | T2V  | 15s          |
| `xai/grok-imagine-video/image-to-video` | I2V  | 15s          |

---

## PixVerse

Supported durations: **5, 8 s** for v5; **5, 8, 10 s** for v5.5 and v5.6 (10s only available at 720p, not 1080p); **1–15 s** (any integer) for v6.

| Model ID            | Mode | Max Duration | Notes                                                |
| ------------------- | ---- | ------------ | ---------------------------------------------------- |
| `pixverse/v6/t2v`   | T2V  | 15s          | Native audio, multi-clip, 360p/540p/720p/1080p       |
| `pixverse/v6/i2v`   | I2V  | 15s          | Native audio, first+last frame, 360p/540p/720p/1080p |
| `pixverse/v5.6/t2v` | T2V  | 10s          | Native audio; highest quality in v5 series           |
| `pixverse/v5.6/i2v` | I2V  | 10s          | Native audio; pass `start_image_url`                 |
| `pixverse/v5.5/t2v` | T2V  | 10s          | Native audio (ambient + music); multi-clip           |
| `pixverse/v5.5/i2v` | I2V  | 10s          | Native audio; pass `start_image_url`                 |
| `pixverse/v5/t2v`   | T2V  | 8s           | No audio                                             |
| `pixverse/v5/i2v`   | I2V  | 8s           | No audio; pass `start_image_url`                     |

**Transition (first + last frame):** Pass both `start_image_url` and `end_image_url` with any I2V model to interpolate between two frames. Supported on all versions.

**Resolution (`resolution` field):**

- v6: `360p`, `540p`, `hd` (720p), `fhd` (1080p) — all resolutions supported for all durations
- v5 / v5.5 / v5.6: `hd` = 720p (default); `fhd` = 1080p (supported up to 8s only; not available for 10s clips)

**PixVerse v6 aspect ratios (T2V only):** `16:9`, `4:3`, `1:1`, `3:4`, `9:16`, `2:3`, `3:2`, `21:9`

**PixVerse v6 credits (per second with audio):** 360p = 7/s · 540p = 9/s · 720p = 12/s · 1080p = 23/s
