---
description: Doc-health review — drift + SSOT + one-screen summary. Standalone ad-hoc checkup (also runs automatically inside /docs-discipline:codify's Phase 2).
argument-hint: "[for drift | SSOT | A/B]"
---

Read `${CLAUDE_PLUGIN_ROOT}/assets/review-procedure.md` **via Bash so the shell expands the variable** (e.g. `ls "${CLAUDE_PLUGIN_ROOT}/assets/review-procedure.md" && cat "${CLAUDE_PLUGIN_ROOT}/assets/review-procedure.md"`), then perform that procedure on the current project. If `${CLAUDE_PLUGIN_ROOT}` is empty in your shell, locate the installed copy instead (search the docs-discipline plugin dir under `~/.claude/plugins/` for `assets/review-procedure.md`). Treat this command's argument as the **intent** hint (`for drift` / `SSOT` / `A/B`, or bare = full health). Do not reconstruct the procedure from memory — read the asset.
