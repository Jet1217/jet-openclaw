# TOOLS.md

## Available Skills

- **chraft-generate-video** — see `skills/chraft-generate-video/SKILL.md`

## Model Quick Reference

| Series         | T2V Model                                      | I2V Model                                       | Best For           |
| -------------- | ---------------------------------------------- | ----------------------------------------------- | ------------------ |
| Kling v3       | `fal-ai/kling-video/v3/standard/text-to-video` | `fal-ai/kling-video/v3/standard/image-to-video` | Default, versatile |
| Kling v3 Pro   | `fal-ai/kling-video/v3/pro/text-to-video`      | `fal-ai/kling-video/v3/pro/image-to-video`      | Higher quality     |
| Seedance 1.5   | `bytedance/seedance-1.5-pro`                   | —                                               | Product/brand      |
| Google Veo 3.1 | `google/veo-3.1`                               | —                                               | Cinematic          |
| Sora 2         | `openai/sora-2`                                | —                                               | Photorealistic     |

See `skills/chraft-generate-video/references/video-models.md` for the full list.

## Output Files

- `video-clips.md` — all generated clips with URLs and metadata
