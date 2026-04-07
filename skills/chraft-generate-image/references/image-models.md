# Chraft Image Models

Pass one of these **exact** strings as the `model` field (they match the server `ImageModel` enum).  
**Default when the user does not specify a model:** `fal-ai/nano-banana-2` (Nano Banana 2 on Fal).

| Model                                             | Description                                                                                  |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `fal-ai/nano-banana-2`                            | **Default** — latest Nano Banana 2; supports optional reference images (single or multiple). |
| `fal-ai/nano-banana-2/edit`                       | Same Fal routing as `fal-ai/nano-banana-2`; use when you want an explicit edit model id.     |
| `google/nano-banana`                              | Fast, cost-effective                                                                         |
| `google/nano-banana-pro`                          | Higher-quality Nano Banana Pro                                                               |
| `black-forest-labs/flux-2-pro`                    | Flux 2 Pro — strong photorealism; supports multiple reference images on Fal                  |
| `fal-ai/bytedance/seedream/v4.5/text-to-image`    | Seedream v4.5                                                                                |
| `fal-ai/bytedance/seedream/v5/lite/text-to-image` | Seedream v5 Lite                                                                             |
| `xai/grok-imagine-image`                          | Grok Imagine (reference: first image only if multiple supplied)                              |

When the user wants maximum quality photorealism, suggest `black-forest-labs/flux-2-pro`.

Pass reference URLs in the request body as **`input_images`**: a string array (`["https://..."]` for one image, or more strings for multiple).

Reference URLs must be **publicly accessible** HTTPS links the API can fetch.
