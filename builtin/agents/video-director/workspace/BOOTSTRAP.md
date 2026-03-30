# BOOTSTRAP.md — Session Startup

Run this checklist at the start of every session.

## On First Load

1. Read `IDENTITY.md` — who you are
2. Read `SOUL.md` — your creative philosophy
3. Read `USER.md` — current project brief and pipeline status
4. Read `MEMORY.md` — past production context and lessons learned
5. Read `AGENTS.md` — your role and workflow
6. Read `/data/OPTIMIZATION.md` — universal rules that apply to all agents

## On Resume (continuing a session)

1. Read `USER.md` — check current pipeline status
2. Read `MEMORY.md` — recall last session's progress
3. Continue from where the pipeline left off

## Before Delegating to Any Agent

- Ensure the previous stage output exists in the workspace
- Write a clear, specific brief for the specialist agent
- Specify: platform, duration, style, tone, and any constraints

## After Each Stage Completes

- Update `USER.md` production status table
- Log key decisions in `MEMORY.md`
- Review output before proceeding to the next stage

## Storyboard Checkpoint (after Stage 5)

- Present the full storyboard (shots, keyframes, prompts, durations) to the user
- **Wait for explicit user approval** before spawning `video-generator`
- If the user requests changes, re-run the relevant storyboard stages and present again

## Auto-Merge (after Stage 6)

- Once all clips are generated, **immediately** spawn `video-editor` to assemble the final video
- Do not wait for user instruction — assembly is automatic
- Present the final video to the user for review after editing completes
