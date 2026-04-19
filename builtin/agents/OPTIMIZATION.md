# OPTIMIZATION.md — Universal Agent Rules

This file is shared across all agents. Every agent must load and follow these rules in addition to their own role-specific instructions.

---

## 1. Creating Agents vs. Creating Skills

Both agents and skills are valid things to create. Use the right one based on what the user asks for.

### The distinction:

- **Agent** = a new permanent resident agent with its own runtime directory at `/data/workspace-<agent-name>/` and the full set of workspace files.
- **Skill** = a tool/capability that an agent uses, living under `skills/<skill-name>/SKILL.md` in the agent's workspace. Skills are valid to create when the user asks for a new capability or tool.

**Only** when a user explicitly asks to **create an agent** (by name, role, or intent) should you create a full agent. Creating a skill is NOT a substitute for creating an agent in that case — but skills are perfectly valid to create on their own or to support a new agent.

### When creating a new agent, always:

1. Create all required workspace files under `/data/workspace-<agent-name>/` (see template below)
2. Register the agent in the platform if applicable
3. The agent is a **permanent (resident) agent**, not a temporary one

### Required workspace files for every new agent:

| File           | Content                                           |
| -------------- | ------------------------------------------------- |
| `IDENTITY.md`  | Name, role, avatar URL, one-paragraph description |
| `SOUL.md`      | Personality, working philosophy, tone             |
| `AGENTS.md`    | Role definition, workflow, output format          |
| `BOOTSTRAP.md` | Session startup checklist                         |
| `HEARTBEAT.md` | Periodic background check template                |
| `MEMORY.md`    | Persistent memory template                        |
| `TOOLS.md`     | Skills list and notes                             |
| `USER.md`      | User/project context (starts empty)               |

All agent files must follow the same pattern as existing agents (e.g. `music-composer` at `/data/workspace-music-composer/`, `video-director` at `/data/workspace-video-director/`).

### Required skills for every new agent:

Every new agent **MUST** install the `self-improving-agent` skill under
`/data/workspace-<agent-name>/skills/self-improving-agent/`. This skill is what
lets the agent observe its own work, update its MEMORY.md, and evolve over time.

An agent without `self-improving-agent` is a frozen agent — it will never
learn from experience, even if dreaming is enabled at the platform level.

---

## 2. Error Memory — Learn and Don't Repeat

When you encounter an error and discover how to fix it:

1. **Fix it immediately.**
2. **Document it in the agent's `MEMORY.md`** under a `## Lessons Learned` section.
3. The record must include:
   - What the error was
   - What caused it
   - How it was fixed
   - What to do differently next time

**Every agent is responsible for its own `MEMORY.md`.** The `main` agent also keeps a cross-agent record of significant lessons.

This rule applies to all agents including `main`. Never repeat a previously documented mistake.

---

## 3. Auto-Save Memory — Every Agent, Every Session

Every agent (main, subagents, third-party agents) **MUST** actively save
memorable information, not wait for automatic triggers. Relying only on the
platform's memory flush is insufficient — short subagent sessions almost never
hit the token threshold that triggers it.

### What to save, when:

1. **User facts & preferences** — the moment a user reveals something durable
   (stack preference, project naming conventions, brand tone, past mistakes to
   avoid), append it to `MEMORY.md` under `## Key Facts About the User` or
   `## Preferences & Decisions` before moving on.
2. **Lessons learned** — any error + fix pair goes under `## Lessons Learned`
   in the same turn the fix is verified (see section 2).
3. **Recurring project context** — when the same project slug is seen again,
   update `MEMORY.md` with what was learned during that project run.
4. **Daily observations** — significant events that are not yet durable enough
   for `MEMORY.md` go to `memory/YYYY-MM-DD.md`. Dreaming will promote them
   into `MEMORY.md` once they recur and score highly enough.

### Why this matters

The platform runs a background **dreaming** pass that scores short-term recall
signals and promotes qualified entries into long-term memory. Dreaming can
only promote what the agent has written down. If the agent silently completes
tasks without journaling, nothing survives the session and the agent never
evolves.

**Rule of thumb:** if you would want a future version of yourself to know it,
write it now.

---

## 4. Agent vs. Skill — Decision Table

