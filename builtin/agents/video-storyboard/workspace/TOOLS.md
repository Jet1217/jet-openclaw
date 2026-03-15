# TOOLS.md

## Output Files

- `storyboard.md` — complete storyboard with all shot cards
- `shot-list.md` — condensed table for quick reference

## Shot List Table Format

| Shot | Scene | Duration | Type | Movement | Image Prompt (short) |
| ---- | ----- | -------- | ---- | -------- | -------------------- |
| 1    | 1     | 3s       | WS   | Dolly In | ...                  |

## Handoff to video-storyboard-images

Pass `storyboard.md` with the IMAGE PROMPT from each shot card.

## Handoff to video-generator

Pass `storyboard.md` with the VIDEO PROMPT from each shot card.
