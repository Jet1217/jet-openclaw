# Chraft Video Models

Pass the full model ID string as the `model` field. Short aliases (e.g. `kling3.0-pro`) are also accepted by the API.

---

## Kling Series (Kuaishou)

| Model ID                                                | Mode    | Max Duration          |
| ------------------------------------------------------- | ------- | --------------------- |
| `fal-ai/kling-video/v3/pro/text-to-video`               | T2V     | 15s                   |
| `fal-ai/kling-video/v3/pro/image-to-video`              | I2V     | 15s                   |
| `fal-ai/kling-video/v3/standard/text-to-video`          | T2V     | 15s — **default T2V** |
| `fal-ai/kling-video/v3/standard/image-to-video`         | I2V     | 15s — **default I2V** |
| `fal-ai/kling-video/v2.6/pro/text-to-video`             | T2V     | 10s                   |
| `fal-ai/kling-video/v2.6/pro/image-to-video`            | I2V     | 10s                   |
| `fal-ai/kling-video/v2.5-turbo/pro/text-to-video`       | T2V     | 10s                   |
| `fal-ai/kling-video/v2.5-turbo/standard/image-to-video` | I2V     | 10s                   |
| `kwaivgi/kling-v2.5-turbo-pro`                          | T2V+I2V | 10s                   |
| `kwaivgi/kling-v2.1`                                    | I2V     | 10s                   |
| `kwaivgi/kling-v2.1-master`                             | T2V+I2V | 10s                   |
| `fal-ai/kling-video/v1.6/standard/text-to-video`        | T2V     | 10s                   |
| `fal-ai/kling-video/v1.6/standard/image-to-video`       | I2V     | 10s                   |
| `fal-ai/kling-video/o1/image-to-video`                  | I2V     | 10s                   |
| `fal-ai/kling-video/o1/standard/image-to-video`         | I2V     | 10s                   |
| `fal-ai/kling-video/o3/standard/reference-to-video`     | I2V     | 15s                   |
| `fal-ai/kling-video/o3/pro/reference-to-video`          | I2V     | 15s                   |

---

## Seedance Series (ByteDance)

| Model ID                     | Mode    | Max Duration       |
| ---------------------------- | ------- | ------------------ |
| `seedance2/text-to-video`    | T2V     | 15s                |
| `seedance2/image-to-video`   | I2V     | 15s                |
| `seedance2/omni-reference`   | T2V+I2V | 15s                |
| `bytedance/seedance-1.5-pro` | T2V+I2V | 12s — native audio |
| `bytedance/seedance-1-pro`   | T2V+I2V | 12s                |

---

## Google Veo Series

| Model ID              | Mode    | Max Duration           |
| --------------------- | ------- | ---------------------- |
| `google/veo-3.1`      | T2V+I2V | 8s — native audio, R2V |
| `google/veo-3.1-fast` | T2V+I2V | 8s                     |

---

## OpenAI Sora 2

| Model ID                           | Mode | Max Duration |
| ---------------------------------- | ---- | ------------ |
| `fal-ai/sora-2/text-to-video`      | T2V  | 12s          |
| `fal-ai/sora-2/text-to-video/pro`  | T2V  | 12s          |
| `fal-ai/sora-2/image-to-video`     | I2V  | 12s          |
| `fal-ai/sora-2/image-to-video/pro` | I2V  | 12s          |

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
