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

```
/plugin install https://github.com/circlecrystal/docs-discipline.git
```

## Commands

### `/docs-discipline:init`

One-time per project. If `CLAUDE.md` doesn't exist, the plugin creates a minimal one with an A/B section containing two empty slots — and probes your existing files to suggest A-layer and B-layer candidates as comments inside those slots. You can keep, edit, or clear the suggestions.

If `CLAUDE.md` already exists, the plugin only appends a short docs-discipline declaration block — it does **not** force A/B onto your existing governance content. The A/B conversation happens later, gently, via codify.

Also copies `drift-check.sh` into the project's `scripts/`.

### `/docs-discipline:codify`

Run at the end of every session. Reads `CLAUDE.md`'s A/B map (if filled), observes your project's docs structure, and produces a checklist of where this session's findings should land — classified by A layer (new immutable artifacts) and B layer (SSOT updates).

If your A/B slots are empty, codify will gently ask once per session — never nag. You can fill them in (preferred), use the suggestions for this run only, or skip A/B classification entirely.

You decide whether to apply, partially apply, skip, or mark the session as exploratory.

### `/docs-discipline:drift-check`

Periodic health check. Runs `scripts/drift-check.sh` and outputs a triage list of suspected drift:

- Broken relative links
- Timestamps that lag behind `git log`
- Orphan documents (no document references them)
- Long strings duplicated across files with subtle inconsistencies

It does **not** auto-fix. You decide what's drift vs. intentional.

## How to use it well

1. Run `/docs-discipline:init` once per project.
2. Open `CLAUDE.md` and either confirm the A/B candidates the plugin probed for you, write your own description of where A and B live, or leave them empty (codify will gently ask later).
3. Add anything else under `## Project governance` as you see fit — the plugin won't touch it.
4. At the end of each Claude Code session, run `/docs-discipline:codify`.
5. Periodically (weekly works well), run `/docs-discipline:drift-check`.

## License

MIT
