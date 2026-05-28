---
description: Doc health review. Reads CLAUDE.md's A/B map, runs drift scan, and checks for SSOT violations (facts repeated across B-layer files). Adapts to user intent.
---

You are running `/docs-discipline:review` on the current project. This is a doc health checkup — combining A/B state assessment, drift scanning, structural observation, and SSOT consistency check. Adapt your behavior to what the user actually needs right now.

## Intent inference

Read what the user typed alongside the command to infer scope:

| User invocation | Focus |
|---|---|
| `/docs-discipline:review` (bare) | Full health checkup (A/B + drift + SSOT + summary) |
| `/docs-discipline:review for drift` / `... drift only` | Drift scan only, skip A/B gap-fill and SSOT |
| `/docs-discipline:review A/B` / `... layers` | A/B assessment + gap-fill only, skip drift and SSOT |
| `/docs-discipline:review SSOT` / `... ssot` | SSOT consistency scan only, skip drift and A/B gap-fill |
| Other free-form hints | Use judgment; when unclear, default to full health |

## What you must do

### 1. Read CLAUDE.md and assess A/B state

- If `CLAUDE.md` does not exist → ask the user to run `/docs-discipline:init` first, then stop.
- For each of the two A/B slots (A layer / B layer):
  - **Filled** — real prose outside `<!-- -->` blocks. Authoritative.
  - **Suggested** — init-generated `Detected candidates` comment but no prose. Hypothesis to confirm.
  - **Empty** — only the default placeholder, or blank.

### 2. Route by intent

- **"drift only"** → skip to step 4.
- **"SSOT only"** → skip to step 5 (and skip A/B gap-fill, but you still need to know B-layer scope, see step 5).
- **"A/B only" OR A/B is Empty/Suggested**:
  - Run the A/B gap-fill flow (same as codify's): scan project structure for candidates, present them, and offer:
    - (1) Fill in CLAUDE.md with these (preferred)
    - (2) Use these for this review only (no write)
    - (3) Skip A/B entirely for this run
  - Honor the choice. Do not nag.
- **Full health (default)**: continue through steps 3–5.

### 3. Observe project docs structure (briefly)

Adaptively scan: `docs/` if present, `README.md`, any wiki references, per-feature doc files. Note anything structurally odd (giant single-file docs, deeply nested layouts, etc.) to surface in the summary.

### 4. Run drift scan

If intent includes drift:

- Locate `scripts/drift-check.sh` in the project (set up by `/docs-discipline:init`); fall back to `${CLAUDE_PLUGIN_ROOT}/assets/drift-check.sh` if the project copy is missing.
- Run it via Bash. Capture stdout and exit code.
- Present the full script output.

### 5. SSOT consistency scan

If intent includes SSOT (i.e., full health OR explicit "SSOT only"):

**Goal**: identify atomic facts that appear in multiple B-layer files. Same fact in many places means an edit to one risks missing the others — a Not-SSOT pattern that is the root cause of most documentation drift.

**Procedure**:

**(a) Determine the B-layer file set:**
- **Preferred**: parse the "Where this project's B layer lives" section of `CLAUDE.md`. Extract declared file paths / directory patterns. These are the canonical B-layer files for this project.
- **Fallback** (if B-layer slot is Empty / Suggested / user picked "skip A/B"): use heuristic discovery — root `README.md`, `docs/README.md`, `STATUS.md`, `ROADMAP.md`, any markdown file whose first 50 lines contain "current state" / "snapshot" / "status" / "roadmap". Surface in summary that you fell back to heuristics.

**(b) Cap the scan**: read at most 10 B-layer files. If more are declared, sample representatively and note "scanned N of M B-layer files" in the summary.

**(c) Extract "atomic facts" from each file**. Atomic facts are short, restatable claims. Look for:
- **Status assertions** — lines mentioning a status symbol (✅ / ⚠️ / ❌ / 🔴 / 🟡 / 🟢) or status keyword (PASS / FAIL / DONE / TODO / IN PROGRESS / BLOCKED) attached to a named subject.
- **Concrete values** — version strings, counts/totals (e.g., "12/13", "Phase 3"), dated decisions, key commit hashes, configuration values.
- **Named conclusions** — lines starting with `Decision:` / `Conclusion:` / `Status:`, or table rows pairing a named entity with a status/value column.

**(d) Cross-reference across the B-layer file set:**
- Same subject in multiple files with **consistent value** → candidate SSOT violation (intentional restatement that breeds future drift).
- Same subject in multiple files with **inconsistent value** → confirmed drift, high priority.

**(e) Output candidate list** (cap ~20 items, prioritize confirmed drift first, then restatements):
```
SUBJECT                  | LOCATIONS                       | VALUES STATED      | SUGGESTED CANONICAL HOME
<feature X> status       | <fileA>:14 / <fileB>:30         | DONE / DONE        | <fileA> (per CLAUDE.md A/B map)
<decision Y> resolution  | <fileC>:42 / <fileB>:23         | accepted / accepted| <fileC>
release count            | <fileB>:18 / <fileA>:9          | 12/13 / 11/13      | <fileA>  ← VALUE MISMATCH
```

Suggested canonical home: your best guess based on each file's stated purpose in CLAUDE.md's A/B map. If you cannot tell, write "?".

**(f) Do NOT auto-fix.** SSOT scan is triage. The user decides whether each candidate is intentional or drift, and which home is canonical.

### 6. Output doc health summary

Always end with a one-screen summary. Template:

```
=== Doc health summary ===
A layer:  ✓ Filled / 🟡 Suggested / ✗ Empty   — <one-line description>
B layer:  ✓ Filled / 🟡 Suggested / ✗ Empty   — <one-line description>
Drift:    N candidates  (broken links: a / stale ts: b / orphans: c / dup H1: d)
SSOT:     N candidates  (M confirmed drift, P restatement) — scanned N of M B-layer files
Notes:    <any structural observations, or "none">
```

Mark sections `(skipped)` if intent excluded them. If SSOT fell back to heuristic discovery (no A/B map), say so in the SSOT line.

## What you must NOT do

- ❌ Do not auto-fix drift or SSOT candidates. This command is triage, not editing.
- ❌ Do not silently write to CLAUDE.md. A/B writes happen only after the user picks option (1) in step 2.
- ❌ Do not nag. If the user picked "skip A/B" once, do not re-ask in this session.
- ❌ Do not assume A/B has a specific structure. Use what the user declared, or use observation.
- ❌ Do not re-implement drift heuristics in this prompt — defer to `scripts/drift-check.sh`.
- ❌ Do not pretend the SSOT scan is exhaustive. It is heuristic, sampling-based, and LLM-judged. Surface uncertainty in the summary (e.g., "B-layer fallback used — accuracy reduced").
- ❌ Do not modify any user files beyond what the user explicitly approves.

## Relationship to other commands

- **`/docs-discipline:init`** runs once per project to bootstrap CLAUDE.md and copy the drift script.
- **`/docs-discipline:codify`** is the session-end ritual — for sedimenting *new* findings into A and B. Run it when you have session output to land.
- **`/docs-discipline:review`** (this command) is the ad-hoc health checkup — for inspecting docs *without* new findings, ensuring A/B is set up, surfacing drift, and identifying SSOT violations. Run it whenever you want a status read.

If a session has produced findings AND you also want a review, run codify first, then review.
