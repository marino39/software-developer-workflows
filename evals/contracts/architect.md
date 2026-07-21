# Contract test — architect

## Stimulus A (inline mode — no `artifact_path`)

> Design a plan to add `func Product(xs []int) int` to the `calc` package of the
> `evalfixture` module, returning the product of the elements.

### Expected output fields (per `agents/architect.md` Output contract, inline mode)

- `goal`, `approach`, `steps`, `interfaces`, `risks`, `verification` — all six
  present, inline, ~400 words total or less.

## Stimulus B (artifact mode — `artifact_path` given)

> Design a plan to add `func Product(xs []int) int` to the `calc` package of the
> `evalfixture` module, returning the product of the elements. Write the full
> plan to `docs/superpowers/plans/product-plan.md` (artifact_path).

### Expected output fields (per `agents/architect.md` Output contract, artifact mode)

- `artifact_path` — echoes the given path; the file exists and carries the full
  six-section plan format.
- `summary` — ≤200 words.
- `steps` — step titles only, no bodies; the inline return stays ~250 words or
  less (the full plan lives in the file, not the reply).

## Role constraints

- No code written (plan only): no source file in the fixture copy is modified.
  In artifact mode the ONLY file created/modified is the given `artifact_path`
  (a docs location); in inline mode the fixture copy is unchanged entirely.
- Spawns only `searcher`/`researcher` (or nothing) — never a writing agent.
