# Ploval Image Models

Pass one of these **alias strings** as the `model` field.  
**Default when the user does not specify a model:** `nano-banana-2`

| Alias                   | Description                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------ |
| `nano-banana-2`         | **Default** — Nano Banana 2; supports optional reference images (single or multiple) |
| `nano-banana-2-edit`    | Explicit edit variant of Nano Banana 2                                               |
| `nano-banana`           | Nano Banana (fast, cost-effective)                                                   |
| `nano-banana-pro`       | Nano Banana Pro (higher quality)                                                     |
| `flux-2-pro`            | Flux 2 Pro — strong photorealism; supports multiple reference images                 |
| `flux-1.1-pro`          | Flux 1.1 Pro                                                                         |
| `flux-pro`              | Flux Pro                                                                             |
| `flux-schnell`          | Flux Schnell (fastest, lowest cost)                                                  |
| `flux-dev`              | Flux Dev                                                                             |
| `flux-kontext-pro`      | Flux Kontext Pro — context-aware editing                                             |
| `flux-kontext-max`      | Flux Kontext Max — highest-quality context editing                                   |
| `seedream-v4.5`         | Seedream v4.5                                                                        |
| `seedream-v5-lite`      | Seedream v5 Lite                                                                     |
| `seedream-v5-lite-edit` | Seedream v5 Lite edit variant                                                        |
| `grok-imagine`          | Grok Imagine (reference: first image only if multiple supplied)                      |
| `gpt-image-1`           | GPT Image 1                                                                          |
| `gpt-image-1-edit`      | GPT Image 1 edit variant                                                             |
| `gpt-image-1.5`         | GPT Image 1.5                                                                        |
| `gpt-image-1.5-edit`    | GPT Image 1.5 edit variant                                                           |

When the user wants maximum quality photorealism, suggest `flux-2-pro`.

Pass reference URLs in the request body as **`input_images`**: a string array (`["https://..."]` for one image, or more strings for multiple).

Reference URLs must be **publicly accessible** HTTPS links the API can fetch.
