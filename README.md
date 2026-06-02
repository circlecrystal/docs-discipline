# docs-discipline

A Claude Code plugin that adds a session-end **codify** ritual and generic documentation **drift detection** to any project, organized around one universal pattern: **A/B layer separation**.

## Philosophy

**Like `git`, not `create-react-app`** — with one universal assertion.

This plugin provides primitives plus one shared truth: **durable documentation benefits from separating immutable artifacts (A layer) from living SSOT (B layer).** That isn't an opinion about your project's specific structure; it's the underlying pattern that prevents documentation drift.

### What the plugin *does* assert

- ✅ A habit anchor: "run `/docs-discipline:codify` at the end of each session"
- ✅ The A/B layer pattern as a universal principle
- ✅ Helps detect when a project is missing one or both layers, and gently offers to fill them in
- ✅ Generic drift detection (broken links, stale timestamps, orphan docs, duplicated H1s)

### What the plugin *does not* assert

- ❌ Does **not** assume your A/B layers live at specific paths or follow specific naming
- ❌ Does **not** ship SSOT maps, status symbol systems, governance whitepapers, or doc templates
- ❌ Does **not** offer reference examples — they implicitly impose structure
- ❌ Does **not** force you to fill in A/B if you don't want to. "Skip for now" is always an option.

### Hard constraint

The plugin will not grow templates, examples, or opinions about *how* A/B should look in your project. Its only opinion is that the A/B pattern is universal. Beyond that, your project is your project.

## Install

Claude Code installs plugins through marketplaces. This repo serves as a single-plugin marketplace for itself, so two commands set it up:

```
/plugin marketplace add circlecrystal/docs-discipline
/plugin install docs-discipline@docs-discipline
```

(`<plugin-name>@<marketplace-name>` — both happen to be `docs-discipline` here.)

To update later:

```
/plugin marketplace update docs-discipline
```

## Commands

### `/docs-discipline:init`

One-time per project. If `CLAUDE.md` doesn't exist, the plugin creates a minimal one with an A/B section containing two empty slots — and probes your existing files to suggest A-layer and B-layer candidates as comments inside those slots. You can keep, edit, or clear the suggestions.

If `CLAUDE.md` already exists, the plugin only appends a short docs-discipline declaration block — it does **not** force A/B onto your existing governance content. The A/B conversation happens later, gently, via codify.

Also copies `drift-check.sh` into the project's `scripts/`.

### `/docs-discipline:codify`

Run at the end of every session. This one command runs three phases in order:

**Phase 1 — codify.** Reads `CLAUDE.md`'s A/B map (if filled), observes your project's docs structure, and produces a checklist of where this session's findings should land — classified by A layer (new immutable artifacts) and B layer (SSOT updates). If your A/B slots are empty, codify will gently ask once per session — never nag. You can fill them in (preferred), use the suggestions for this run only, or skip A/B classification entirely. You decide whether to apply, partially apply, skip, or mark the session as exploratory.

**Phase 2 — review (automatic).** Right after codifying, it continues into the `/docs-discipline:review` drift + SSOT + health summary — no separate invocation needed. This phase always runs (a health check doesn't depend on new findings) and stays triage-only; nothing is auto-fixed.

**Phase 3 — session-handoff plan (optional).** Finally, it offers to write a self-contained handoff document (goal, decisions, current state, next steps, pointers) so you can resume in a fresh session. It asks where to put it and imposes no location. Decline anytime.

### `/docs-discipline:review`

Ad-hoc doc health checkup. Reads `CLAUDE.md`'s A/B map, runs the drift scan, performs an SSOT consistency check, and outputs a one-screen summary. Adapts to what you actually need:

- **Bare `/docs-discipline:review`** → full health (A/B state + drift + SSOT + structural observations)
- **`/docs-discipline:review for drift`** → drift scan only
- **`/docs-discipline:review A/B`** → A/B assessment + gap-fill only
- **`/docs-discipline:review SSOT`** → SSOT consistency scan only

The **SSOT scan** identifies atomic facts (statuses, version values, decisions, progress numbers) that appear in multiple B-layer files. Same fact in many places means edits will eventually miss one — that's the root pattern behind most doc drift. The scan reads the B-layer files you declared in CLAUDE.md (or falls back to heuristic discovery if you skipped A/B), cross-references facts, and surfaces candidates. Nothing is auto-fixed; the user decides what's intentional restatement vs. real drift, and which file is canonical.

Drift findings come from `scripts/drift-check.sh` (broken links, stale timestamps, orphan documents, duplicated H1s). For pure CI/cron use, invoke that script directly — it stays a deterministic, scriptable interface.

## How to use it well

1. Run `/docs-discipline:init` once per project.
2. Open `CLAUDE.md` and either confirm the A/B candidates the plugin probed for you, write your own description of where A and B live, or leave them empty (codify or review will gently ask later).
3. Add anything else under `## Project governance` as you see fit — the plugin won't touch it.
4. At the end of each Claude Code session, run `/docs-discipline:codify`. One command does it all: it codifies findings, then auto-runs the doc-health review, then optionally writes a session-handoff plan.
5. Anytime you want a doc status read (with or without session changes), run `/docs-discipline:review`.
6. For automation (CI / cron / weekly), wire `scripts/drift-check.sh` directly.

## License

MIT
