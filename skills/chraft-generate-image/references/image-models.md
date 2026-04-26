# Chraft Image Models

Pass one of these **alias strings** as the `model` field.  
**Default when the user does not specify a model:** `nano-banana-2`

## Recommended (Modern) Models

These are the preferred models for all new generations and edits:

| Alias                   | Description                                                                          | Best for                                            |
| ----------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------- |
| `nano-banana-2`         | **Default** — Nano Banana 2; supports optional reference images (single or multiple) | General text-to-image, fast turnaround              |
| `nano-banana-2-edit`    | Explicit edit/inpaint variant of Nano Banana 2                                       | Direct edit/inpaint requests                        |
| `nano-banana-pro`       | Nano Banana Pro — higher quality output                                              | High-quality generation and editing                 |
| `flux-2-pro`            | Flux 2 Pro — strong photorealism; supports multiple reference images                 | Photorealistic scenes, multi-reference conditioning |
| `gpt-image-2`           | GPT Image 2 — latest GPT-based image model                                           | High-fidelity, instruction-following generation     |
| `gpt-image-2-edit`      | GPT Image 2 edit variant                                                             | High-fidelity edits and inpainting                  |
| `seedream-v5-lite`      | Seedream v5 Lite                                                                     | Artistic / stylized generation                      |
| `seedream-v5-lite-edit` | Seedream v5 Lite edit variant                                                        | Artistic style edits                                |

## Model Selection Guide

| Goal                           | Use                                     |
| ------------------------------ | --------------------------------------- |
| Default generation             | `nano-banana-2`                         |
| Higher quality generation      | `nano-banana-pro`                       |
| Photorealism / multi-reference | `flux-2-pro`                            |
| GPT-powered high fidelity      | `gpt-image-2`                           |
| Default edit / inpaint         | `nano-banana-2` or `nano-banana-2-edit` |
| Precise GPT edit               | `gpt-image-2-edit`                      |
| Artistic edit                  | `seedream-v5-lite-edit`                 |

## Legacy Models (Avoid for New Work)

These older models are still available but should not be used as defaults:

| Alias                | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| `nano-banana`        | Nano Banana (original, superseded by nano-banana-2)             |
| `seedream-v4.5`      | Seedream v4.5 (superseded by v5)                                |
| `grok-imagine`       | Grok Imagine (reference: first image only if multiple supplied) |
| `gpt-image-1.5`      | GPT Image 1.5 (superseded by 2)                                 |
| `gpt-image-1.5-edit` | GPT Image 1.5 edit variant (superseded by 2-edit)               |
| `gpt-image-1`        | GPT Image 1 (superseded by 2)                                   |
| `gpt-image-1-edit`   | GPT Image 1 edit variant (superseded by 2-edit)                 |

Pass reference URLs in the request body as **`input_images`**: a string array (`["https://..."]` for one image, or more strings for multiple).

Reference URLs must be **publicly accessible** HTTPS links the API can fetch.
