# Contract test — researcher

`network-dependent` — `/workflow-eval --contracts` skips this when offline and
records `skipped (network)`.

## Stimulus

> Does Go's standard library provide a built-in to compute the product of an
> integer slice, or is a manual loop idiomatic? Cite sources.

## Expected output fields (per `agents/researcher.md` Output contract)

- `findings` — synthesized prose answer.
- `facts` — key facts each with a source URL.
- `confidence` — explicit confidence level.
- `open_questions` — remaining unknowns (or `none`).

## Role constraints

- No implementation work; no codebase changes.
