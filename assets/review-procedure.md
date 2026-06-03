# Doc-health review procedure

> Single source of truth for the doc-health review. Consumed by two callers: the `/docs-discipline:review` shim forwards the user's argument as **intent**, and `/docs-discipline:codify`'s Phase 2 invokes this procedure with intent = *full health*. Do not duplicate these steps elsewhere — read this file.

Perform a doc-health review on the current project. This is a doc health checkup — combining A/B state assessment, drift scanning, structural observation, and SSOT consistency check. Honor the **intent** passed by the caller (the `/review` shim forwards the user's argument; codify's Phase 2 passes *full health*). Adapt your behavior to what the intent actually asks for.

## Intent inference

Read the intent hint passed by the caller to infer scope:

| Intent hint | Focus |
|---|---|
| bare / none | Full health checkup (A/B + drift + SSOT + summary) |
| `for drift` / `drift only` | Drift scan only, skip A/B gap-fill and SSOT |
| `A/B` / `layers` | A/B assessment + gap-fill only, skip drift and SSOT |
| `SSOT` / `ssot` | SSOT consistency scan only, skip drift and A/B gap-fill |
| Other free-form hints | Use judgment; when unclear, default to full health |

## What you must do

### 1. Read CLAUDE.md and assess A/B state

- If `CLAUDE.md` does not exist → say so and continue with heuristic fallback (this review already has B-layer heuristic discovery, see step 5), or suggest the user run `/docs-discipline:codify` to initialize (its Phase 0 self-bootstraps CLAUDE.md). Do **not** require running a separate init step first.
- For each of the two A/B slots (A layer / B layer):
  - **Filled** — real prose outside `<!-- -->` blocks. Authoritative.
  - **Suggested** — setup-generated `Detected candidates` comment (written by codify Phase 0) but no prose. Hypothesis to confirm.
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

- Locate `scripts/drift-check.sh` in the project (set up by codify's first run — Phase 0 self-bootstrap); fall back to `${CLAUDE_PLUGIN_ROOT}/assets/drift-check.sh` if the project copy is missing.
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

**(f) Within-file accretion (B absorbing A).** Beyond cross-file restatement (d), flag any single B-layer "current state / snapshot / status" section that has absorbed per-session narrative — multiple dated entries stacked over time, or a high density of implementation-level tokens (hex colors, commit hashes, long code identifiers) that read as a journal rather than an aggregate. These are candidates to **thin to aggregate + pointer**: the narrative belongs in an A-layer artifact, with B keeping a one-line pointer. This is the single-file complement to (d)'s multi-file pattern, and the most common way a "small, living" B layer silently bloats. The deterministic `scripts/drift-check.sh` also surfaces oversized / impl-leaking B files (heuristic 5) — reconcile with its output.

**(g) Do NOT auto-fix.** SSOT scan is triage. The user decides whether each candidate is intentional or drift, and which home is canonical.

### 6. Output doc health summary

Always end with a one-screen summary. Template:

```
=== Doc health summary ===
A layer:  ✓ Filled / 🟡 Suggested / ✗ Empty   — <one-line description>
B layer:  ✓ Filled / 🟡 Suggested / ✗ Empty   — <one-line description>
Drift:    N candidates  (broken links: a / stale ts: b / orphans: c / dup H1: d / B-bloat: e)
SSOT:     N candidates  (M confirmed drift, P restatement, Q within-file accretion) — scanned N of M B-layer files
Notes:    <any structural observations, or "none">
```

Mark sections `(skipped)` if intent excluded them. If SSOT fell back to heuristic discovery (no A/B map), say so in the SSOT line.

## What you must NOT do

- ❌ Do not auto-fix drift or SSOT candidates. This procedure is triage, not editing.
- ❌ Do not silently write to CLAUDE.md. A/B writes happen only after the user picks option (1) in step 2.
- ❌ Do not nag. If the user picked "skip A/B" once, do not re-ask in this session.
- ❌ Do not assume A/B has a specific structure. Use what the user declared, or use observation.
- ❌ Do not re-implement drift heuristics in this prompt — defer to `scripts/drift-check.sh`.
- ❌ Do not pretend the SSOT scan is exhaustive. It is heuristic, sampling-based, and LLM-judged. Surface uncertainty in the summary (e.g., "B-layer fallback used — accuracy reduced").
- ❌ Do not modify any user files beyond what the user explicitly approves.

## Relationship to the commands

This procedure is the shared SSOT for two callers: `/docs-discipline:review` (standalone ad-hoc checkup; forwards your argument as intent) and `/docs-discipline:codify` Phase 2 (auto-runs this with intent = full health, skipping the A/B steps Phase 1 already did). It is triage only — surface candidates, never auto-fix.
