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

## 3. Agent vs. Skill — Decision Table

| User says                     | Correct action                                            |
| ----------------------------- | --------------------------------------------------------- |
| "Create an agent that does X" | Create a new permanent agent at `/data/workspace-<name>/` |
| "I want an agent named X"     | Create a new permanent agent at `/data/workspace-<name>/` |
| "Add X capability to agent Y" | Create a skill under `/data/workspace-<name>/skills/`     |
| "Create a skill for X"        | Create a skill (`SKILL.md`) — this is valid and correct   |
| "Create a tool for X"         | Create a skill (`SKILL.md`) — this is valid and correct   |
| "Add a tool to agent Y"       | Create a skill under `/data/workspace-<name>/skills/`     |

---

## 4. Language

All code comments and file content must be in **English**.
