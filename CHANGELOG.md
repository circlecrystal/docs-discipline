# Changelog

All notable changes to docs-discipline are recorded here. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/); versioning is [SemVer](https://semver.org/).

## [0.8.0] — 2026-06-03

Theme: **stop the B layer from silently bloating.** The most common long-term failure
mode is per-session narrative accreting into the "current state" (B) layer — codify
adds a little every session and nothing ever trims it. This release teaches every
phase of the tool the same corollary of the A/B idea: **B is an aggregate + pointer
layer; the narrative lives in A.**

### Added
- **A/B thinness corollary** baked into the core concept (`assets/claude-md-stub.md`
  + both READMEs). It is installed into every new project's `CLAUDE.md` on first
  codify, so the principle is a standing instruction from day one: *"A-layer size is
  expected; only B-layer growth is bloat."*
- **`drift-check.sh` heuristic 5 — B-layer bloat (A/B-aware).** Flags oversized B
  files and implementation-detail leakage (hex colors, commit hashes, long code
  identifiers). It scans **only** the B-layer set — declared in `CLAUDE.md`, or
  heuristically discovered when absent — so large, legitimately frozen A-layer
  artifacts (spike reports, ADRs, handoffs) are never false-flagged. Tunable via
  `DOCS_DISCIPLINE_B_MAX_LINES` (default 250) and `DOCS_DISCIPLINE_B_MAX_IMPL`
  (default 12).
- **SSOT within-file accretion check** in `assets/review-procedure.md` — flags a
  single B-layer "current state / snapshot" section that has absorbed per-session
  narrative (the single-file complement to cross-file restatement).

### Changed
- **codify Phase 1** now keeps current-state B edits to an aggregate + pointer, and
  routes per-session narrative into A (a dated artifact, or the Phase 3 handoff).
- **codify Phase 1 ↔ Phase 3 coordination**: when a handoff is written, the B-layer
  current-state edit *points to it* rather than restating it — eliminating the
  double-write that used to copy the same session story into both A and B.
- **codify "What you must NOT do"** clarified: replacing a stale current-state line
  with its updated aggregate+pointer is expected B-layer *curation*, not a
  destructive overwrite — B is curated, not append-only. Added an explicit
  "don't grow B with per-session narrative" rule.
- The doc-health summary gains a `B-bloat` drift counter and a `within-file
  accretion` SSOT counter.

### Fixed
- Version string unified to `0.8.0` across `plugin.json`, `marketplace.json`, and
  both README badges (the badges had lagged at `0.7.1` while the manifests were at
  `0.7.2`).
