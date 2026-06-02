---
description: Session-end ritual and single entry point. Self-bootstraps docs-discipline setup if missing, codifies this session's findings into the project's A/B doc layers, automatically runs a doc-health review (drift + SSOT), and optionally writes a session-handoff plan — all in one command. A/B-aware; interactive at every decision point.
---

You are running the docs-discipline codify ritual at the end of a Claude Code session — the **single entry point** for docs-discipline. It runs phases in order within this one command: **Phase 0** ensures docs-discipline is set up in this project (self-bootstrap, idempotent — absorbs what used to be a separate `/init`); **Phase 1** sediments this session's findings into the project's A/B layer convention; **Phase 2** automatically continues into a doc-health review; **Phase 3** optionally writes a session-handoff plan. Stay interactive — surface decisions to the user at each point; never silently write.

## Phase 0 — Ensure setup (self-bootstrap, idempotent)

Before codifying, make sure docs-discipline is actually set up in this project. This absorbs what used to be a separate `/init` step — codify is now self-bootstrapping. Run this first, every time; it is idempotent and only touches what is missing. Never write silently — leave a receipt (step 0c).

### 0a. Check setup state

The project is set up when **all three** hold:
- `CLAUDE.md` exists at the project root, AND
- it contains the marker line `This project uses [docs-discipline]`, AND
- `scripts/drift-check.sh` exists.

If all three are true → say so in **one line** (e.g. "docs-discipline already set up — CLAUDE.md + drift-check.sh present, skipping bootstrap") and proceed to Phase 1. Do not stay completely silent; leave a one-line receipt.

If any is missing → enter bootstrap (0b). Only create / append / copy what is actually missing.

### 0b. Bootstrap (only fills gaps)

1. **Locate the plugin assets.** Find `${CLAUDE_PLUGIN_ROOT}/assets/` via Bash (it holds `claude-md-stub.md` and `drift-check.sh`). If `${CLAUDE_PLUGIN_ROOT}` is empty, locate the installed copy under `~/.claude/plugins/`. If you cannot locate the assets at all → report the error and **stop**; do not invent content.

2. **CLAUDE.md — Case A (does NOT exist):** write `CLAUDE.md` from `assets/claude-md-stub.md` verbatim. The stub already carries empty A/B placeholder slots; do **not** probe or fill candidates here — Phase 1 step 3 owns A/B discovery, so the probing heuristic is described in exactly one place (step 3), not duplicated in Phase 0. (Phase 1 step 2 will read these slots as **Empty** and step 3 will offer to fill them.)

3. **CLAUDE.md — Case B (exists but no marker):** append ONLY the top declaration block of the stub (everything up to but NOT including `## Doc layers (A/B)`), separated by a single blank line. Do **not** force the A/B section onto an existing CLAUDE.md — the user may already have governance content there that would conflict. Phase 1 surfaces A/B gently later instead.

4. **scripts/drift-check.sh:** ensure `scripts/` exists (create if missing). If `scripts/drift-check.sh` is missing → copy the asset there and `chmod +x`. If it exists with identical content → skip. If it exists with **different** content → do NOT overwrite; report the conflict, show a diff, and ask the user how to proceed.

### 0c. Report (do not write silently)

List exactly what was created / appended / copied / skipped, with concrete file paths. This receipt is what keeps Phase 0 from silently writing to disk: on a greenfield project (Case A), the very first codify creates `CLAUDE.md` + copies the drift script, and the user must see that happen. Then continue into Phase 1.

## Phase 1 — Codify this session's findings

### 1. Inspect what changed in this session

- Run `git status` and `git diff` to see uncommitted changes.
- Review the conversation context for key findings, decisions, conclusions, or knowledge that are NOT yet captured in the diff.
- Make a private list of "significant findings worth codifying."

### 2. Read CLAUDE.md and assess A/B state

Read the project's `CLAUDE.md` (Phase 0 has already ensured it exists).

For each of the two A/B slots (`### Where this project's A layer lives` / `### Where this project's B layer lives`), determine its state:

- **Filled** — the slot contains **non-comment text** the user has written (i.e., real prose outside `<!-- -->` blocks). Treat as authoritative.
- **Suggested** — the slot contains a setup-generated comment (written by Phase 0) like `<!-- Detected candidates (keep, edit, or clear): ... -->` but no real prose. Treat as a hypothesis to confirm with the user.
- **Empty** — the slot only contains the default placeholder comment (`<!-- Free-form. If empty, ... -->`) or is blank. The user has not engaged with this layer yet.

