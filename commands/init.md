---
description: One-time per project. Adds a docs-discipline declaration to CLAUDE.md (creating it if needed) and copies drift-check.sh into scripts/. Imposes no doc structure.
---

You are setting up docs-discipline for the current project. The current working directory is the project root.

## What you must do

1. **Locate the plugin's assets directory.** It is at `${CLAUDE_PLUGIN_ROOT}/assets/` when installed via `/plugin install`, or at the plugin's local path when running under `claude --plugin-dir`. Use Bash to verify the directory exists before proceeding. If you cannot locate it, report the error and stop — do not invent content.

   The two assets you need:
   - `claude-md-stub.md` — the declaration block to add to CLAUDE.md
   - `drift-check.sh` — the drift detection script

2. **Handle `CLAUDE.md`** in the project root:
   - If `CLAUDE.md` does NOT exist → create it with exactly the stub content (read the file, write it verbatim).
   - If `CLAUDE.md` DOES exist → check whether it already contains the marker line `This project uses [docs-discipline]`.
     - If yes → leave CLAUDE.md unchanged. Report "already set up."
     - If no → append the stub content to the end of CLAUDE.md, preceded by a single blank line for separation. Do not modify any existing content.

3. **Copy `drift-check.sh`** to the project:
   - Ensure `scripts/` directory exists in the project root (create if missing).
   - If `scripts/drift-check.sh` does not exist → copy the asset there and `chmod +x`.
   - If `scripts/drift-check.sh` exists with identical content → do nothing.
   - If `scripts/drift-check.sh` exists with different content → **do not overwrite**. Report the conflict, show the user a diff, and ask how to proceed.

4. **Report** the outcome to the user, listing exactly what was created, appended, copied, or skipped. Be specific about file paths.

## What you must NOT do

- Do not create `docs/`, `spikes/`, `adr/`, or any other directory beyond `scripts/`.
- Do not write governance philosophy, SSOT structure, layer models, status symbol systems, or templates into CLAUDE.md beyond what is literally in the stub.
- Do not "improve" or expand the stub content. If you find yourself adding "best practices" or "tips", stop.
- Do not touch any other files in the project.

## Edge cases

- If the current directory is not a git repository: warn the user, then proceed anyway. drift-check has reduced functionality without git (timestamp comparison is skipped), but `init` and `codify` still work.
- If the user has multiple CLAUDE.md candidates (e.g., one in the repo root and one under a subdirectory): operate on the one at the current working directory only.

## Idempotency contract

Running `init` twice in a row must result in no second-pass changes (other than possibly re-asserting `chmod +x`). The marker check on CLAUDE.md and the content-hash check on `drift-check.sh` make this safe.
