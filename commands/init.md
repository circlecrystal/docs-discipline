---
description: One-time per project. Adds a docs-discipline declaration to CLAUDE.md (creating it if needed) with A/B layer slots, then copies drift-check.sh into scripts/. Imposes no doc structure.
---

You are setting up docs-discipline for the current project. The current working directory is the project root.

## What you must do

### 1. Locate the plugin's assets directory

It is at `${CLAUDE_PLUGIN_ROOT}/assets/` when installed via `/plugin install`, or at the plugin's local path under `claude --plugin-dir`. Use Bash to verify the directory exists. If you cannot locate it, report the error and stop — do not invent content.

Assets you need:
- `claude-md-stub.md` — declaration block + A/B section to add to CLAUDE.md
- `drift-check.sh` — the drift detection script

### 2. Handle `CLAUDE.md`

**Case A — `CLAUDE.md` does NOT exist** (greenfield project):

1. Read the stub asset.
2. **Probe the project structure** to find A-layer and B-layer candidates (see § A/B probing below).
3. Write `CLAUDE.md` using the stub content. In the two A/B slots, if you found candidates, **replace the placeholder comment** with a comment listing them, prefixed with `Detected candidates (keep, edit, or clear):`. If no candidates were found for a layer, leave the original placeholder comment unchanged.

**Case B — `CLAUDE.md` DOES exist**:

1. Check whether it already contains the marker line `This project uses [docs-discipline]`.
   - If yes → leave CLAUDE.md unchanged. Report "already set up."
   - If no → append ONLY the top declaration block (the first part of the stub, up to but NOT including `## Doc layers (A/B)`). Use a single blank line for separation.
2. **Do NOT add the A/B section** to an existing CLAUDE.md. Reason: the user may already have governance content there, and force-adding A/B risks conflict. Codify will gently surface this on its first run instead.

### 3. Copy `drift-check.sh`

- Ensure `scripts/` directory exists in the project root (create if missing).
- If `scripts/drift-check.sh` does not exist → copy the asset there and `chmod +x`.
- If it exists with identical content → do nothing.
- If it exists with different content → do NOT overwrite. Report the conflict, show a diff, and ask how to proceed.

### 4. Report

List exactly what was created, appended, copied, or skipped. Be specific about file paths. If A/B candidates were probed, summarize what was suggested.

## A/B probing (only in Case A above)

Use `git ls-files` (or `find` if not in a git repo) to scan project files. Look for:

**A-layer candidates** (immutable, dated artifacts):
- Files with date-prefixed names: `adr-YYYY-MM-DD-*.md`, `session-YYYY-*.md`, `YYYY-MM-DD-*.md`
- Files with numbered/identified prefixes: `spike-S[0-9]*.md`, `S[0-9]*-*.md`, `decision-*.md`
- Directories suggesting artifact storage: `history/`, `logs/`, `sessions/`, `spikes/`, `decisions/`, `adr/`, `archive/`, `journal/`

**B-layer candidates** (living SSOT):
- `README.md` at project root
- `docs/README.md`
- Files matching: `STATUS.md`, `ROADMAP.md`, `CURRENT.md`, `STATE.md`
- Markdown files whose first 50 lines contain words like "current state", "status", "roadmap", "snapshot"

For each candidate, write a SHORT bullet describing what it is. Keep candidate lists to ≤5 items per layer; if there are more, sample representatively.

If **no** candidates found for a layer → do not invent any. Leave the placeholder comment untouched.

## What you must NOT do

- ❌ Do not create `docs/`, `spikes/`, `adr/`, or any other business directory beyond `scripts/`.
- ❌ Do not write any governance philosophy or templates into CLAUDE.md beyond what is in the stub.
- ❌ Do not "improve" or expand the stub content.
- ❌ Do not add A/B section to an existing CLAUDE.md (Case B).
- ❌ Do not invent A/B candidates when none were detected — empty placeholder is fine; codify will ask later.
- ❌ Do not modify any user file beyond CLAUDE.md and scripts/.

## Edge cases

- If the current directory is not a git repository: probing uses `find` instead of `git ls-files`. Warn the user that drift-check has reduced functionality without git, then proceed.
- If `CLAUDE.md` is in a subdirectory rather than the project root: operate on the project root only.

## Idempotency contract

Running `init` twice must result in no second-pass changes (other than possibly re-asserting `chmod +x`). The marker check on `CLAUDE.md` and the content-hash check on `drift-check.sh` make this safe.
