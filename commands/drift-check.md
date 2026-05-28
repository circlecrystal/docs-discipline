---
description: Run heuristic doc drift detection. Reports candidates only — does not auto-fix.
---

You are running docs-discipline drift-check on the current project.

## What you must do

1. **Locate the drift-check script.** Prefer in this order:
   - `scripts/drift-check.sh` in the project (set up by `/docs-discipline:init`).
   - `${CLAUDE_PLUGIN_ROOT}/assets/drift-check.sh` (the plugin's bundled copy).
   - If neither is available, ask the user to run `/docs-discipline:init` first, then stop.

2. **Run the script** using Bash. It accepts an optional first argument (project root, defaults to git root or current directory) and respects `DOCS_DISCIPLINE_STALE_DAYS` (default 30). Capture both stdout and exit code.

3. **Present the result** to the user:
   - Print the full script output verbatim.
   - If exit code is `0` → "No drift detected."
   - If exit code is `1` → Summarize counts per category (broken links / stale timestamps / orphans / duplicated H1s). Remind the user that these are **candidates** — the script does not know what is intentional vs. drift.
   - If exit code is `2` → Report the setup error and stop.

## What you must NOT do

- Do not auto-fix any drift candidates. This command is a triage tool.
- Do not suggest "drift vs. intentional" judgments unless the user explicitly asks. Human judgment is the whole point.
- Do not modify any files.
- Do not re-implement the heuristics in this prompt — defer to the script. If the script needs changes, that is a separate task (edit `scripts/drift-check.sh` directly, or update the plugin's asset and re-run init).
