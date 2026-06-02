---
description: Session-end codify ritual. A/B-aware — reads CLAUDE.md's A/B map (or gently helps fill it), then classifies session findings into A-layer artifacts and B-layer SSOT edits.
---

You are running the docs-discipline codify ritual at the end of a Claude Code session. Your goal is to help the user turn this session's ephemeral findings into durable structure that fits *their* project's A/B layer convention.

## What you must do

### 1. Inspect what changed in this session

- Run `git status` and `git diff` to see uncommitted changes.
- Review the conversation context for key findings, decisions, conclusions, or knowledge that are NOT yet captured in the diff.
- Make a private list of "significant findings worth codifying."

### 2. Read CLAUDE.md and assess A/B state

Read the project's `CLAUDE.md` (must exist — if not, ask user to run `/docs-discipline:init` first).

For each of the two A/B slots (`### Where this project's A layer lives` / `### Where this project's B layer lives`), determine its state:

- **Filled** — the slot contains **non-comment text** the user has written (i.e., real prose outside `<!-- -->` blocks). Treat as authoritative.
- **Suggested** — the slot contains an init-generated comment like `<!-- Detected candidates (keep, edit, or clear): ... -->` but no real prose. Treat as a hypothesis to confirm with the user.
- **Empty** — the slot only contains the default placeholder comment (`<!-- Free-form. If empty, ... -->`) or is blank. The user has not engaged with this layer yet.

### 3. Gentle gap-fill (only when needed)

If either slot is **Suggested** or **Empty**, enter the gap-fill flow:

a. Scan project structure using the same heuristic logic as `/docs-discipline:init` (date-prefixed files, identifier-prefixed files, `history/` / `logs/` / `sessions/` / `spikes/` / `decisions/` / `adr/` for A; `README.md`, `STATUS.md`, `ROADMAP.md`, docs with "current/status/roadmap" content for B).

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

### 7. Offer a doc-health review (soft, optional)

After findings have been applied, offer once — never force:

> "Findings landed. Want a quick **doc-health review** now? `/docs-discipline:review` scans your B layer for drift and SSOT violations (facts repeated across files). This is the natural codify → review sequence — but it's optional, say no and we're done."

- Offer **only when at least one finding was actually written this run**. Do not offer if the user chose *Skip all* or *Mark exploratory*, **nor if *Apply selectively* ended up writing nothing** — an empty session has nothing new to drift-check, and nagging it is noise.
- This is a **distinct, second offer** (about `review`), separate from the step-3 A/B gap-fill ask. The step-78 "one ask per session run" rule governs the A/B ask; this review offer is its own one-shot. In a fresh project's first codify both may fire — that is acceptable, but keep each strictly **once** and never re-ask either this session.
- Accept any answer. Do **not** run `review` yourself or auto-chain into it — the user must invoke it. Your job is to surface the sequence at the right moment, not to enforce it.

## What you must NOT do

- ❌ Do not assume A or B has a particular structure. Use what the user has declared in CLAUDE.md, or use observation when they haven't.
- ❌ Do not force users to fill in A/B before codifying. Option (3) "skip" is always available.
- ❌ Do not silently edit CLAUDE.md's A/B slots — only after the user picks option (1).
- ❌ Do not nag. One ask per session run, not per codify invocation.
- ❌ Do not auto-apply findings. Always present the checklist first.
- ❌ Do not silently overwrite or contradict existing B-layer content. Flag conflicts.
- ❌ Do not "teach" the user how their docs should be structured beyond the A/B concept itself.
- ❌ Do not auto-run or force `/docs-discipline:review`. Offer it once at the end (step 7), only when **≥1 finding was actually written** this run, and respect a "no".

## If the project's docs are chaotic or absent

It is acceptable to say:

> "I could not find a clear A-layer or B-layer location for finding X. The project has no obvious immutable-artifact directory. Please tell me where to put it, or skip it for now."

Do not paper over with assumptions.

## If the user marks the session exploratory

Acknowledge, write nothing, and exit. Note that any committed code remains in `git log` regardless — `codify` only governs documentation.
