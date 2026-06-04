🌐 **English** · [中文](README.zh-CN.md)

# docs-discipline

**Give your AI-coded project a memory that survives across sessions.**

![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-7C3AED)
![Version](https://img.shields.io/badge/version-0.8.1-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![No network](https://img.shields.io/badge/network-none-brightgreen)
![Never auto-edits](https://img.shields.io/badge/writes-you%20approve-brightgreen)

Every new AI coding session starts cold. The decisions, the dead-ends, the *"where were we?"* from last time — gone. Meanwhile your docs quietly drift away from the code. On long, exploratory work this is brutal: you burn the first twenty minutes of every session re-explaining context your agent already figured out once.

**docs-discipline turns the end of each session into a 60-second ritual.** One command — `/docs-discipline:codify` — files what this session learned into durable docs, checks them for drift, and (optionally) writes a handoff so the *next* session picks up exactly where you left off.

---

## Why you'll want it

- 🧠 **Cross-session memory.** Findings and decisions land in your repo as real files — so a fresh session *continues* the last one instead of restarting it. This is the whole point.
- 🔔 **It reminds you.** Setup installs a one-line habit anchor in your `CLAUDE.md`, so your coding agent offers the ritual on its own at session end. Nothing to wire up, nothing to remember.
- ⏱️ **One command closes the session.** codify → automatic doc-health review → optional handoff plan, all in a single pass.
- 🛰️ **Drift radar.** Catches broken links, stale timestamps, orphaned docs, the same "fact" restated in five places, and B-layer "current state" docs that quietly bloat with per-session narrative — the root causes of docs that lie.
- 🪶 **Zero lock-in.** No templates. No enforced folder layout. It never silently rewrites your docs — it *proposes*, you approve. Every write is yours.
- 🎯 **Built for the work that needs it most.** Multi-week spikes, research, architecture — the big, exploratory tasks where losing the thread between sessions costs you the most.

> The magic moment: you close a session, open a brand-new one a week later, and your agent already knows what was decided, what's half-done, and what's next — because it's written down, not held in a context window that's long gone.

## Quickstart (30 seconds)

Claude Code installs plugins through marketplaces. This repo is its own single-plugin marketplace, so two commands set it up:

```
/plugin marketplace add circlecrystal/docs-discipline
/plugin install docs-discipline@docs-discipline
```

(`<plugin-name>@<marketplace-name>` — both happen to be `docs-discipline` here.)

> *Heads up:* docs-discipline is also being submitted to Anthropic's community marketplace. Once it lands there you can instead `/plugin marketplace add anthropics/claude-plugins-community` and `/plugin install docs-discipline@claude-community`. Until then, the direct install above is the way.

Then, at the end of each session, run:

```
/docs-discipline:codify
```

That's it. The first run sets your project up automatically (see Phase 0 below) — there's no separate init step.

To update later:

```
/plugin marketplace update docs-discipline
```

## What's in the box

Two slash commands and one script — nothing that runs on its own:

| Component | What it is |
| --- | --- |
| `/docs-discipline:codify` | The end-of-session ritual: self-bootstrap → codify → review → optional handoff |
| `/docs-discipline:review` | Standalone doc-health checkup (drift + SSOT) |
| `scripts/drift-check.sh` | A read-only Bash scanner, copied into your repo on first run, that powers the drift heuristics (also callable from CI/cron) |
| `CLAUDE.md` stub | A minimal habit anchor + A/B scaffold, created or appended on first run |

**No agents, no hooks, no MCP servers, no LSP servers.** Nothing wires itself into your session loop, so the per-turn context cost is effectively zero — the commands run only when *you* invoke them.

## Requirements

- **Claude Code** with plugin support (the `/plugin` command).
- **Bash** for `drift-check.sh` (macOS/Linux; it handles both BSD and GNU `date`). The agent-driven phases work without it — only the scriptable drift scan needs a shell.
- **Git** is optional: `drift-check.sh` uses it when present (to respect `.gitignore` and read commit dates) and falls back to a plain file walk when absent.

## Safety & permissions — what it touches

docs-discipline is deliberately low-trust. Exactly what it does, and does not, do:

- **Reads** your repo's markdown and `CLAUDE.md`, plus read-only git metadata (`git ls-files`, `git log`) via `drift-check.sh`.
- **Writes only what you approve.** On first run it may create `CLAUDE.md` (or append a declaration block to an existing one) and copy `drift-check.sh` into `scripts/` — and it always prints a receipt of exactly what it created, appended, copied, or skipped. Every other write (A/B doc edits, the handoff doc) is *proposed as a checklist first* and applied only on your say-so.
- **Never writes silently, never auto-fixes.** The review phase is triage-only — it surfaces candidates and lets you decide.
- **No network, no telemetry, no external services.** `drift-check.sh` is a plain Bash scanner that reads files and emits an exit code + stdout; it never modifies your docs.

That is the whole surface area — there is nothing else running in the background.

## The one idea: A/B layers

Almost all doc drift has a single cause: **yesterday's "as-of-then" note gets read as today's truth.** docs-discipline fixes that by separating your docs into two layers.

- **A layer — artifacts.** Immutable and dated. Written once, never edited after. Each one captures a point-in-time finding, decision, or session output (an ADR, a spike report, a research note).
- **B layer — SSOT.** A small, living set of "current state" docs (a README, a status page, a roadmap). Each B-layer claim points back to the A-layer artifact that justifies it.

Once A and B are separate, drift becomes obvious instead of invisible: a "current state" line that no longer matches its dated source sticks out. That's the entire mental model — and it's universal. **How** A and B look in *your* project (paths, naming, conventions) is entirely your call; the plugin assumes nothing.

**Keep B thin.** A B-layer line is an *aggregate + a pointer* to its A-layer artifact — never a restatement of that artifact's narrative. Per-session detail accretes in A (which may grow without bound); B stays small by pointing, not copying. A-layer size is expected; only B-layer growth is bloat — which is why the drift radar's bloat check scans *only* B.

## Commands

Two commands. **`codify`** is the single entry point you run every session — it self-bootstraps setup, codifies, reviews, and offers a handoff. **`review`** is a standalone ad-hoc checkup (also run automatically inside codify). There is no separate `/init` — codify absorbs setup as its Phase 0.

### `/docs-discipline:codify`

Run at the end of every session. Self-bootstrapping, idempotent, and **never writes silently** — it runs four phases in order:

- **Phase 0 — setup (automatic).** On first run, sets the project up: creates a minimal `CLAUDE.md` if missing (a short docs-discipline declaration plus two empty A/B slots), or appends only the declaration block to an existing `CLAUDE.md` without touching your governance content. Copies `drift-check.sh` into `scripts/`. On an already-set-up project it just says "already set up" and moves on. It always reports exactly what it created, appended, copied, or skipped.
- **Phase 1 — codify.** Reads your A/B map, observes your docs structure, and produces a checklist of where this session's findings should land — classified as A (new immutable artifacts) or B (SSOT updates), each with a concrete diff sketch. If your A/B slots are empty it asks **once** — fill them in (preferred), use suggestions for this run only, or skip. You decide what to apply, partially apply, skip, or mark the session exploratory. Nothing is written without your say-so. It keeps B-layer edits thin — an aggregate plus a pointer — and routes per-session narrative into A (or the handoff), so your SSOT stays small instead of bloating session by session.
- **Phase 2 — review (automatic).** Continues straight into the doc-health review (drift + SSOT + a one-screen summary). Always runs, stays triage-only — it surfaces candidates, never auto-fixes.
- **Phase 3 — handoff (optional).** Offers to write a self-contained handoff doc — goal, decisions, current state, next steps, pointers — so you can resume in a fresh session. It asks where to put it and imposes no location. Decline anytime.

### `/docs-discipline:review`

An ad-hoc doc-health checkup you can run anytime, with or without session changes. Reads your A/B map, runs the drift scan, performs an SSOT consistency check, and prints a one-screen summary. Adapts to intent:

- **`/docs-discipline:review`** → full health (A/B state + drift + SSOT + structure)
- **`/docs-discipline:review for drift`** → drift scan only
- **`/docs-discipline:review A/B`** → A/B assessment + gap-fill only
- **`/docs-discipline:review SSOT`** → SSOT consistency scan only

The **SSOT scan** finds atomic facts — statuses, version values, decisions, progress numbers — restated across multiple B-layer files. Same fact in many places means an edit will eventually miss one; that's where drift is born. It surfaces candidates and flags mismatches; **you** decide what's intentional restatement vs. real drift, and which file is canonical.

## Design principles

**Like `git`, not `create-react-app`.** The plugin gives you primitives plus exactly one shared truth — *durable docs benefit from separating immutable artifacts (A) from living SSOT (B)* — and then gets out of your way.

**What it *does* assert:**

- ✅ A habit anchor: "run `/docs-discipline:codify` at the end of each session"
- ✅ The A/B layer pattern as a universal principle
- ✅ It detects when a project is missing one or both layers, and gently offers to fill them in
- ✅ The thinness corollary of A/B: B is an aggregate+pointer layer; per-session narrative lives in A
- ✅ Generic drift detection (broken links, stale timestamps, orphan docs, duplicated H1s) plus A/B-aware B-layer bloat detection

**What it *does not* assert:**

- ❌ It does **not** assume your A/B layers live at specific paths or follow specific naming
- ❌ It does **not** ship SSOT maps, status-symbol systems, governance whitepapers, or doc templates
- ❌ It does **not** offer reference examples — they'd implicitly impose structure
- ❌ It does **not** force you to fill in A/B. "Skip for now" is always an option.

**Hard constraint.** The plugin will not grow templates, examples, or opinions about *how* A/B should look in your project. Its only opinion is that the A/B pattern is universal. Beyond that, your project is your project.

## Automation (CI / cron)

Drift findings come from `scripts/drift-check.sh` — a deterministic, scriptable interface (broken links, stale timestamps, orphan documents, duplicated H1s; exit code + stdout). For pure CI or weekly-cron use, call it directly, no agent required.

## License

MIT © Wang Heng · [github.com/circlecrystal/docs-discipline](https://github.com/circlecrystal/docs-discipline)
