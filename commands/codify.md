---
description: Session-end codify ritual. Observes the project's actual docs structure and proposes where this session's findings should land — without imposing any template.
---

You are running the docs-discipline codify ritual at the end of a Claude Code session. Your goal is to help the user turn this session's ephemeral findings into durable structure that fits *their* project — not a structure this plugin imposes.

## What you must do

1. **Inspect what changed in this session.**
   - Run `git status` and `git diff` to see uncommitted changes.
   - Review the conversation for key findings, decisions, conclusions, or knowledge that are NOT yet captured in the diff (e.g., a spike conclusion that was reached verbally but not written down; a design tradeoff the user accepted).
   - Make a private list of "significant findings worth codifying."

2. **Read the project's `CLAUDE.md`** if present. Whatever governance rules the project itself declares — read them and respect them. The plugin imposes no rules; the project may.

3. **Observe the project's actual docs structure — adaptively, without assumptions.**
   - Is there a `docs/` directory? What is its layout? Are there subdirectories with their own conventions?
   - Are there ADRs, decision logs, design docs, changelogs anywhere?
   - Is documentation in README files, in a wiki linked from README, or scattered as code comments?
   - Are there per-feature or per-module doc files near the code?
   - **If you cannot find a clear docs structure, say so honestly — do not invent one.**

4. **Synthesize a codify checklist.** For each significant finding from step 1, propose:
   - **Where it should land**: a specific file path in the project's actual docs. If multiple plausible locations exist, list them and let the user pick.
   - **What the change looks like**: a concrete diff sketch (additions, edits) — not vague advice like "update the docs."
   - **Whether it conflicts with existing content**: use `grep` to check whether the project already says something contradictory at the proposed location or elsewhere. Flag conflicts explicitly.

5. **Present the checklist to the user.** Offer them four choices:
   - **Apply all** — you write the diffs.
   - **Apply selectively** — user picks which items.
   - **Skip all** — nothing is written; findings remain only in git history and the conversation.
   - **Mark exploratory** — user declares this session was exploratory and intentionally not for codifying.

6. **Apply only what the user approved.** Be conservative — if uncertain about wording or placement, surface the ambiguity rather than guessing.

## What you must NOT do

- Do not assume the project has `docs/`, `spikes/`, ADRs, an SSOT map, status symbol systems, or any particular layer model. If those exist, observe and use them. If they don't, do not create them or suggest them.
- Do not write findings to "default" paths invented by the plugin. The plugin has no defaults.
- Do not auto-apply changes. Always present the checklist first.
- Do not silently overwrite existing content. Always flag conflicts.
- Do not "teach" the user how their docs should be structured. Their structure is their choice.

## If the project's docs are chaotic or absent

This happens. It is acceptable and honest to say:

> "I could not find a clear place for finding X. The project has no `docs/` directory and the README does not reference any documentation. Please tell me where to put it, or skip it for now."

Do not paper over with assumptions.

## If the user marks the session exploratory

Acknowledge, write nothing, and exit. Note that any committed code remains in `git log` regardless — `codify` only governs documentation.
