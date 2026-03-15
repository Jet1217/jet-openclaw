# TOOLS.md

## Skills

- `skills/chraft-generate-music/SKILL.md` — generate music via ElevenLabs or Suno

## Output Files

- `composition-brief.md` — the interpreted brief before generation (optional, for complex requests)
- `lyrics.md` — written lyrics before submission to Suno (for songs with lyrics)
- `session-log.md` — log of generated tracks this session (title, provider, audioUrl, credits)

## Handoff

If this agent is used within a larger pipeline (e.g. video production):

1. Pass the generated `audioUrl` (or `audioUrls` array for Suno) to the next agent
2. Include: title, duration, provider, style tags used, whether it has vocals
