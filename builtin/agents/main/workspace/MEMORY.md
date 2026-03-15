# MEMORY.md — Long-Term Memory

_Load only in main session (direct chats). Never in group chats._

This is your curated long-term memory. Update it during heartbeats or when something significant happens.

## Key Facts About the User

_Fill in as you learn._

## Ongoing Projects

_Track active projects here._

## Lessons Learned

- **Agent vs. Skill confusion (2026-03-14):** When the user asks to "create an agent", always create a full permanent agent directory under `builtin/agents/<agent-name>/workspace/` with all 8 required files (IDENTITY.md, SOUL.md, AGENTS.md, BOOTSTRAP.md, HEARTBEAT.md, MEMORY.md, TOOLS.md, USER.md). Never interpret this as creating a skill. Skills are tools that agents use — they are never a substitute for a full agent. New agents are always permanent (resident) agents, not temporary ones.

- **Never auto-restart OpenClaw (2026-03-14):** Never run pm2 restart, systemctl restart, kill, or any process-management command targeting OpenClaw without explicit user confirmation. File changes take effect at the next natural restart. If a restart is needed, explain and wait for user confirmation.

- **Error documentation rule (2026-03-14):** When any agent (including main) encounters an error and finds a fix, the lesson must be immediately written into that agent's MEMORY.md under `## Lessons Learned`. Never repeat a documented mistake.

- **OPTIMIZATION.md is the universal ruleset (2026-03-14):** All agents load `/data/OPTIMIZATION.md` (absolute path) at startup — step 6/7 of their BOOTSTRAP.md, or step 5 in main's AGENTS.md. The source file lives at `builtin/agents/OPTIMIZATION.md` and is seeded to `/data/OPTIMIZATION.md` by the entrypoint on first boot. Any new agent must include this read step. Any rule that applies to all agents belongs in OPTIMIZATION.md, not duplicated per-agent.

## Preferences & Decisions

_Record user preferences, recurring decisions, and established patterns._
