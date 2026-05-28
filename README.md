# docs-discipline

A Claude Code plugin that adds a session-end **codify** ritual and generic documentation **drift detection** to any project.

## Philosophy

**Like `git`, not `create-react-app`.** This plugin provides primitives — not opinions about how your docs should be structured.

What this means in practice:

- ✅ Provides a habit anchor: "run `/docs-discipline:codify` at the end of each session"
- ✅ Provides an observation-driven codify command that reads your actual project structure
- ✅ Provides generic drift detection (broken links, stale timestamps, orphan docs, inconsistent duplicates)
- ❌ Does **not** assume your project has `docs/`, `spikes/`, ADRs, or any particular layout
- ❌ Does **not** ship governance philosophy, SSOT maps, or doc templates
- ❌ Does **not** offer reference examples (even optional ones — they implicitly impose structure)

**Hard constraint**: this plugin will never grow opinionated templates. If something feels universal enough to ship, it goes through a public discussion first.

## Install

```
/plugin install https://github.com/circlecrystal/docs-discipline.git
```

## Commands

### `/docs-discipline:init`

One-time per project. Creates a minimal `CLAUDE.md` (or appends a short declaration to an existing one) stating that the project uses docs-discipline, and copies `drift-check.sh` into the project's `scripts/`.

It does **not** create `docs/`, write templates, or impose any structure. Whatever governance rules your project wants are written by you, into the empty section it leaves behind.

### `/docs-discipline:codify`

Run at the end of every session. Reads `git diff`, your project's `CLAUDE.md`, and **observes** your actual docs structure (whatever that happens to be). Produces a checklist of where this session's findings should land — based on what your project actually has, not what the plugin thinks you should have.

You decide whether to apply, partially apply, skip, or explicitly mark the session as "not codified" (e.g., exploratory work).

### `/docs-discipline:drift-check`

Periodic health check. Runs the project-local `scripts/drift-check.sh` and outputs a triage list of suspected drift:

- Broken relative links
- Timestamps that lag behind `git log`
- Orphan documents (no document references them)
- Long strings duplicated across files with subtle inconsistencies

It does **not** auto-fix. You decide what's drift vs. intentional.

## How to use it well

1. Run `/docs-discipline:init` once per project.
2. Fill in the empty `## Project governance` section in `CLAUDE.md` with whatever rules suit *your* project (SSOT pointers, doc layout, status symbols, whatever you want — or leave it empty).
3. At the end of each Claude Code session, run `/docs-discipline:codify`.
4. Periodically (weekly works well), run `/docs-discipline:drift-check`.

## License

MIT