### 3. Gentle gap-fill (only when needed)

If either slot is **Suggested** or **Empty**, enter the gap-fill flow:

a. Scan project structure using the same A/B probing heuristic (date-prefixed files, identifier-prefixed files, `history/` / `logs/` / `sessions/` / `spikes/` / `decisions/` / `adr/` for A; `README.md`, `STATUS.md`, `ROADMAP.md`, docs with "current/status/roadmap" content for B). This is the single description of the heuristic; Phase 0 deliberately defers all A/B discovery here.

b. Present to the user, clearly and once:

> "Your project's A layer / B layer / both layers haven't been explicitly mapped yet. Here's what I see as candidates: [list]. Would you like to:
> - **(1) Fill in CLAUDE.md** with these (you can edit before saving) — preferred
> - **(2) Use these for this codify only** without writing to CLAUDE.md
> - **(3) Skip — proceed with generic heuristics, no A/B classification this run**"

c. Honor the choice:
- (1) → write the chosen description to CLAUDE.md's A/B slot, replacing the comment. Then continue codifying with A/B awareness.
- (2) → continue codifying with A/B awareness in this run, but **do not modify CLAUDE.md**.
- (3) → continue codifying without A/B classification; just propose where findings go based on what you see.

d. **Do not nag**. If the user picks (2) or (3), do not re-ask in this session. (If a future session also has empty slots, that session's codify run will ask once again — that's fine and expected; just don't loop.)

### 4. Observe the project's docs structure

Whether or not you have an A/B map, scan the project's actual docs adaptively:
- Is there a `docs/` directory? What's inside?
- Are there ADRs, design docs, changelogs, wiki references?
- Where do per-feature docs live?

This grounds the codify proposals in what the project actually has.

### 5. Synthesize the codify checklist

For each significant finding from step 1, propose:

- **Layer**: A (immutable artifact) or B (SSOT update). Use the A/B map if available; otherwise use judgment based on the finding's nature (one-shot dated capture → A; current-state assertion → B).
- **Where it should land**: a specific file path. For A-layer additions, this is usually a new file (suggest a dated/numbered name fitting the project's convention). For B-layer updates, this is an edit to an existing file.
- **What the change looks like**: a concrete diff sketch (additions, edits) — not vague advice.
- **Whether it conflicts with existing B-layer content**: use `grep` to check whether the project already says something contradictory. Flag conflicts explicitly.

### 6. Present and apply

Offer the user these choices:
- **Apply all** — you write the diffs.
- **Apply selectively** — user picks which items.
- **Skip all** — nothing is written.
- **Mark exploratory** — declare this session was exploratory, no codify needed.

Apply only what the user approves. Be conservative — if uncertain about wording or placement, surface the ambiguity rather than guessing.

## Phase 2 — Doc-health review (auto-run, interactive)

After Phase 1, **automatically continue** into a doc-health review. Do not ask "want a review?", and do not require the user to invoke `/docs-discipline:review` separately — the review is now a fixed part of this one ritual.

**Run the review from its single source — do not paste, paraphrase, or reconstruct its steps here.** The review procedure lives in the shared asset `assets/review-procedure.md` (the same file the `/docs-discipline:review` shim reads); follow it live so the two never drift:

1. **Load it via Bash, not by trusting variable expansion in the Read tool.** `${CLAUDE_PLUGIN_ROOT}` is a shell variable; print and read the file through a shell so it expands reliably:
   ```bash
   ls "${CLAUDE_PLUGIN_ROOT}/assets/review-procedure.md" && cat "${CLAUDE_PLUGIN_ROOT}/assets/review-procedure.md"
   ```
   If `${CLAUDE_PLUGIN_ROOT}` is empty in your shell, locate the installed copy instead (e.g. search the docs-discipline plugin dir under `~/.claude/plugins/` for `assets/review-procedure.md`). Do not proceed from memory — read the actual file.
2. Perform that file's procedure, but **skip the steps Phase 1 already did**: its `Read CLAUDE.md and assess A/B state`, `Route by intent`, and `Observe project docs structure`. **Resume at `Run drift scan`, then `SSOT consistency scan`, then `Output doc health summary`.** Treat intent as **full health** (run both drift and SSOT).
3. **Always run this phase**, even if Phase 1 wrote nothing (Skip all / Mark exploratory / a selective apply that wrote nothing). The drift and SSOT scans inspect the project's existing doc corpus — their value does not depend on whether this session produced new findings.
4. The review is **triage only**: surface drift/SSOT candidates and let the user decide. Do not auto-fix. Do not re-ask the A/B gap-fill here — Phase 1 owns it.

## Phase 3 — Optional session-handoff plan

Some sessions end with "I'll continue this in a fresh session." Offer — once, never force — to capture a handoff document:

> "Want me to write a **session-handoff plan** so you can resume in a new session? It captures this session's goal, key decisions, current state, next steps, and the files/commits to pick up from. Optional — say no and we're done."

- Offer this **regardless of whether Phase 1 wrote anything** — a pure-exploration session is often exactly when a handoff is wanted.
- This is a **distinct, one-shot ask**, separate from Phase 1's A/B gap-fill. Ask once, accept any answer, do not re-ask this session.
- **If the user accepts:**
  1. **Ask where to write it.** Propose an adaptive default and let the user confirm or override — docs-discipline imposes no location. Suggested default: if the project has a `docs/` directory, `docs/handoff/handoff-<date>-<slug>.md`; otherwise `<repo-root>/.handoff/handoff-<date>-<slug>.md`. If the project's A layer is mapped and the user prefers, the A-layer artifact location is also fine. Get `<date>` from `date +%F`.
  2. **Write the handoff** using the template below. Keep it self-contained — the resuming session may start with zero prior context. Reference what Phase 1 codified (link the A/B artifacts) and any open drift/SSOT items Phase 2 surfaced.
- **If the user declines:** write nothing and finish.

**Handoff template:**

```markdown
# Session handoff — <date> — <one-line topic>

## Goal & outcome
<what this session set out to do; what actually happened>

## Key decisions
<decisions made + one-line rationale each; link any A/B artifacts codified this session>

## Current state
<what works / what's verified / what's still pending or broken>

## Next steps (for the resuming session)
<ordered, concrete TODOs to pick up>

## Pointers
<relevant files, commits, branch, PRs, dashboards>

## Open questions & risks
<unresolved threads the next session must decide; include open drift/SSOT items from Phase 2>
```

## What you must NOT do

- ❌ Do not assume A or B has a particular structure. Use what the user has declared in CLAUDE.md, or use observation when they haven't.
- ❌ Do not force users to fill in A/B before codifying. Option (3) "skip" is always available.
- ❌ Do not silently edit CLAUDE.md's A/B slots — only after the user picks option (1).
- ❌ Do not nag. One ask per session run, not per codify invocation. There are two distinct one-shot asks — Phase 1's A/B gap-fill and Phase 3's handoff offer — each fires at most once.
- ❌ Do not auto-apply findings. Always present the checklist first.
- ❌ Do not silently overwrite or contradict existing B-layer content. Flag conflicts.
- ❌ Do not "teach" the user how their docs should be structured beyond the A/B concept itself.
- ❌ Do not skip Phase 2 or turn it back into an opt-in "want a review?" prompt — the review runs automatically as part of codify.
- ❌ Do not paste or reconstruct `assets/review-procedure.md`'s drift/SSOT procedure into this file — read it from its single source so the two never drift.
- ❌ Do not auto-fix drift/SSOT in Phase 2 — it stays triage.
- ❌ Do not force the Phase 3 handoff — it is opt-in; write nothing if the user declines.

## If the project's docs are chaotic or absent

It is acceptable to say:

> "I could not find a clear A-layer or B-layer location for finding X. The project has no obvious immutable-artifact directory. Please tell me where to put it, or skip it for now."

Do not paper over with assumptions.

## If the user marks the session exploratory

"Exploratory" applies to **Phase 1 only**. **Phase 0 (setup self-bootstrap) always runs first** — the project still needs to be set up whether or not the session was exploratory. For Phase 1: acknowledge, write no codify findings, and note that any committed code remains in `git log` regardless — `codify` only governs documentation. Then **still continue into Phase 2 (the doc-health review always runs) and Phase 3 (still offer the handoff)** — neither depends on this session having produced findings.
