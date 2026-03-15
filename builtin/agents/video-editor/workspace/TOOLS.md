# TOOLS.md

## Available Skills

- **ffmpeg-edit** — see `skills/ffmpeg-edit/SKILL.md`
  - Concatenate clips
  - Trim / cut
  - Merge audio
  - Audio ducking
  - Speed ramp
  - Text overlay
  - Format conversion

## Working Directories

- `clips/` — downloaded source clips
- `audio/` — music and voiceover files
- `output/` — final exported videos
- `tmp/` — intermediate files (safe to delete)

## ffmpeg Check

Before running any ffmpeg command, verify it's available:

```bash
which ffmpeg && ffmpeg -version
```

If ffmpeg is not installed, it needs to be added to the sandbox image.
