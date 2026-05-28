## docs-discipline

This project uses [docs-discipline](https://github.com/circlecrystal/docs-discipline).

- At the end of each session, run `/docs-discipline:codify`.
- Periodically run `/docs-discipline:drift-check` to surface doc drift.

## Doc layers (A/B)

Durable docs follow a two-layer pattern. This is universal — every project benefits from it.

- **A layer (artifacts)**: immutable, dated. Written once, never edited after creation. Each captures a point-in-time finding, decision, or session output.
- **B layer (SSOT)**: living, curated. Few files. Each B-layer assertion should be backed by an A-layer artifact.

Drift typically happens when old A-layer "as-of-then" content is treated as B-layer "as-of-now" truth.

How A and B *look* in this project — paths, file conventions, naming — is your call. The plugin does not assume.

### Where this project's A layer lives

<!-- Free-form. Describe where immutable, dated artifacts go in this project.
     If you leave this empty, /docs-discipline:codify will gently ask on first run. -->

### Where this project's B layer lives

<!-- Free-form. Describe where the living SSOT lives in this project.
     If you leave this empty, /docs-discipline:codify will gently ask on first run. -->

## Project governance

<!-- Any other rules specific to this project. docs-discipline imposes nothing here. -->
