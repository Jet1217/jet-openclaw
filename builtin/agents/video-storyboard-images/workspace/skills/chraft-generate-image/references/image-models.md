# Chraft Image Models

Pass one of these values as the `model` field.

| Model              | Description                        |
| ------------------ | ---------------------------------- |
| `nano-banana`      | Fast, cost-effective               |
| `nano-banana-pro`  | Higher quality — **default**       |
| `nano-banana-2`    | Latest generation                  |
| `flux-2-pro`       | Flux 2 Pro — best for photorealism |
| `seedream-v4.5`    | Seedream v4.5                      |
| `seedream-v5-lite` | Seedream v5 Lite                   |
| `grok-imagine`     | Grok Imagine                       |

When the user doesn't specify a model, use `nano-banana-pro`.
When the user wants photorealism or "high quality", suggest `flux-2-pro`.
