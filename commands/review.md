---
description: Doc health review. Reads CLAUDE.md's A/B map; if missing, gently helps fill it; if present, runs drift scan. Adapts to user intent.
---

You are running `/docs-discipline:review` on the current project. This is a doc health checkup — combining A/B state assessment, drift scanning, and structural observation. Adapt your behavior to what the user actually needs right now.

## Intent inference

Read what the user typed alongside the command to infer scope:

| User invocation | Focus |
|---|---|
| `/docs-discipline:review` (bare) | Full health checkup (A/B + drift + summary) |
| `/docs-discipline:review for drift` / `... drift only` | Drift scan only, skip A/B gap-fill |
| `/docs-discipline:review A/B` / `... layers` | A/B assessment + gap-fill only, skip drift |
| Other free-form hints | Use judgment; when unclear, default to full health |

## What you must do

### 1. Read CLAUDE.md and assess A/B state

- If `CLAUDE.md` does not exist → ask the user to run `/docs-discipline:init` first, then stop.
- For each of the two A/B slots (A layer / B layer):
  - **Filled** — real prose outside `<!-- -->` blocks. Authoritative.
  - **Suggested** — init-generated `Detected candidates` comment but no prose. Hypothesis to confirm.
  - **Empty** — only the default placeholder, or blank.

### 2. Route by intent

**If "drift only" intent**: skip to step 4.

**If "A/B only" intent or A/B is Empty/Suggested**:
- Run the A/B gap-fill flow (same as codify's): scan project structure for candidates, present them to the user, and offer three options:
  - (1) Fill in CLAUDE.md with these (preferred)
  - (2) Use these for this review only (no write)
  - (3) Skip A/B entirely for this run
- Honor the choice. Do not nag.

**If A/B is Filled and intent is full health**: continue to step 3.

### 3. Observe project docs structure (briefly)

Adaptively scan: `docs/` if present, `README.md`, any wiki references, per-feature doc files. Note anything structurally odd (giant single-file docs, deeply nested layouts, etc.) to surface in the summary.

### 4. Run drift scan

If intent includes drift (i.e., not "A/B only"):
- Locate `scripts/drift-check.sh` in the project (set up by `/docs-discipline:init`); fall back to `${CLAUDE_PLUGIN_ROOT}/assets/drift-check.sh` if the project copy is missing.
- Run it via Bash. Capture stdout and exit code.
- Present the full script output.

### 5. Output doc health summary

Always end with a one-screen summary. Use this template (fill in actual values):

```
=== Doc health summary ===
A layer:  ✓ Filled / 🟡 Suggested / ✗ Empty   — <one-line description>
B layer:  ✓ Filled / 🟡 Suggested / ✗ Empty   — <one-line description>
Drift:    N candidates  (broken links: a / stale ts: b / orphans: c / dup H1: d)
Notes:    <any structural observations, or "none">
```

If you skipped any section due to intent, mark it `(skipped)`.

## What you must NOT do

- ❌ Do not auto-fix drift candidates. This command is triage, not editing.
- ❌ Do not silently write to CLAUDE.md. A/B writes happen only after the user picks option (1).
- ❌ Do not nag. If the user picked "skip A/B" once, do not re-ask in this session.
- ❌ Do not assume A/B has a specific structure. Use what the user declared, or use observation.
- ❌ Do not re-implement drift heuristics in this prompt — defer to `scripts/drift-check.sh`. If the script needs changes, edit it directly.
- ❌ Do not modify any user files beyond what the user explicitly approves.

## Relationship to other commands

- **`/docs-discipline:init`** runs once per project to bootstrap CLAUDE.md and copy the drift script.
- **`/docs-discipline:codify`** is the session-end ritual — for sedimenting *new* findings into A and B. Run it when you have session output to land.
- **`/docs-discipline:review`** (this command) is the ad-hoc health checkup — for inspecting docs *without* new findings, ensuring A/B is set up, and surfacing drift. Run it whenever you want a status read.

If a session has produced findings AND you also want a review, run codify first, then review.