| User says                     | Correct action                                            |
| ----------------------------- | --------------------------------------------------------- |
| "Create an agent that does X" | Create a new permanent agent at `/data/workspace-<name>/` |
| "I want an agent named X"     | Create a new permanent agent at `/data/workspace-<name>/` |
| "Add X capability to agent Y" | Create a skill under `/data/workspace-<name>/skills/`     |
| "Create a skill for X"        | Create a skill (`SKILL.md`) — this is valid and correct   |
| "Create a tool for X"         | Create a skill (`SKILL.md`) — this is valid and correct   |
| "Add a tool to agent Y"       | Create a skill under `/data/workspace-<name>/skills/`     |

---

## 5. Spawning Agents — Always Pass `agentId`

When using `sessions_spawn`, you **MUST** always pass the `agentId` parameter with the exact agent ID of the target agent.

**Without `agentId`, the spawned session becomes a copy of yourself** — it reads YOUR workspace, uses YOUR config, and has YOUR identity. The `label` parameter is just a display name; it does NOT select which agent runs.

```
// CORRECT — spawns the video-script agent
sessions_spawn(agentId: "video-script", task: "...", mode: "run")

// WRONG — spawns a copy of the CALLER, not video-script
sessions_spawn(label: "video-script", task: "...", mode: "run")
```

---

## 6. Project Folder Isolation

Different projects **MUST** store their outputs in separate project folders. All project data lives under a **shared** `/data/projects/` directory so that every agent can read and write to the same project files directly — no cross-workspace path juggling required.

> **This rule applies to ALL agents**, including third-party agents installed from zip packages. This file (`OPTIMIZATION.md`) is automatically injected into every agent's system prompt at runtime — you are bound by these rules regardless of what your own `AGENTS.md` says about file paths.

### Layout

```
/data/
├── workspace/                     (main agent config)
├── workspace-<agent-name>/        (per-agent config, memory, skills)
└── projects/                      (shared across ALL agents)
    ├── <project-slug>/
    │   ├── brief.md
    │   ├── production-plan.md
    │   ├── characters.md
    │   ├── script.md
    │   ├── storyboard.md
    │   ├── storyboard-images.md
    │   ├── video-clips.md
    │   ├── clips/                 (downloaded video clips)
    │   └── output/                (final rendered videos)
    └── <another-project>/
        └── ...
```

All agents read and write to the **same** `/data/projects/<slug>/` folder. There is no per-agent duplication — `video-script` writes `/data/projects/<slug>/script.md`, `video-storyboard` reads it from the same path, etc.

### How to detect the project slug

When you are spawned as a subagent, check your task brief for a `project:` field. It will appear as the **first line** of the task:

```
project: coffee-ad-tiktok
<rest of the brief...>
```

- If the task contains `project: <slug>`, you **MUST** save all output files under `/data/projects/<slug>/`.
- If no `project:` field is present (e.g. standalone direct chat), save to your own workspace as usual.

### Rules

1. **The orchestrator (e.g. `video-director`) creates the project slug** from the brief — use a short, lowercase, hyphenated name derived from the project title or topic (e.g. `coffee-ad-tiktok`, `summer-sale-promo`). Include a date prefix if ambiguity is likely: `2026-03-30-coffee-ad`.
2. **Every `sessions_spawn` task brief MUST include `project: <slug>` as the first line** so the specialist agent knows the project folder.
3. **All agents save deliverables under `/data/projects/<slug>/`** — the same shared directory. For example, `video-script` saves `/data/projects/coffee-ad/script.md`, and `video-storyboard` reads it from the same path.
4. **Agent config files (`AGENTS.md`, `SOUL.md`, `MEMORY.md`, etc.) remain in each agent's own workspace.** Only project deliverables go into `/data/projects/<slug>/`.
5. **The `main` agent passes the project slug** when spawning an orchestrator. If the user doesn't name the project, `main` generates a slug from the request.
6. **When spawning a sub-agent that you expect to produce files**, always forward the `project: <slug>` line in the task brief so the sub-agent writes to the same project folder.

### Project slug format

- Lowercase alphanumeric + hyphens only
- Max 60 characters
- Examples: `coffee-brand-ad`, `2026-03-30-product-launch`, `music-video-sunset`

---

## 7. Language

All code comments and file content must be in **English**.
