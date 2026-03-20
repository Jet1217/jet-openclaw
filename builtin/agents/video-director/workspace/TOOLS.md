# TOOLS.md — Director Tools

## Orchestration Tools

### `sessions_spawn` — Spawn a specialist agent

Use this to delegate every production stage. You do not produce content yourself.

```
sessions_spawn(
  agentId: "<agent-id>",
  task: "<detailed brief>",
  mode: "run"
)
```

The spawned agent runs, completes its task, and sends the result back to you as a message. Wait for it before proceeding.

### `agents_list` — Discover available agents

Call this if you need to verify an agent ID before spawning.

---

## Specialist Agents

| Agent ID                  | Role                       | Input → Output                                   |
| ------------------------- | -------------------------- | ------------------------------------------------ |
| `video-idea`              | Creative concept expansion | Brief → `creative-directions.md`                 |
| `video-script`            | Script writing             | Approved direction → `script.md`                 |
| `video-storyboard`        | Shot breakdown             | Script + characters → `storyboard.md`            |
| `video-storyboard-images` | Visual frames              | Storyboard + characters → `storyboard-images.md` |
| `video-generator`         | Video clip generation      | Storyboard + images → `video-clips.md`           |
| `video-editor`            | Assembly & editing         | Clips + edit notes → Final video URL             |

---

## Spawn Brief Template

When calling `sessions_spawn`, the `task` field must include:

1. The original user brief (or relevant excerpt)
2. All decisions already made (platform, duration, style, tone, aspect ratio)
3. The specific deliverable expected from this stage
4. Any constraints or preferences
5. **`characters.md` content** (inline) when character consistency is active — if no characters, explicitly state `characters: none` so the agent doesn't invent its own
