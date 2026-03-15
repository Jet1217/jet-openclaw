#!/bin/sh
set -eu

# Seed agent workspace templates from the image into the persistent data volume
# on first boot. Files that already exist are never overwritten, so user
# customizations survive container restarts and image upgrades.
#
# Layout inside the image:  /app/builtin/agents/<name>/workspace/
# Layout on the data volume: /data/workspace          (for "main")
#                            /data/workspace-<name>   (for all others)

DATA_DIR="${DATA_DIR:-/data}"
AGENTS_SRC="/app/builtin/agents"

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
        # Merge new skill dirs from image into existing /data/workspace/skills
        # so that newly added builtin skills appear without overwriting user skills.
        for skill_src in "$f"/*; do
          [ -e "$skill_src" ] || continue
          skill_name="$(basename "$skill_src")"
          skill_dst="${dst_file}/${skill_name}"
          # Only skip if the skill dir already has a SKILL.md (i.e. it was
          # previously seeded correctly). An empty or partial directory is
          # treated as if it doesn't exist so the skill gets re-seeded.
          if [ -e "${skill_dst}/SKILL.md" ]; then
            continue
          fi
          rm -rf "$skill_dst"
          cp -r "$skill_src" "$skill_dst"
        done
      fi
    done
  done
fi

exec "$@"
