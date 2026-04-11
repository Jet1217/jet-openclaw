---
name: video-inspiration
description: Research and gather creative inspiration for video production from the internet. Use when the user wants to brainstorm video ideas, find visual references, explore concepts or styles, search for mood boards, look up trending content, find example footage, or gather textual and visual inspiration for a video project. Triggers on phrases like "find inspiration for", "search for references", "look up examples of", "find images for", "what style should I use", "mood board for", "research ideas for my video".
---

# Video Inspiration Research

This skill helps gather creative inspiration for video projects by searching the internet for:

- **Concept references** — visual and textual examples of a specific idea
- **Style references** — cinematography, color grading, motion aesthetics
- **Trend discovery** — what's performing well in a genre or niche
- **Mood board material** — curated images/screenshots that define a look
- **Competitive research** — similar videos or creators in a space

---

## Workflow

### Step 1 — Clarify intent

Extract from the user's request:

- **Topic / concept**: what the video is about
- **Target platform**: TikTok, YouTube, Instagram Reels, commercial, film, etc.
- **Style or mood** (if mentioned): cinematic, lo-fi, UGC, editorial, etc.
- **Output goal**: mood board, prompt improvement, style guide, concept validation

If any of these are unclear, ask one focused question rather than several at once.

---

### Step 2 — Search strategy

Choose search methods based on availability. Use in priority order:

#### A. Web search (always available)

Use the `WebSearch` tool to find:

- Text articles, breakdowns, trend reports
- YouTube/TikTok video recommendations (return titles + links)
- Behance, Pinterest, and Dribbble concept galleries
- Film/video style guides, color palette references
- Reddit threads with creative discussion on the concept

Suggested query patterns:

```
"[concept] video style reference site:pinterest.com"
"[concept] color palette mood board"
"[style] cinematography examples"
"[topic] TikTok trend 2026"
"[niche] video aesthetic inspiration"
```

#### B. Fetch specific pages

Use `WebFetch` to retrieve content from discovered URLs — especially:

- Pinterest board pages
- Behance project pages
- YouTube video descriptions
- Blog posts on visual style

When fetching, extract:

- Image URLs (for visual reference)
- Key descriptive text (for prompt building)
- Style vocabulary (color, texture, motion, mood words)

#### C. Multiple parallel searches

Run several `WebSearch` calls in parallel for efficiency:

- One for **visual/image** references
- One for **text/concept** references
- One for **platform-specific trends**

---

### Step 3 — Organise results

Present findings in this structure:

```
## Inspiration Board — [Topic]

### Concept Overview
[1–2 sentence summary of what you found]

### Visual References
[Image URLs or embedded markdown images, with captions]

### Style Keywords
[10–20 words/phrases that capture the visual language — usable directly in prompts]

### Recommended Viewing
[3–5 links to videos or campaigns with a one-line note on what to borrow from each]

### Prompt Seeds
[2–3 ready-to-use video generation prompts built from the references]
```

---

### Step 4 — Offer next steps

After presenting the board, offer:

1. **Generate a reference image** → hand off to `chraft-generate-image` skill
2. **Generate a video** → hand off to `chraft-generate-video` skill
3. **Refine the search** → narrow by platform, color, era, or mood
4. **Export as a prompt** → distil all findings into a single generation prompt

---

## Platform-Specific Tips

| Platform         | What to search for                                               |
| ---------------- | ---------------------------------------------------------------- |
| TikTok / Reels   | "trending [niche] TikTok 2026", "viral [topic] hook styles"      |
| YouTube          | "[topic] cinematic short film", "[brand] YouTube ad breakdown"   |
| Commercial / UGC | "UGC [product category] examples", "[brand] ad creative 2026"    |
| Film / Narrative | "[genre] color grading LUT", "[director] visual style reference" |
| Music Video      | "[genre] music video aesthetic", "[artist] visual treatment"     |

---

## Style Vocabulary Extraction

When reading reference pages, extract and highlight these attributes to build generation prompts:

- **Lighting**: golden hour, neon, overcast, high-key, chiaroscuro
- **Color palette**: desaturated, teal-and-orange, warm analog, monochrome
- **Camera movement**: handheld, slow push, drone, static wide
- **Texture / grain**: film grain, clean digital, VHS, anamorphic flare
- **Pacing / edit style**: fast cuts, long takes, montage, slow motion
- **Subject framing**: close-up talking head, wide establishing, POV

---

## Example Interactions

**"Find inspiration for a TikTok video about matcha lattes"**
→ Search: matcha aesthetic TikTok 2026, café color palette mood board, ASMR food video style
→ Return: visual refs, style keywords, 2 prompt seeds in 9:16

**"I need references for a cinematic travel video in Japan"**
→ Search: Japan travel film cinematography, wabi-sabi visual style, Japanese street photography mood board
→ Return: image board, filmmaker references, style vocab, prompt seed for Seedance or Kling

**"What visual style is trending for luxury brand ads?"**
→ Search: luxury fashion ad creative 2026, high-end product video aesthetic, editorial cinematography
→ Return: trend summary, 4–5 campaign references, color palette, generation prompt

**"Find me references for a dark moody horror short"**
→ Search: horror short film color grading, dark cinematic mood board, chiaroscuro video reference
→ Return: visual board with image URLs, lighting vocab, recommended films, prompt seed
