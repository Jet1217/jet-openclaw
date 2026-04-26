# Chraft Video Models

Pass the **alias** as the `model` field. The server maps it to the internal model ID.

---

## Kling Series (Kuaishou)

| Alias                   | Mode    | Max Duration          |
| ----------------------- | ------- | --------------------- |
| `kling3-pro`            | T2V     | 15s                   |
| `kling3-pro-i2v`        | I2V     | 15s                   |
| `kling3-standard`       | T2V     | 15s — **default T2V** |
| `kling3-standard-i2v`   | I2V     | 15s — **default I2V** |
| `kling2.6-pro`          | T2V     | 10s                   |
| `kling2.6-pro-i2v`      | I2V     | 10s                   |
| `kling2.5-pro`          | T2V     | 10s                   |
| `kling2.5-pro-i2v`      | I2V     | 10s                   |
| `kling2.5-turbo`        | T2V+I2V | 10s                   |
| `kling2.1`              | I2V     | 10s                   |
| `kling2.1-master`       | T2V+I2V | 10s                   |
| `kling1.6-standard`     | T2V     | 10s                   |
| `kling1.6-standard-i2v` | I2V     | 10s                   |
| `kling-o1-i2v`          | I2V     | 10s                   |
| `kling-o1-standard-i2v` | I2V     | 10s                   |
| `kling-o3-ref`          | I2V     | 15s                   |
| `kling-o3-pro-ref`      | I2V     | 15s                   |

---

## Seedance Series (ByteDance)

| Alias                 | Mode    | Duration | Notes                                                           |
| --------------------- | ------- | -------- | --------------------------------------------------------------- |
| `seedance2`           | T2V     | 4–15s    | Seedance 2.0 standard                                           |
| `seedance2-i2v`       | I2V     | 4–15s    | `start_image_url` required; pass `end_image_url` for transition |
| `seedance2-omni`      | T2V+I2V | 4–15s    | Seedance 2.0 standard                                           |
| `seedance2-fast`      | T2V     | 4–15s    | Seedance 2.0 Fast — lower cost, faster                          |
| `seedance2-fast-i2v`  | I2V     | 4–15s    | `start_image_url` required; pass `end_image_url` for transition |
| `seedance2-fast-omni` | T2V+I2V | 4–15s    | Seedance 2.0 Fast                                               |
| `seedance1.5`         | T2V+I2V | 12s      | native audio — **default model**                                |
| `seedance1`           | T2V+I2V | 12s      |                                                                 |

---

## Google Veo Series

| Alias         | Mode    | Max Duration      |
| ------------- | ------- | ----------------- |
| `veo3.1`      | T2V+I2V | 8s — native audio |
| `veo3.1-fast` | T2V+I2V | 8s                |

---

## OpenAI Sora 2

| Alias           | Mode | Max Duration                      |
| --------------- | ---- | --------------------------------- |
| `sora2`         | T2V  | 20s — use for UGC ads/commercials |
| `sora2-pro`     | T2V  | 20s                               |
| `sora2-i2v`     | I2V  | 20s                               |
| `sora2-i2v-pro` | I2V  | 20s                               |

---

## MiniMax Hailuo

| Alias            | Mode    | Max Duration |
| ---------------- | ------- | ------------ |
| `hailuo2.3`      | T2V+I2V | 10s          |
| `hailuo2.3-fast` | I2V     | 10s          |
| `hailuo2`        | T2V+I2V | 10s          |

---

## Wan Video

| Alias             | Mode       | Max Duration |
| ----------------- | ---------- | ------------ |
| `wan2.7`          | T2V        | 15s          |
| `wan2.7-i2v`      | I2V        | 15s          |
| `wan2.7-edit`     | I2V (edit) | 15s          |
| `wan2.7-ref`      | I2V (ref)  | 15s          |
| `wan2.2`          | I2V        | 5s           |
| `wan2.2-fast`     | I2V        | 5s           |
| `wan2.2-t2v-fast` | T2V        | 5s           |

---

## Vidu

| Alias         | Mode | Max Duration       |
| ------------- | ---- | ------------------ |
| `vidu-q3`     | T2V  | 16s — native audio |
| `vidu-q3-i2v` | I2V  | 16s — native audio |

---

## Grok

| Alias            | Mode | Max Duration |
| ---------------- | ---- | ------------ |
| `grok-video`     | T2V  | 15s          |
| `grok-video-i2v` | I2V  | 15s          |

---

## PixVerse

| Alias               | Mode | Max Duration                             |
| ------------------- | ---- | ---------------------------------------- |
| `pixverse-v6`       | T2V  | 15s — native audio, 360p/540p/720p/1080p |
| `pixverse-v6-i2v`   | I2V  | 15s — native audio, first+last frame     |
| `pixverse-v5.6`     | T2V  | 10s                                      |
| `pixverse-v5.6-i2v` | I2V  | 10s — first+last frame                   |
| `pixverse-v5.5`     | T2V  | 10s                                      |
| `pixverse-v5.5-i2v` | I2V  | 10s — first+last frame                   |
| `pixverse-v5`       | T2V  | 8s                                       |
| `pixverse-v5-i2v`   | I2V  | 8s — first+last frame                    |
