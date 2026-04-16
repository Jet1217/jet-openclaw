#!/bin/sh
set -eu

# Seed agent workspace templates from the image into the persistent data volume
# on first boot. Files that already exist are never overwritten, so user
# customizations survive container restarts and image upgrades.
#
# Layout inside the image:  /app/builtin/agents/<name>/workspace/
# Layout on the data volume: /data/workspace          (for "main")
#                            /data/workspace-<name>   (for all others)
#                            /data/projects/           (shared project deliverables)

DATA_DIR="${DATA_DIR:-/data}"
AGENTS_SRC="/app/builtin/agents"
BUILTIN_SKILLS_LIST="/app/builtin/.builtin-skills"

# Ensure the shared projects directory exists for cross-agent project isolation.
mkdir -p "${DATA_DIR}/projects"

if [ -d "$AGENTS_SRC" ]; then
  # Copy root-level files (e.g. OPTIMIZATION.md) directly into /data/
  for f in "$AGENTS_SRC"/*; do
    [ -f "$f" ] || continue
    fname="$(basename "$f")"
    dst_file="${DATA_DIR}/${fname}"
    if [ ! -e "$dst_file" ]; then
      cp "$f" "$dst_file"
    fi
  done

  for agent_src in "$AGENTS_SRC"/*/; do
    agent_name="$(basename "$agent_src")"
    if [ "$agent_name" = "main" ]; then
      agent_dst="${DATA_DIR}/workspace"
    else
      agent_dst="${DATA_DIR}/workspace-${agent_name}"
    fi
    mkdir -p "$agent_dst"
    for f in "$agent_src"workspace/*; do
      [ -e "$f" ] || continue
      fname="$(basename "$f")"
      dst_file="${agent_dst}/${fname}"
      if [ ! -e "$dst_file" ]; then
        cp -r "$f" "$dst_file"
      elif [ "$fname" = "skills" ] && [ -d "$f" ]; then
        # Merge skill dirs from image into the existing skills directory.
        #
        # Two categories:
        #   Builtin skills  — listed as "<agent>:<skill>" in /app/builtin/.builtin-skills.
        #                     Always replaced with the image version so updates are
        #                     delivered on every container restart after an image upgrade.
        #   User skills     — anything NOT in the whitelist.  Never overwritten so
        #                     user customisations survive upgrades.
        for skill_src in "$f"/*; do
          [ -e "$skill_src" ] || continue
          skill_name="$(basename "$skill_src")"
          skill_dst="${dst_file}/${skill_name}"
          if grep -qx "${agent_name}:${skill_name}" "$BUILTIN_SKILLS_LIST" 2>/dev/null; then
            # Builtin skill: always update from image to deliver new versions.
            rm -rf "$skill_dst"
            cp -r "$skill_src" "$skill_dst"
          else
            # User skill: only seed if not already present.
            if [ -e "${skill_dst}/SKILL.md" ]; then
              continue
            fi
            rm -rf "$skill_dst"
            cp -r "$skill_src" "$skill_dst"
          fi
        done
      fi
    done
  done
fi

exec "$@"
